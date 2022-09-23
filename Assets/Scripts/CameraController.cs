using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class CameraController : MonoBehaviour
{
    [SerializeField] GameObject target;
    [SerializeField] float xRotateSpeed = 3f;
    Vector3 offset;
    Vector3 beforePos;

    void Start()
    {
        offset = transform.position - target.transform.position;

    }

    void Update()
    {
        beforePos = transform.position;
        float xRot = Input.GetAxis("Mouse X") * xRotateSpeed;
        transform.RotateAround(target.transform.position, Vector3.up, xRot);

        offset += transform.position - beforePos;
        transform.position = target.transform.position + offset;
    }
}
