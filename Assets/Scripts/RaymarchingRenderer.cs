using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

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
        Debug.Log("clean");
        _camera = GetComponent<Camera>();

        if (_camera != null && buffer != null)
        {
            _camera.RemoveCommandBuffer(pass, buffer);
        }

        Debug.Log("do clean");
    }

    void OnEnable()
    {
        CleanUp();
        UpdateCommandBuffer();
    }

    void OnDisable()
    {
        CleanUp();
        Debug.Log("Disable");
    }

    void Update()
    {
        //Debug.Log("neko");
        //UpdateCommandBuffer();
        if (buffer != null)
        {
            quad_.vertices = new Vector3[4] {
                Quaternion.Euler(transform.localEulerAngles)*(new Vector3( 2.0f , 1.0f,  1.0f))+transform.position,
                Quaternion.Euler(transform.localEulerAngles)*(new Vector3(-2.0f , 1.0f,   1.0f))+transform.position,
                Quaternion.Euler(transform.localEulerAngles)*(new Vector3(-2.0f ,-1.0f,   1.0f))+transform.position,
                Quaternion.Euler(transform.localEulerAngles)*(new Vector3( 2.0f ,-1.0f,  1.0f))+transform.position,
            };
            quad_.triangles = new int[6] { 0, 1, 2, 2, 3, 0 };
            //buffer.DrawMesh(quad_, Matrix4x4.identity, material, 0, 0);
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

        if (buffer == null)
        {
            quad_ = GenerateQuad();

            buffer = new CommandBuffer();
            buffer.name = "Raymarching";

            buffer.DrawMesh(quad_, Matrix4x4.identity, material, 0, 0);
            _camera.AddCommandBuffer(pass, buffer);

            Debug.Log("draw");
        }
    }

}
