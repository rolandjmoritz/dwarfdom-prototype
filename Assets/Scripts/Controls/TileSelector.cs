using System.Collections;
using System.Collections.Generic;
using Unity.AI.Navigation;
using UnityEngine;

public class TileSelector : MonoBehaviour
{
    public NavMeshSurface surface;

    private void Start()
    {
        if (surface == null)
        {
            surface = FindObjectOfType<NavMeshSurface>();
        }
    }

    public void UpdateNavMesh()
    {
        surface.BuildNavMesh();
    }

    void Update()
    {
        // Check for mouse click
        if (Input.GetMouseButton(0))
        {
            DetectMeshClick();
        }
    }

    void DetectMeshClick()
    {
        // Create a ray from the camera to the mouse position
        Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
        RaycastHit hit;

        // Perform the raycast
        if (Physics.Raycast(ray, out hit))
        {
            // Check if the object hit by the raycast has a collider
            Collider collider = hit.collider;

            if (collider != null)
            {
                // Handle the selection logic
                HandleSelection(collider.gameObject);
            }
        }
    }

    void HandleSelection(GameObject selectedObject)
    {
        // Here you can handle what happens when a mesh is selected
        Debug.Log("Selected object: " + selectedObject.name);

        WallTile tile = selectedObject.GetComponent<WallTile>();
        if (tile != null)
        {
            tile.Selected = !tile.Selected;
        }
    }
}
