using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace CureAllGame
{
    internal class ScreenSpaceOutlineRendererFeature : ScriptableRendererFeature
    {
        [Header("Layer Settings")]
        public bool m_EnableMasking = false;
        public LayerMask m_LayerMask = 0;

        [Header("Rendering Settings")]
        public RenderPassEvent m_RenderPassEvent;
        public int m_RenderLayerMask;

        private Material m_OutlineMaterial;

        private OutlineRenderPass m_OutlineRenderPass;


        public override void Create()
        {
            m_OutlineMaterial = CoreUtils.CreateEngineMaterial("Hidden/Outlines");

            m_OutlineRenderPass = new OutlineRenderPass(m_EnableMasking, m_RenderPassEvent, m_OutlineMaterial, m_LayerMask, m_RenderLayerMask);
        }

        public override void AddRenderPasses(ScriptableRenderer mainRenderer, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.cameraType == CameraType.Game)
                mainRenderer.EnqueuePass(m_OutlineRenderPass);
        }

        public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
        {
            if (renderingData.cameraData.cameraType != CameraType.Game)
                return;

            m_OutlineRenderPass.ConfigureInput(ScriptableRenderPassInput.Color);
            // Enable if pass requires access to the CameraDepthTexture or the CameraNormalsTexture.
            m_OutlineRenderPass.ConfigureInput(ScriptableRenderPassInput.Depth);
            m_OutlineRenderPass.ConfigureInput(ScriptableRenderPassInput.Normal);
        }

        protected override void Dispose(bool disposing)
        {
            m_OutlineRenderPass.Dispose();
            CoreUtils.Destroy(m_OutlineMaterial);
        }
    }
}