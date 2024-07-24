using System.Collections;
using System.Collections.Generic;
using Unity.AI.Navigation;
using UnityEngine;

public class TileSelector : MonoBehaviour, IEventListener
{
    public static List<WallTile> selectedWallTiles = new List<WallTile>();
    public NavMeshSurface surface;

    private void Start()
    {
        EventManager.Instance.AddListener(this);
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
        if (Input.GetMouseButtonDown(0))
        {
            DetectMeshClick();
        }
    }

    public void OnEventTriggered(string eventType, object data)
    {
        if (eventType == "TileDestroyed")
        {
            WallTile wt = data as WallTile;
            DeselectWallTile(wt);
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
            if (selectedWallTiles.Contains(tile))
            {
                DeselectWallTile(tile);
            }
            else
            {
                SelectWallTile(tile);
            }
        }
    }

    public static void SelectWallTile(WallTile wallTile)
    {
        // Add to the list of selected WallTiles
        selectedWallTiles.Add(wallTile);
        wallTile.Selected = true;
        // Optionally, change the appearance to indicate selection
        wallTile.meshRenderer.material.color = Color.yellow; // Example: change color
    }

    public static void DeselectWallTile(WallTile wallTile)
    {
        // Remove from the list of selected WallTiles
        selectedWallTiles.Remove(wallTile);
        wallTile.Selected = false;
        // Optionally, revert the appearance to indicate deselection
        wallTile.meshRenderer.material.color = Color.white; // Example: change color
    }
}
