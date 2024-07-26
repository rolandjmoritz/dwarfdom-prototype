using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace CureAllGame
{
    internal class DwarfGameRendererFeature : ScriptableRendererFeature
    {
        [Header("Layer Settings")]
        public bool m_EnableMasking = false;
        public LayerMask m_LayerMask = 0;

        [Header("Rendering Settings")]
        public RenderPassEvent m_RenderPassEvent;
        public int m_RenderLayerMask;

        private Material m_DitheringMat;

        private PixelizeRenderPass m_PixelizePass;


        public override void Create()
        {
            m_DitheringMat = CoreUtils.CreateEngineMaterial("Cure-All/Pixelize");

            m_PixelizePass = new PixelizeRenderPass(m_EnableMasking, m_RenderPassEvent, m_DitheringMat, m_LayerMask, m_RenderLayerMask);
        }

        public override void AddRenderPasses(ScriptableRenderer mainRenderer, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.cameraType == CameraType.Game)
                mainRenderer.EnqueuePass(m_PixelizePass);
        }

        public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
        {
            if (renderingData.cameraData.cameraType != CameraType.Game)
                return;

            m_PixelizePass.ConfigureInput(ScriptableRenderPassInput.Color);
            // Enable if pass requires access to the CameraDepthTexture or the CameraNormalsTexture.
            m_PixelizePass.ConfigureInput(ScriptableRenderPassInput.Depth);
            m_PixelizePass.ConfigureInput(ScriptableRenderPassInput.Normal);
        }

        protected override void Dispose(bool disposing)
        {
            m_PixelizePass.Dispose();
            CoreUtils.Destroy(m_DitheringMat);
        }
    }
}