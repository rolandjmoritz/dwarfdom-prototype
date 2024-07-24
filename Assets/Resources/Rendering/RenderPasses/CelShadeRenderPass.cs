using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using static Unity.Burst.Intrinsics.X86.Avx;

namespace CureAllGame
{
    /*internal class CelShadeRenderPass : ScriptableRenderPass
	{
        private static readonly int m_Identifier = Shader.PropertyToID("SomethingOrOther2"); // maybe serialize the other properties for more speed+

        private const string m_ProfilerTag = "Cel Shading Pass";
        private ProfilingSampler m_ProfilingSampler = new(m_ProfilerTag);

        private RenderTargetIdentifier m_ColorBuffer;
        private RenderTargetIdentifier m_TempBuffer;
        //private RTHandle m_ColorBuffer;
        //private RTHandle m_TempBuffer;

        private PixelizeComponent m_Component;
        private Material m_Material;


        public CelShadeRenderPass(Material renderMaterial)
        {
            m_Material = renderMaterial;
            renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            m_ColorBuffer = renderingData.cameraData.renderer.cameraColorTarget;
            cmd.GetTemporaryRT(m_Identifier, renderingData.cameraData.cameraTargetDescriptor, FilterMode.Trilinear);
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            m_Component = VolumeManager.instance.stack.GetComponent<PixelizeComponent>();
            m_TempBuffer = new RenderTargetIdentifier(m_Identifier);
            ConfigureTarget(m_ColorBuffer);
        }

        // Executes the render pass for every camera each frame.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (m_Material == null)
                return;

            m_Material.SetFloat("_Spread", m_Component.m_Spread.value);
            m_Material.SetInt("_RedColorCount", m_Component.m_RedColorCount.value);
            m_Material.SetInt("_GreenColorCount", m_Component.m_GreenColorCount.value);
            m_Material.SetInt("_BlueColorCount", m_Component.m_BlueColorCount.value);
            m_Material.SetInt("_BayerLevel", m_Component.m_BayerLevel.value);

            CommandBuffer commandBuffer = CommandBufferPool.Get();
            using (new ProfilingScope(commandBuffer, m_ProfilingSampler))
            {
                context.ExecuteCommandBuffer(commandBuffer);
                commandBuffer.Clear();

                Blit(commandBuffer, m_ColorBuffer, m_TempBuffer, m_Material, 0);
                Blit(commandBuffer, m_TempBuffer, m_ColorBuffer);
            }

            context.ExecuteCommandBuffer(commandBuffer);
            commandBuffer.Clear();
            CommandBufferPool.Release(commandBuffer);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(m_Identifier);
            // m_ColorBuffer = null;
        }

        public void Dispose()
        {
            // m_TempBuffer.Release();
        }
    }*/
}