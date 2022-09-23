Shader "Custom/Raymating"
{
   Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
        _Diffuse ("Diffuse Color", Color) = (1, 1, 1, 1)
		[Space(10)]
		[HDR]_GlowColor ("Emission", Color) = (1, 1, 1, 1)
	}
   SubShader
    {
        Tags {"Queue" = "Transparent" "LightMode" = "ForwardBase"}
        //LOD 100
        Cull Off ZWrite On ZTest Always
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
            float4 _Diffuse;
            float4 _GlowColor;
            float3 lightDir = float3(1.0, 1.0, 1.0);
            struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};
            struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : POSITION1;
				float4 vertex : SV_POSITION;
			};

            // 球の距離関数
            float sphereDist(float3 position, float radius)
            {
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
            }

            // レイがぶつかった位置における法線を取得
            float3 getNormal(float3 p)
            {
                const float d = 0.0005;
                return normalize( float3(
                    dePseudoKleinian(p+float3(  d,0.0,0.0))-dePseudoKleinian(p+float3( -d,0.0,0.0)),
                    dePseudoKleinian(p+float3(0.0,  d,0.0))-dePseudoKleinian(p+float3(0.0, -d,0.0)),
                    dePseudoKleinian(p+float3(0.0,0.0,  d))-dePseudoKleinian(p+float3(0.0,0.0, -d)) ));
            }
            
            v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
                //ローカル→ワールド座標に変換
				o.pos = mul(unity_ObjectToWorld, v.vertex);
				o.uv = v.uv;
				return o;
			}

            fixed4 frag(v2f i) : SV_Target
			{
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 lightColor = _LightColor0;

                float3 pos = i.pos.xyz;
				// レイの進行方向
				float3 rayDir = normalize(pos.xyz - _WorldSpaceCameraPos);

                
                for (int n = 0; n < 90; n++)
                {
                    float3 q = pos;

                    
                    float dist = sceneDist(q);
                    if (dist < 0.001)
                    {
                        // 距離が十分に短かったら衝突したと判定して色を計算する
                        float3 normal = getNormal(q);

                        float3 color = tex2D(_MainTex,i.uv);
                        float diff = fixed4(lightColor * max(dot(normal, lightDir), 0) , 1.0);
                        color = diff*_Diffuse*(1-length(q)*0.08);
                        fixed4 emission = pow(dist + length(q)/20 + 0.8, -2.0);
                        return float4(color*_GlowColor*emission,1.0);
                    }
                    // レイを進める
                    pos.xyz += dist * rayDir.xyz;
                }

                return float4(0,1,0, 0);
                
            }
            ENDCG
        }
    }
}
