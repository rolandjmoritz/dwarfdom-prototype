Shader "Cure-All/Cel Shading"
{
    Properties
    {
        [MainTexture] _MainTex ("Albedo Map", 2D) = "white" {}
		[NoScaleOffset] _NormalTexture ("Normal Map", 2D) = "black" {}
        [NoScaleOffset] _AOTexture ("Ambient Occlusion Map", 2D) = "white" {}
		_AOMapLevels ("AO Color Levels", Range(2, 255)) = 2
		_AOBrightPreference ("Quantization Brightness Preference", Range(0, 1)) = 0.5
		_AOIntensityMin ("AO Minimum Intensity", Range(0, 1)) = 0
		_AOIntensityMax ("AO Maximum Intensity", Range(0, 1)) = 1

		[Space]
		[Toggle()] _EnergyConservation ("Light Energy Conservation", Float) = 0
		[MainColor] _Color ("Color", Color) = (1, 1, 1, 1)
		_AmbientColor ("Ambient Color", Color) = (0.4, 0.4, 0.4, 1)
		_SpecularColor ("Specular Color", Color) = (0.9, 0.9, 0.9, 1)
		_RimColor ("Rim Color", Color) = (0.8, 0.8, 0.8, 1)
		
		[Space]
		_Smoothness ("Smoothness", Range(0, 100)) = 50
		
		[Space]
		_ShadingStrength ("Ambient Strength", Range(0, 1)) = 1
		_RimStrength ("Rim Strength", Range(0, 1)) = 0.275
		_RimThreshold ("Rim Threshold", Range(0, 1)) = 0.1
		
		[Space]
		_BlendStrengthAmb ("Ambient Blend Strength", Range(0, 10)) = 1
		_BlendStrengthSpec ("Specular Blend Strength", Range(0.5, 10)) = 1
		_BlendStrengthRim ("Rim Blend Strength", Range(0, 10)) = 1
    }

    SubShader
    {
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
				"PassFlags" = "OnlyDirectional"
			}

			Cull Off
			
            HLSLPROGRAM
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram

			#pragma multi_compile_fwdbase
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _SHADOWS_SOFT

			#include "CelShader.hlsl"
			
            ENDHLSL
		}
		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
