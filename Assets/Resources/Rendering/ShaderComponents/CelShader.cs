using System;
using UnityEngine;

namespace CureAllGame
{
    [ExecuteAlways]
    [RequireComponent(typeof(MeshRenderer))]
    [AddComponentMenu("Cure-All/Shaders/Cel Shader")]
    public class CelShader : MonoBehaviour
    {
        private Material m_Material;

        [Header("Textures")]
        [SerializeField] private Texture m_AlbedoMap;
        [SerializeField] private Texture m_OcclusionMap;


        [Header("Ambient Occlusion Map Settings")]
        [SerializeField][Range(2, 255)] private Int32 m_QuantizedShadeLimit = 255;
        [SerializeField][Range(0, 1)] private float m_BrightnessPreference = 0.5f;
        [SerializeField][Range(0, 1)] private float m_MinimumIntensity = 0.5f;
        [SerializeField][Range(0, 1)] private float m_MaximumIntensity = 0.5f;

        [Header("Lighting Settings")]
        [SerializeField] private bool m_LightEnergyConservation = false;
        [SerializeField] private Color m_BaseColor = new Color(1, 1, 1, 1);
        [SerializeField] private Color m_AmbientColor = new Color(0.4f, 0.4f, 0.4f, 1);
        [SerializeField] private Color m_SpecularColor = new Color(0.9f, 0.9f, 0.9f, 1);
        [SerializeField] private Color m_RimColor = new Color(0.8f, 0.8f, 0.8f, 1);
        [SerializeField] private Int32 m_Smoothness = 50;
        [Space]
        [SerializeField][Range(0, 1)] private float m_AmbientLightStrength = 1.0f;
        [SerializeField][Range(0, 1)] private float m_RimLightStrength = 0.275f;
        [SerializeField][Range(0, 1)] private float m_RimThreshold = 0.1f;
        [Space]
        [SerializeField][Range(0, 10)] private float m_AmbientBlendStrength = 1.0f;
        [SerializeField][Range(0.5f, 10)] private float m_SpecularBlendStrength = 1.0f;
        [SerializeField][Range(0, 10)] private float m_RimBlendStrength = 1.0f;

        void OnEnable()
        {
            if (Application.isPlaying)
                return;

            if (m_Material is null)
            {
                m_Material = new Material(Shader.Find("Cure-All/Cel Shading"));
                m_Material.hideFlags = HideFlags.NotEditable;
                GetComponent<MeshRenderer>().material = m_Material;
            }
        }

        private void Update()
        {
            if (Application.isPlaying)
                return;

            m_Material.SetTexture("_MainTex", m_AlbedoMap);
            m_Material.SetTexture("_AOTexture", m_OcclusionMap);

            m_Material.SetFloat("_EnergyConservation", m_LightEnergyConservation ? 1 : 0);
            m_Material.SetFloat("_AOMapLevels", m_QuantizedShadeLimit);
            m_Material.SetFloat("_AOBrightPreference", m_BrightnessPreference);
            m_Material.SetFloat("_AOIntensityMin", m_MinimumIntensity);
            m_Material.SetFloat("_AOIntensityMax", m_MaximumIntensity);

            m_Material.SetColor("_Color", m_BaseColor);
            m_Material.SetColor("_AmbientColor", m_AmbientColor);
            m_Material.SetColor("_SpecularColor", m_SpecularColor);
            m_Material.SetColor("_RimColor", m_RimColor);

            m_Material.SetFloat("_Smoothness", m_Smoothness);
            m_Material.SetFloat("_ShadingStrength", m_AmbientLightStrength);
            m_Material.SetFloat("_RimStrength", m_RimLightStrength);
            m_Material.SetFloat("_RimThreshold", m_RimThreshold);
            m_Material.SetFloat("_BlendStrengthAmb", m_AmbientBlendStrength);
            m_Material.SetFloat("_BlendStrengthSpec", m_SpecularBlendStrength);
            m_Material.SetFloat("_BlendStrengthRim", m_RimBlendStrength);
        }
    }
}