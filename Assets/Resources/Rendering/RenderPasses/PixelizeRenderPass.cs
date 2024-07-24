using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using static Unity.Burst.Intrinsics.X86.Avx;

namespace CureAllGame
{
    internal class PixelizeRenderPass : ScriptableRenderPass
	{
        private const string m_ProfilerTag = "Pixelize Pass";
        private ProfilingSampler m_ProfilingSampler = new(m_ProfilerTag);

        private readonly FilteringSettings m_FilteringSettings;
        private readonly List<ShaderTagId> m_ShaderTagIds = new();

        private RTHandle m_ColorBuffer;
        private RTHandle m_TempBuffer;
        private RTHandle m_FilterBuffer;

        private PixelizeComponent m_Component;
        private Material m_Material;

        private RendererList m_RendererList;


        public PixelizeRenderPass(Material renderMaterial, LayerMask layerMask, int renderLayerMask)
        {
            m_Material = renderMaterial;
            renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;

            m_FilteringSettings = new FilteringSettings(RenderQueueRange.opaque, layerMask, (uint)1 << renderLayerMask);

            // Default shader tags.
            m_ShaderTagIds.Add(new ShaderTagId("SRPDefaultUnlit"));
            m_ShaderTagIds.Add(new ShaderTagId("UniversalForward"));
            m_ShaderTagIds.Add(new ShaderTagId("UniversalForwardOnly"));
            m_ShaderTagIds.Add(new ShaderTagId("LightweightForward"));
            m_ShaderTagIds.Add(new ShaderTagId("DepthNormals"));
            m_ShaderTagIds.Add(new ShaderTagId("DepthOnly"));
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            var cameraTextureDescriptor = renderingData.cameraData.cameraTargetDescriptor;
            cameraTextureDescriptor.depthBufferBits = (int)DepthBits.None;
            m_Component = VolumeManager.instance.stack.GetComponent<PixelizeComponent>();

            m_Material.SetFloat("_Spread", m_Component.m_Spread.value);
            m_Material.SetInt("_RedColorCount", m_Component.m_RedColorCount.value);
            m_Material.SetInt("_GreenColorCount", m_Component.m_GreenColorCount.value);
            m_Material.SetInt("_BlueColorCount", m_Component.m_BlueColorCount.value);
            m_Material.SetInt("_BayerLevel", m_Component.m_BayerLevel.value);

            RenderingUtils.ReAllocateIfNeeded(ref m_FilterBuffer, cameraTextureDescriptor,
                name: "_FilterBuffer");

            for (int i = 0; i < m_Component.m_DownscaleFactor.value; ++i)
            {
                cameraTextureDescriptor.width /= 2;
                cameraTextureDescriptor.height /= 2;
            }
            RenderingUtils.ReAllocateIfNeeded(ref m_TempBuffer, cameraTextureDescriptor,
                name: "_TempBuffer");

            ConfigureTarget(m_FilterBuffer, renderingData.cameraData.renderer.cameraDepthTargetHandle); // Configure the target to render to. Attach depth handle to filter texture by depth.
            ConfigureClear(ClearFlag.Color, Color.clear); // Clear the target buffer by giving it a solid color.
        }

        private void InitRendererLists(ref RenderingData renderingData, ScriptableRenderContext context)
        {
            var sortingCriteria = renderingData.cameraData.defaultOpaqueSortFlags;
            var drawingSettings = CreateDrawingSettings(m_ShaderTagIds, ref renderingData, sortingCriteria);
            var renderListParams = new RendererListParams(renderingData.cullResults, drawingSettings, m_FilteringSettings);

            m_RendererList = context.CreateRendererList(ref renderListParams);
        }

        // Executes the render pass for every camera each frame.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (m_Material == null)
                return;
            
            m_ColorBuffer = renderingData.cameraData.renderer.cameraColorTargetHandle;

            CommandBuffer commandBuffer = CommandBufferPool.Get();
            using (new ProfilingScope(commandBuffer, m_ProfilingSampler))
            {
                context.ExecuteCommandBuffer(commandBuffer);
                commandBuffer.Clear();

                // Draw filtered items to m_FilterBuffer texture.
                InitRendererLists(ref renderingData, context);
                commandBuffer.DrawRendererList(m_RendererList);

                // Pass filter texture to shaders as a global texture.
                commandBuffer.SetGlobalTexture(Shader.PropertyToID(m_FilterBuffer.name), m_FilterBuffer);

                if (m_ColorBuffer.rt != null && m_TempBuffer.rt != null)
                {
                    Blitter.BlitCameraTexture(commandBuffer, m_ColorBuffer, m_TempBuffer);
                    Blitter.BlitCameraTexture(commandBuffer, m_TempBuffer, m_ColorBuffer, m_Material, 0);
                }
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
            m_TempBuffer?.Release();
            m_FilterBuffer?.Release();
        }
    }
}