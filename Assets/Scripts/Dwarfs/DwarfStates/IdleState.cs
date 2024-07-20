using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class IdleState : DwarfState
{
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
    }

    public override void OnExitState()
    {
        base.OnExitState();
    }

    public override void OnFrameUpdate()
    {
        base.OnFrameUpdate();
    }
}
