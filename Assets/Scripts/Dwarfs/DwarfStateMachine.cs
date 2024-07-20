using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DwarfStateMachine
{
    public DwarfState CurrentDwarfState { get; set; }

    public void Initialize(DwarfState startingState)
    {
        CurrentDwarfState = startingState;
        CurrentDwarfState.OnEnterState();
    }

    public void ChangeState(DwarfState newState)
    {
        CurrentDwarfState.OnExitState();
        CurrentDwarfState = newState;
        CurrentDwarfState.OnEnterState();
    }
}
