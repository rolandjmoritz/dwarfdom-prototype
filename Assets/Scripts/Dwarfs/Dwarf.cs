using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

public class Dwarf : MonoBehaviour, IEventListener
{
    public float wanderRange = 10f;
    private NavMeshAgent agent;


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

    private void OnEnable()
    {
        EventManager.Instance.AddListener(this);
    }

    private void OnDisable()
    {
        EventManager.Instance.RemoveListener(this);
    }

    public void OnEventTriggered(string eventType, object data)
    {             
        // If we learn about a new tile being selected, we check if another dwarf is already mining it and if not, we'll claim it as the one we are working on
        switch (eventType)
        {
            case "TileSelected":
                WallTile tile = data as WallTile;
                if (tile.minedByDwarf == null)
                {
                    TileToMine = tile;
                    tile.minedByDwarf = this;
                }
                break;
            default:
                break;
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
    }

    // Update is called once per frame
    void Update()
    {
        StateMachine.CurrentDwarfState.OnFrameUpdate();

        UpdateAnimator();
    }

    private void UpdateAnimator()
    {
        float speed = agent.velocity.magnitude;
        animator.SetFloat("Speed", speed);
    }
}
