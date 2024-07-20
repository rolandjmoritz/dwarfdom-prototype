using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MineState : DwarfState
{
    public MineState(Dwarf dwarf, DwarfStateMachine stateMachine) : base(dwarf, stateMachine)
    {
    }

    public override void AnimationTriggerEvent(Dwarf.AnimationTriggerType triggerType)
    {
        base.AnimationTriggerEvent(triggerType);
    }

    public override void OnEnterState()
    {
        base.OnEnterState();
        dwarf.Agent.isStopped = false;

        Vector3 finalPosition = dwarf.TileToMine.transform.position;
        dwarf.Agent.SetDestination(finalPosition);

        Debug.Log(dwarf.gameObject.name + " starting to mine...");
    }

    public override void OnExitState()
    {
        base.OnExitState();
    }

    public override void OnFrameUpdate()
    {
        base.OnFrameUpdate();

        if (dwarf.TileToMine == null || dwarf.TileToMine.Selected == false)
        {
            dwarf.StateMachine.ChangeState(dwarf.MoveState);
            Debug.Log(dwarf.gameObject.name + " stopping to mine.");
        }
        if (dwarf.Agent.remainingDistance <= dwarf.Agent.stoppingDistance)
        {
            Debug.Log(dwarf.gameObject.name + " reached goal");
            dwarf.TileToMine.TakeDamage(dwarf.miningSpeed * Time.deltaTime);
        }
    }
}
