using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerController : MonoBehaviour
{
    [SerializeField] float speed = 5;
    [SerializeField] float angleSpeed = 5;
    float h = 0, v = 0;
    Animator anim;

    Rigidbody rb;
    // Start is called before the first frame update
    void Start()
    {
        rb = GetComponent<Rigidbody>();
        anim = GetComponent<Animator>();
    }

    // Update is called once per frame
    void Update()
    {
        h = Input.GetAxisRaw("Horizontal");
        v = Input.GetAxisRaw("Vertical");
    }

    private void FixedUpdate()
    {
        bool moving = h != 0 || v != 0;
        Vector3 movement = Camera.main.transform.forward * v + Camera.main.transform.right * h;
        rb.MovePosition(transform.position + movement * speed * Time.deltaTime);
        anim.SetBool("running", moving);
        if (moving)
        {
            Quaternion q = Quaternion.LookRotation(movement.normalized, Vector3.up);
            transform.rotation = Quaternion.Slerp(transform.rotation, q, Time.deltaTime * angleSpeed);

        }

    }

}
