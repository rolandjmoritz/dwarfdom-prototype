using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMovement : MonoBehaviour
{
    public float speed = 10f; // Base speed of the camera
    public float acceleration = 2f; // Acceleration rate
    public float deceleration = 2f; // Deceleration rate

    private Vector3 velocity = Vector3.zero;

    void Update()
    {
        // Get input from WASD keys
        float inputX = Input.GetAxis("Horizontal");
        float inputZ = Input.GetAxis("Vertical");

        // Create a target velocity based on input
        Vector3 targetVelocity = new Vector3(-inputX, 0, -inputZ) * speed;

        // Smoothly interpolate the current velocity towards the target velocity
        velocity = Vector3.Lerp(velocity, targetVelocity, acceleration * Time.deltaTime);

        // Apply deceleration when there is no input
        if (inputX == 0 && inputZ == 0)
        {
            velocity = Vector3.Lerp(velocity, Vector3.zero, deceleration * Time.deltaTime);
        }

        // Move the camera based on the calculated velocity
        transform.position += velocity * Time.deltaTime;
    }
}
