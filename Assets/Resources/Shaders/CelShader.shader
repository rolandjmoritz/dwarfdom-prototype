Shader "Cure-All/Cel Shading"
{
    Properties
    {
        [MainTexture] _BaseMap ("Albedo Map", 2D) = "white" {}		
		[Normal] _NormalMap ("Normal Map", 2D) = "bump" {}
		_NormalStrength ("Normal Strength", Range(0, 10)) = 1
		_AOMap ("Ambient Occlusion Map", 2D) = "white" {}
		[NoScaleOffset] _ShadingRamp ("Shading Ramp", 2D) = "black" {}

		[Space]
		[MainColor] _Color ("Albedo Color", Color) = (1, 1, 1, 1)
		_AmbientColor ("Ambient Color", Color) = (0, 0, 0, 1)
		
		[Space]
		[Toggle(USE_SHADING_RAMP)] _UseShadingRamp ("Use Shading Ramp", Float) = 0
		_BaseShade ("Shading Tone", Color) = (1, 1, 1, 1)
		_ShadeTones ("Shade Tones", Range(2, 10)) = 5
		_ShadeBlend ("Blend Strength", Range(0, 1)) = 1
		_LowToneWeight ("Low Tone Weight", Range(0, 10)) = 1
		_MidToneWeight ("Mid Tone Weight", Range(0, 10)) = 1
		_HighToneWeight ("High Tone Weight", Range(0, 10)) = 1

		[Space]
		_Smoothness ("Smoothness", Range(0, 50)) = 30
		_RimThreshold ("Rim Threshold", Range(0, 5)) = 0.5
		
		[Space]
		_DiffuseSmoothing ("Diffuse Smoothing", Range(0, 1)) = 0.02
		_SpecularSmoothing ("Specular Smoothing", Range(0, 1)) = 0.5
		_RimStrength ("Rim Strength", Range(0, 1)) = 0.3
		_RimSmoothing ("Rim Smoothing", Range(0, 1)) = 0.1
		_DistanceAttenuation ("Light Distance Attenuation", Range(0, 1)) = 1
		_ShadowAttenuation ("Shadow Attenuation", Range(0, 1)) = 0.02
    }

    SubShader
    {
		LOD 100 // indicates how computationally demanding it is

        Tags
		{
			"RenderType" = "Opaque"
			"RenderPipeline" = "UniversalPipeline"
		}
		
        Pass
        {
			Name "Directional Lighting"
			Tags
			{
				"LightMode" = "UniversalForward"
			}

			Cull Back
			ZWrite On
			Blend One OneMinusSrcAlpha
			
            HLSLPROGRAM
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram

			#pragma multi_compile_fwdbase
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS

			#pragma shader_feature USE_SHADING_RAMP

			#include "CelShader.hlsl"
			
            ENDHLSL
		}

		UsePass "Universal Render Pipeline/Lit/ShadowCaster"
		UsePass "Universal Render Pipeline/Lit/GBuffer"
		UsePass "Universal Render Pipeline/Lit/DepthOnly"
		UsePass "Universal Render Pipeline/Lit/DepthNormals"
    }
}
