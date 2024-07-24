using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MoveState : DwarfState
{
    public float wanderRange = 10f;

    public MoveState(Dwarf dwarf, DwarfStateMachine stateMachine) : base(dwarf, stateMachine)
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
        
        Vector3 randomDirection = Random.insideUnitSphere * wanderRange;
        randomDirection += dwarf.transform.position;
        UnityEngine.AI.NavMeshHit hit;
        UnityEngine.AI.NavMesh.SamplePosition(randomDirection, out hit, wanderRange, UnityEngine.AI.NavMesh.AllAreas);
        Vector3 finalPosition = hit.position;
        dwarf.Agent.SetDestination(finalPosition);
    }

    public override void OnExitState()
    {
        base.OnExitState();
    }

    public override void OnFrameUpdate()
    {
        base.OnFrameUpdate();
        if (dwarf.Agent.remainingDistance <= dwarf.Agent.stoppingDistance)
        {
            stateMachine.ChangeState(dwarf.IdleState);
        }
        dwarf.CheckForTilesToMine();
        if (dwarf.TileToMine != null && dwarf.TileToMine.Selected)
        {
            stateMachine.ChangeState(dwarf.MineState);
        }
    }
}
