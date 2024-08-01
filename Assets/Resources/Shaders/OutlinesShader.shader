Shader "Hidden/Outlines"
{
    Properties {}

    SubShader
    {
        Tags
		{
			"RenderType" = "Opaque"
			"RenderPipeline" = "UniversalPipeline"
		}
		
        Pass
        {
			Name "Render Camera Normals"
			
			Cull Back
			
            HLSLPROGRAM
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram

			#include "DisplayNormalsShader.hlsl"

            ENDHLSL
		}

        Pass
        {
			Name "Render Outline"
			
			Cull Back

            HLSLPROGRAM
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram

            #pragma require msaatex

			#include "OutlinesShader.hlsl"

            ENDHLSL
		}

        Pass
        {
			Name "Copy Pass"

            HLSLPROGRAM
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram

			#include "DownscaleShader.hlsl"
			
            ENDHLSL
		}
    }
}
