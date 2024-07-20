using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public interface IEventListener
{
    void OnEventTriggered(string eventType, object data);
}

public class EventManager : MonoBehaviour
{
    private Dictionary<string, Action<object>> events = new Dictionary<string, Action<object>>();
    private List<IEventListener> listeners = new List<IEventListener>();

    public static EventManager Instance { get; private set; }

    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }
        else
        {
            Destroy(gameObject);
        }
    }

    public void AddListener(IEventListener listener)
    {
        listeners.Add(listener);
    }

    public void RemoveListener(IEventListener listener)
    {
        listeners.Remove(listener);
    }

    public void TriggerEvent(string eventType, object data = null)
    {
        foreach (var listener in listeners)
        {
            listener.OnEventTriggered(eventType, data);
        }
    }
}