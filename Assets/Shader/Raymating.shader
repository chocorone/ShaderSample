Shader "Custom/Raymating"
{
   Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
        _Diffuse ("Diffuse Color", Color) = (1, 1, 1, 1)
        _Specular ("Specular Color", Color) = (1, 1, 1, 1)
        _minDistance ("Min Distance",float) = 1
		[Space(10)]
		[HDR]_GlowColor ("Emission", Color) = (1, 1, 1, 1)
	}
   SubShader
    {
        Tags { "RenderType" = "Opaque" "DisableBatching" = "True" "Queue" = "Geometry" }
        Cull Off 


        Pass
        {
            Tags { "LightMode" = "Deferred" }
            Stencil 
            {
                Comp Always
                Pass Replace
                Ref 128
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
            float4 _Diffuse;
            float4 _GlowColor;
            float4 _Specular;
            float3 lightDir = float3(1.0, 1.0, 1.0);
            float _minDistance;

            struct appdata
			{
				float4 vertex : POSITION;
			};
            struct v2f
			{
				float4 pos : POSITION1;
				float4 vertex : SV_POSITION;
			};

            struct GBufferOut
            {
                half4 diffuse  : SV_Target0; // rgb: diffuse,  a: occlusion
                half4 specular : SV_Target1; // rgb: specular, a: smoothness
                half4 normal   : SV_Target2; // rgb: normal,   a: unused
                half4 emission : SV_Target3; // rgb: emission, a: unused
                float depth    : SV_Depth;
            };

            // 球の距離関数
            float sphereDist(float3 position)
            {
                float radius = 3.0;
                return length(position) - radius;
            }

            //立方体の距離関数
            float boxDist(float3 position){
                return length(max(abs(position) - float3(1.0, 1.0, 1.0), 0.0));
            }

            float3 rotate(float3 p, float angle, float3 axis){
                float3 a = normalize(axis);
                float s = sin(angle);
                float c = cos(angle);
                float r = 1.0 - c;
                float3x3 m = float3x3(
                    a.x * a.x * r + c,
                    a.y * a.x * r + a.z * s,
                    a.z * a.x * r - a.y * s,
                    a.x * a.y * r - a.z * s,
                    a.y * a.y * r + c,
                    a.z * a.y * r + a.x * s,
                    a.x * a.z * r + a.y * s,
                    a.y * a.z * r - a.x * s,
                    a.z * a.z * r + c
                );
                return mul(m , p);
            }

            float dePseudoKleinian(float3 p) {
                float3 csize = float3(0.90756, 0.92436, 0.90756);
                float size = 1.0;
                float3 c = float3(0.0,0.0,0.0);
                float defactor = 0.75;
                float3 offset = float3(0,0.0,0);
                float3 ap = p + 1.0;
                for (int i = 0; i < 8; i++) {
                    ap = p;
                    p = 2.0 * clamp(p, -csize, csize) - p;
                    float r2 = dot(p, p);
                    float k = max(size / r2, 1.0);
                    p *= k;
                    defactor *= k + 0.05;
                    p += c;
                }
                float r = abs(0.5 * abs(p.y - offset.y) /defactor);
                return r;
            }

            // シーンの距離関数
            float sceneDist(float3 position)
            {
                return dePseudoKleinian(position);
                //return sphereDist(position);
            }

            float3 GetCameraPosition()    { return _WorldSpaceCameraPos;      }
            float3 GetCameraForward()     { return -UNITY_MATRIX_V[2].xyz;    }
            float3 GetCameraUp()          { return UNITY_MATRIX_V[1].xyz;     }
            float3 GetCameraRight()       { return UNITY_MATRIX_V[0].xyz;     }
            float  GetCameraFocalLength() { return abs(UNITY_MATRIX_P[1][1]); }
            float  GetCameraMaxDistance() { return _ProjectionParams.z - _ProjectionParams.y; }

            float GetDepth(float3 pos)
            {
                float4 vpPos = mul(UNITY_MATRIX_VP, float4(pos, 1.0));
            #if defined(SHADER_TARGET_GLSL)
                return (vpPos.z / vpPos.w) * 0.5 + 0.5;
            #else 
                return vpPos.z / vpPos.w;
            #endif 
            }

            // レイがぶつかった位置における法線を取得
            float3 getNormal(float3 p)
            {
                const float d = 0.0005;
                return normalize( float3(
                    sceneDist(p+float3(  d,0.0,0.0))-sceneDist(p+float3( -d,0.0,0.0)),
                    sceneDist(p+float3(0.0,  d,0.0))-sceneDist(p+float3(0.0, -d,0.0)),
                    sceneDist(p+float3(0.0,0.0,  d))-sceneDist(p+float3(0.0,0.0, -d)) ));
            }
            
            v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
                //ローカル→ワールド座標に変換
				o.pos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

            GBufferOut frag(v2f i) 
			{
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 lightColor = _LightColor0;

                float3 pos = i.pos.xyz;
				// レイの進行方向
				float3 rayDir = normalize(pos.xyz - _WorldSpaceCameraPos);

                float dist;
                for (int n = 0; n < 90; n++)
                {
                    float3 q = pos;
                    dist = sceneDist(q);
                    // 距離が十分に短かったら衝突したと判定
                    if (dist <= 0.001) break;
                    // レイを進める
                    pos.xyz += dist * rayDir.xyz;
                }


                
                if (dist > 0.001)
                    discard;

                GBufferOut o;
                float2 uv = float2(1.0-fmod(pos.x,2.0),1.0-fmod(pos.z,2.0));
                o.diffuse  = float4(tex2D(_MainTex,uv)*_Diffuse.xyz,1);
                o.specular = _Specular;
                fixed4 emission = pow(dist + length(pos)/400 + 0.8, -2.0);
                o.emission = _GlowColor*emission;
                o.normal = float4(getNormal(pos),1.0);
                o.depth  = GetDepth(pos);
                    

                return o;
                
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
