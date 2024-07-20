using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Dwarf : MonoBehaviour
{
    public enum AnimationTriggerType
    {
        Idle, 
        Mining
    }

    public DwarfStateMachine StateMachine { get; set; }
    public IdleState IdleState { get; set; }
    public MoveState MoveState { get; set; }
    public MineState MineState { get; set; }
    
    private void AnimationTriggerEvent(AnimationTriggerType triggerType)
    {
        StateMachine.CurrentDwarfState.AnimationTriggerEvent(triggerType);
    }

    // Start is called before the first frame update
    void Awake()
    {
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
    }
}
