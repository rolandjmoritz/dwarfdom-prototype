using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace CureAllGame
{
    [Serializable]
    public class DwarfGameRendererFeature : ScriptableRendererFeature
    {
        [SerializeField] private Shader m_DownsampleShader;
        [SerializeField] private Shader m_DitheringShader;
        [SerializeField] private Shader m_QuantizingShader;


        private PixelizeRenderPass m_PixelizePass;

        public override void Create()
        {
            
        }

        public override void AddRenderPasses(ScriptableRenderer mainRenderer, ref RenderingData renderingData)
        {
            //mainRenderer.EnqueuePass(m_PixelizePass);
        }
    }
}