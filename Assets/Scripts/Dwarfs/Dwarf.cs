using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

public class Dwarf : MonoBehaviour, IEventListener
{
    public float wanderRange = 10f;
    private NavMeshAgent agent;
    public float miningSpeed = 20.0f;

    public enum AnimationTriggerType
    {
        Idle, 
        Mining
    }

    public Animator animator;

    public DwarfStateMachine StateMachine { get; set; }
    public IdleState IdleState { get; set; }
    public MoveState MoveState { get; set; }
    public MineState MineState { get; set; }
    public WallTile TileToMine { get; set; }
    public NavMeshAgent Agent { get => agent; set => agent = value; }


    public void OnEventTriggered(string eventType, object data)
    {             
        if (eventType == "TileDeSelected")
        {
            WallTile wt = data as WallTile;
            if (wt == TileToMine)
            {
                TileToMine = null;
            }
        }
        StateMachine.CurrentDwarfState.OnEventTriggered(eventType, data);
    }    

    private void AnimationTriggerEvent(AnimationTriggerType triggerType)
    {
        StateMachine.CurrentDwarfState.AnimationTriggerEvent(triggerType);
    }

    // Start is called before the first frame update
    void Awake()
    {
        Agent = GetComponent<NavMeshAgent>();

        StateMachine = new DwarfStateMachine();

        IdleState = new IdleState(this, StateMachine);
        MoveState = new MoveState(this, StateMachine);
        MineState = new MineState(this, StateMachine);
    }   

    private void Start()
    {
        StateMachine.Initialize(IdleState);
        EventManager.Instance.AddListener(this);
    }

    // Update is called once per frame
    void Update()
    {
        StateMachine.CurrentDwarfState.OnFrameUpdate();
        UpdateAnimator();
    }

    // returns true if the Dwarf has found a new tile to mine
    public bool CheckForTilesToMine()
    {
        if (TileSelector.selectedWallTiles.Count > 0)
        {
            float minDist = 100000.0f;
            float currentDist = 0.0f;
            int tileIdx = -1;
            // try to find nearest free selected tile
            for (int i = 0; i < TileSelector.selectedWallTiles.Count; i++)
            {
                currentDist = Vector3.Distance(transform.position, TileSelector.selectedWallTiles[i].transform.position);
                if (currentDist < minDist && (TileSelector.selectedWallTiles[i].minedByDwarf == null))
                {
                    minDist = currentDist;
                    tileIdx = i;
                }
            }
            // if we found a free selected tile, return true and assign tile to dwarf and dwarf to tile
            if (tileIdx >= 0)
            {
                TileToMine = TileSelector.selectedWallTiles[tileIdx];
                TileSelector.selectedWallTiles[tileIdx].minedByDwarf = this;
                return true;
            }
        }

        return false;
    }

    private void UpdateAnimator()
    {
        float speed = agent.velocity.magnitude;
        animator.SetFloat("Speed", speed);
    }

    public void ResetAllTriggers()
    {
        animator.ResetTrigger("mine");
        animator.ResetTrigger("walk");
        animator.ResetTrigger("idle");
    }
}
