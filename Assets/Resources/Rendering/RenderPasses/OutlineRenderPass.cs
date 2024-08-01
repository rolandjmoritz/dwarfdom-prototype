using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

namespace CureAllGame
{
	public class OutlineRenderPass : ScriptableRenderPass
	{
        private const string m_ProfilerTag = "Outline Render Pass";
        private ProfilingSampler m_ProfilingSampler = new(m_ProfilerTag);

        private readonly bool m_EnableMasking;
        private FilteringSettings m_FilteringSettings;
        private readonly List<ShaderTagId> m_ShaderTagIds = new()
        {
            new ShaderTagId("SRPDefaultUnlit"),
            new ShaderTagId("UniversalForward"),
            new ShaderTagId("UniversalForwardOnly"),
            new ShaderTagId("LightweightForward"),
            new ShaderTagId("DepthNormals"),
            new ShaderTagId("DepthOnly")
        };

        private RTHandle m_ColorBuffer;
        private RTHandle m_NormalBuffer;
        private RTHandle m_TempBuffer;

        private PixelizeComponent m_Component;
        private Material m_OutlineMaterial;

        private RendererList m_RendererList;


        public OutlineRenderPass(bool enableMasking, RenderPassEvent renderPass, Material outlineMaterial, LayerMask layerMask, int renderLayerMask)
        {
            m_OutlineMaterial = outlineMaterial;
            m_EnableMasking = enableMasking;
            renderPassEvent = renderPass;
            m_FilteringSettings = new FilteringSettings(RenderQueueRange.opaque, layerMask, (uint)1 << renderLayerMask);
        }

        public override void OnCameraSetup(CommandBuffer commandBuffer, ref RenderingData renderingData)
        {
            var cameraTextureDescriptor = renderingData.cameraData.cameraTargetDescriptor;
            cameraTextureDescriptor.depthBufferBits = (int)DepthBits.None;

            RenderingUtils.ReAllocateIfNeeded(ref m_NormalBuffer, cameraTextureDescriptor, FilterMode.Point,
                name: "_NormalBuffer");

            RenderingUtils.ReAllocateIfNeeded(ref m_TempBuffer, cameraTextureDescriptor, FilterMode.Point,
                name: "_TempBuffer");

            ConfigureTarget(m_NormalBuffer, renderingData.cameraData.renderer.cameraDepthTargetHandle); // Configure the target to render to. Attach depth handle to filter texture by depth.
            ConfigureClear(ClearFlag.Color, Color.clear); // Clear the target buffer by giving it a solid color.
        }

        private void InitRendererLists(ref RenderingData renderingData, ScriptableRenderContext context)
        {
            var sortingCriteria = renderingData.cameraData.defaultOpaqueSortFlags;
            var drawingSettings = CreateDrawingSettings(m_ShaderTagIds, ref renderingData, sortingCriteria);
            drawingSettings.overrideMaterial = m_OutlineMaterial;
            drawingSettings.overrideMaterialPassIndex = 0;
            var renderListParams = new RendererListParams(renderingData.cullResults, drawingSettings, m_FilteringSettings);

            m_RendererList = context.CreateRendererList(ref renderListParams);
        }

        // Executes the render pass for every camera each frame.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (m_OutlineMaterial == null)
                return;

            m_ColorBuffer = renderingData.cameraData.renderer.cameraColorTargetHandle;

            CommandBuffer commandBuffer = CommandBufferPool.Get();
            using (new ProfilingScope(commandBuffer, m_ProfilingSampler))
            {
                context.ExecuteCommandBuffer(commandBuffer);
                commandBuffer.Clear();

                var sortingCriteria = renderingData.cameraData.defaultOpaqueSortFlags;
                var drawingSettings = CreateDrawingSettings(m_ShaderTagIds, ref renderingData, sortingCriteria);
                drawingSettings.overrideMaterial = m_OutlineMaterial;

                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref m_FilteringSettings);

                Shader.SetGlobalTexture(m_NormalBuffer.name, m_NormalBuffer);

                Blitter.BlitCameraTexture(commandBuffer, m_ColorBuffer, m_TempBuffer, m_OutlineMaterial, 1);
                Blitter.BlitCameraTexture(commandBuffer, m_TempBuffer, m_ColorBuffer, m_OutlineMaterial, 2);
            }

            context.ExecuteCommandBuffer(commandBuffer);
            commandBuffer.Clear();
            CommandBufferPool.Release(commandBuffer);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            m_ColorBuffer = null;
        }

        public void Dispose()
        {
            m_NormalBuffer?.Release();
            m_TempBuffer?.Release();
        }
    }
}