using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WallTile : MonoBehaviour
{
    public MeshRenderer meshRenderer;
    public Material normalMaterial;
    public Material selectedMaterial;

    public float health = 100.0f;

    public Dwarf minedByDwarf = null;

    public enum tileType
    {
        rock, 
        wall, 
        gold
    };

    private bool selected = false;

    public void TakeDamage(float amount = 1.0f)
    {
        health -= amount;
        if (health < amount)
        {
            EventManager.Instance.TriggerEvent("TileDestroyed", this);
            Destroy(gameObject);
        }
    }

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
                EventManager.Instance.TriggerEvent("TileSelected", this);
            }
            else
            {
                EventManager.Instance.TriggerEvent("TileDeSelected", this);
            }
        }
    }
}
