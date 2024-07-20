using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DwarfState
{
    protected Dwarf dwarf;
    protected DwarfStateMachine stateMachine;

    public DwarfState(Dwarf dwarf, DwarfStateMachine stateMachine)
    {
        this.dwarf = dwarf;
        this.stateMachine = stateMachine;
    }

    public virtual void OnEnterState() { }
    public virtual void OnExitState() { }
    public virtual void OnFrameUpdate() { }
    public virtual void AnimationTriggerEvent(Dwarf.AnimationTriggerType triggerType) { }
}

