using UnityEngine;
using UnityEngine.AI;

public class DwarfMovement : MonoBehaviour
{
    public float wanderRange = 10f;
    private NavMeshAgent agent;

    void Start()
    {
        agent = GetComponent<NavMeshAgent>();
        if (agent != null)
        {
            SetNewRandomDestination();
        }
        else
        {
            Debug.LogError("NavMeshAgent component not found on this GameObject.");
        }
    }

    void Update()
    {
        if (agent.remainingDistance <= agent.stoppingDistance)
        {
            SetNewRandomDestination();
        }
    }

    void SetNewRandomDestination()
    {
        Vector3 randomDirection = Random.insideUnitSphere * wanderRange;
        randomDirection += transform.position;
        NavMeshHit hit;
        NavMesh.SamplePosition(randomDirection, out hit, wanderRange, NavMesh.AllAreas);
        Vector3 finalPosition = hit.position;
        agent.SetDestination(finalPosition);
    }
}