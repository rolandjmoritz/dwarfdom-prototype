using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class IdleState : DwarfState
{
    public float idleDurationMin = 0.0f;
    public float idleDurationMax = 4.0f;
    private float idleCounter = 0.0f;

    public IdleState(Dwarf dwarf, DwarfStateMachine stateMachine) : base(dwarf, stateMachine)
    {
    }

    public override void AnimationTriggerEvent(Dwarf.AnimationTriggerType triggerType)
    {
        base.AnimationTriggerEvent(triggerType);
    }

    public override void OnEnterState()
    {
        base.OnEnterState();
        dwarf.Agent.isStopped = true;
        idleCounter = Random.Range(idleDurationMin, idleDurationMax);
    }

    public override void OnExitState()
    {
        base.OnExitState();
    }

    public override void OnFrameUpdate()
    {
        base.OnFrameUpdate();
        idleCounter -= Time.deltaTime;
        if (idleCounter <= 0.0f)
        {
            stateMachine.ChangeState(dwarf.MoveState);
        }
    }
}
