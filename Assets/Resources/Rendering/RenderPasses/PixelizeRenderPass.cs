using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Experimental.Rendering.RenderGraphModule;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace CureAllGame
{
    public class PixelizeRenderPass : ScriptableRenderPass
	{
        private Material m_Material;
        private RTHandle m_TextureHandle;
        private RenderTextureDescriptor m_TextureDescriptor;

        public PixelizeRenderPass(Material renderMaterial)
        {
            m_Material = renderMaterial;
            m_TextureDescriptor = new(Screen.width, Screen.height, RenderTextureFormat.Default, 0);
        }

        // Called before executing render pass.
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            // Camera target size.
            m_TextureDescriptor.width = cameraTextureDescriptor.width;
            m_TextureDescriptor.height = cameraTextureDescriptor.height;

            // Reallocate the handle to the texture if the descriptor changes.
            RenderingUtils.ReAllocateIfNeeded(ref m_TextureHandle, m_TextureDescriptor);
        }

        // Executes the render pass for every camera each frame.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer commandBuffer = CommandBufferPool.Get();

            var cameraTargetHandle = renderingData.cameraData.renderer.cameraColorTargetHandle;

            Blit(commandBuffer, cameraTargetHandle, m_TextureHandle, m_Material, 0); // Do something via a material shader.
            Blit(commandBuffer, m_TextureHandle, cameraTargetHandle, m_Material, 1); // Copy texture back.

            CommandBufferPool.Release(commandBuffer);
        }

        // Destroys the material and texture handle after execution is done.
        public void Dispose()
        {
        #if UNITY_EDITOR
            if (EditorApplication.isPlaying)
                Object.Destroy(m_Material);
            else
                Object.DestroyImmediate(m_Material);
        #else
            Object.Destroy(m_Material);
        #endif

            if (m_TextureHandle is not null)
                m_TextureHandle.Release();
        }
    }
}