using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MineState : DwarfState
{
    private bool currentlyMining = false;

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
        dwarf.animator.SetTrigger("walk");
        dwarf.Agent.isStopped = false;

        Vector3 finalPosition = dwarf.TileToMine.transform.position;
        dwarf.Agent.SetDestination(finalPosition);
        currentlyMining = false;

        Debug.Log(dwarf.gameObject.name + " starting to mine...");
    }

    public override void OnExitState()
    {
        base.OnExitState();
    }

    public override void OnFrameUpdate()
    {
        base.OnFrameUpdate();

        // Nothing to mine? Then return to walking around
        if (dwarf.TileToMine == null || dwarf.TileToMine.Selected == false)
        {
            dwarf.StateMachine.ChangeState(dwarf.MoveState);
            currentlyMining = false;
        }
        // else, keep on mining!
        else if (dwarf.Agent.remainingDistance <= dwarf.Agent.stoppingDistance)
        {
            if (!currentlyMining)
            {
                dwarf.ResetAllTriggers();
                dwarf.animator.SetTrigger("mine");
                dwarf.transform.LookAt(dwarf.TileToMine.transform, Vector3.up);
            }
            currentlyMining = true;
            dwarf.TileToMine.TakeDamage(dwarf.miningSpeed * Time.deltaTime);
        }
    }

    public override void OnEventTriggered(string eventType, object data)
    {
        base.OnEventTriggered(eventType, data);
        if (eventType == "TileDestroyed")
        {
            WallTile wt = data as WallTile;
            if (wt == dwarf.TileToMine)
            {
                dwarf.TileToMine = null;                
            }
            dwarf.CheckForTilesToMine();
        }
    }
}
