using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class RaymarchingRenderer : MonoBehaviour
{
    Mesh quad_;
    Camera _camera;
    CommandBuffer buffer = null;
    [SerializeField] Material material = null;
    [SerializeField] CameraEvent pass = CameraEvent.BeforeGBuffer;

    Mesh GenerateQuad()
    {
        var mesh = new Mesh();
        mesh.vertices = new Vector3[4] {
            new Vector3( 2.0f , 1.0f,  1.0f)+transform.position,
            new Vector3(-2.0f , 1.0f,   1.0f)+transform.position,
            new Vector3(-2.0f ,-1.0f,   1.0f)+transform.position,
            new Vector3( 2.0f ,-1.0f,  1.0f)+transform.position,
        };
        mesh.triangles = new int[6] { 0, 1, 2, 2, 3, 0 };
        return mesh;
    }

    void CleanUp()
    {
        _camera = GetComponent<Camera>();
        //GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;

        if (_camera != null && buffer != null)
        {
            _camera.RemoveCommandBuffer(pass, buffer);
        }
    }

    void OnEnable()
    {
        CleanUp();
        UpdateCommandBuffer();
    }

    void OnDisable()
    {
        CleanUp();
    }

    void Update()
    {
        if (buffer != null)
        {
            quad_.vertices = new Vector3[4] {
                Quaternion.Euler(transform.localEulerAngles)*(new Vector3( 2.0f , 1.0f,  1.0f))+transform.position,
                Quaternion.Euler(transform.localEulerAngles)*(new Vector3(-2.0f , 1.0f,   1.0f))+transform.position,
                Quaternion.Euler(transform.localEulerAngles)*(new Vector3(-2.0f ,-1.0f,   1.0f))+transform.position,
                Quaternion.Euler(transform.localEulerAngles)*(new Vector3( 2.0f ,-1.0f,  1.0f))+transform.position,
            };
            quad_.triangles = new int[6] { 0, 1, 2, 2, 3, 0 };
        }
    }

    void UpdateCommandBuffer()
    {
        var act = gameObject.activeInHierarchy && enabled;
        if (!act)
        {
            OnDisable();
            return;
        }


        quad_ = GenerateQuad();

        buffer = new CommandBuffer();
        buffer.name = "Raymarching";

        buffer.DrawMesh(quad_, Matrix4x4.identity, material, 0, 0);

        _camera.AddCommandBuffer(pass, buffer);

    }

}
