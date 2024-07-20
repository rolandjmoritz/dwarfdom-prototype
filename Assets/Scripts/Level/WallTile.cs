using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WallTile : MonoBehaviour
{
    public MeshRenderer meshRenderer;
    public Material normalMaterial;
    public Material selectedMaterial;

    public enum tileType
    {
        rock, 
        wall, 
        gold
    };

    private bool selected = false;

    public bool Selected {
        get
        {
            return selected;
        } 
        set
        {
            selected = value;
            if (selected)
            {
                meshRenderer.material = selectedMaterial;
            }
            else
            {
                meshRenderer.material = normalMaterial;
            }
        }
    }
}
