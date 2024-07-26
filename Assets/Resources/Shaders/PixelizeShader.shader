Shader "Cure-All/Pixelize"
{
    Properties { }

    SubShader
    {
        Tags
		{
			"RenderType" = "Opaque"
            "LightMode" = "UniversalForward"
			"RenderPipeline" = "UniversalPipeline"
		}
		
        Pass
        {
			Name "Pixelization Pass"


            HLSLPROGRAM
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram

			#include "PixelizeShader.hlsl"
			
            ENDHLSL
		}

        Pass
        {
			Name "Downscaling Pass"


            HLSLPROGRAM
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram

			#include "DownscaleShader.hlsl"
			
            ENDHLSL
		}
    }
}