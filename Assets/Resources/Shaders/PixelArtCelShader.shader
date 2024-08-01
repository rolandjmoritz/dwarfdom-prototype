Shader "Cure-All/Pixel Art Cel Shading"
{
    Properties
    {
        [MainTexture] _MainTex ("Albedo Map", 2D) = "white" {}
		[MainColor] _Color ("Color", Color) = (1, 1, 1, 1)
		
		[Space]
		[Normal] _NormalTexture ("Normal Map", 2D) = "bump" {}

		[Space]
		_AmbientColor ("Ambient Color", Color) = (0.4, 0.4, 0.4, 1)
		_RimColor ("Rim Color", Color) = (0.8, 0.8, 0.8, 1)
		
		[Space]
		_BaseShade ("Shading Tone", Color) = (1, 1, 1, 1)
		_ShadeTones ("Shade Tones", Range(2, 20)) = 5
		_ShadeBlend ("Shading Blend", Range(0, 10)) = 1

		[Space]
		_SpecularColor ("Specular Color", Color) = (0.6, 0.6, 0.6, 1)
		_Smoothness ("Smoothness", Range(0.1, 100)) = 30
		
		[Space]
		_ShadingStrength ("Ambient Strength", Range(0, 1)) = 1
		_RimStrength ("Rim Strength", Range(0, 1)) = 0.275
		_RimThreshold ("Rim Threshold", Range(0, 1)) = 0.1
    }

    SubShader
    {
        Tags
		{
			"Queue" = "Transparent"
			"RenderType" = "Transparent"
			"PreviewType" = "Plane"
			"CanUseSpriteAtlas" = "True"
			"IgnoreProjector" = "True"
			"RenderPipeline" = "UniversalPipeline"
		}
		
        Pass
        {
			Name "Directional Lighting"
			
			Cull Off
			Blend One OneMinusSrcAlpha
			
            HLSLPROGRAM
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram

			#pragma multi_compile_fwdbase
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _SHADOWS_SOFT

			#include "PixelArtCelShader.hlsl"
			
            ENDHLSL
		}
		UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}
