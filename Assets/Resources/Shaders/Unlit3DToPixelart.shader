Shader "Cure-All/Unlit 3D To Pixelart"
{
    Properties
    {
		[MainTexture] _MainTex ("Albedo Map", 2D) = "white" {}
		[MainColor] _Color ("Albedo Color", Color) = (1, 1, 1, 1)

		[Space]
		[Normal] _NormalTexture ("Normal Map", 2D) = "bump" {}
		[Toggle(DISPLAY_NORMALS_ONLY)] _DisplayNormals ("Render Normals Only", Float) = 0

		[Space]
		_Sharpness ("Sharpness", Range(0, 100)) = 0
		[Toggle(SHARPEN_AFTER_QUANTIZING)] _SharpenQuantized ("Sharpen Color Reduction", Float) = 0

		[Space]
		[NoScaleOffset] _PaletteTex ("Color Palette", 2D) = "black" {}
		//_PaletteSizeY ("Color Palette Rows", Int) = 4
		//_PaletteSizeX ("Color Palette Columns", Int) = 16

		[Space]
		_RedColorCount ("Red Color Count", Int) = 64
		_GreenColorCount ("Green Color Count", Int) = 64
		_BlueColorCount ("Blue Color Count", Int) = 64
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
			
			Cull Off
			
            HLSLPROGRAM
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram

			#pragma multi_compile_fwdbase
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _SHADOWS_SOFT

			#pragma shader_feature DISPLAY_NORMALS_ONLY
			#pragma shader_feature SHARPEN_AFTER_QUANTIZING

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GlobalSamplers.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"

			struct Attributes // world position
			{
				real4 positionOS : POSITION;
				real4 tangentOS : TANGENT;
				real3 normalOS : NORMAL;
				real2 uv : TEXCOORD0;
			};

			struct VertexOutput // local position
			{
				real4 positionCS : POSITION0;
				real3 normalWS : NORMAL;
				real3 tangentWS : TANGENT;
				real3 biTangentWS : TEXCOORD2;
				real2 uv : TEXCOORD0;
			};

			TEXTURE2D_X(_MainTex);
			SAMPLER(sampler_MainTex);
			TEXTURE2D_X(_NormalTexture);
			SAMPLER(sampler_NormalTexture);
			TEXTURE2D_X(_PaletteTex);


			CBUFFER_START(UnityPerMaterial)
				uniform real4 _MainTex_ST;
				uniform real4 _NormalTexture_ST;
				uniform real4 _MainTex_TexelSize;
				uniform real4 _NormalTexture_TexelSize;
				uniform real4 _PaletteTex_TexelSize;

				real _Sharpness;
				int _PaletteSizeX, _PaletteSizeY;
				int _RedColorCount, _GreenColorCount, _BlueColorCount;
			CBUFFER_END

			real4 FindNearestColor(real4 origColor)
			{
				real4 nearestColor = origColor;
				float minDistance = 1000000;

				for (real y = _PaletteTex_TexelSize.y / 2; y < 1; y += _PaletteTex_TexelSize.y)
				{
					for (real x = _PaletteTex_TexelSize.x / 2; x < 1; x += _PaletteTex_TexelSize.x)
					{
						real4 paletteColor = SAMPLE_TEXTURE2D_X_LOD(_PaletteTex, sampler_PointClamp, real2(x, y), 0);
						if (paletteColor.a < 0.01) // in case no palette is assigned
							return origColor;

						real colDistance = length(origColor.rgb - paletteColor.rgb);
						if (colDistance < minDistance)
						{
							minDistance = colDistance;
							nearestColor = paletteColor;
						}
					}
				}

				return nearestColor;
			}

			VertexOutput VertexProgram(Attributes attrInfo)
			{
				VertexOutput vertInfo;

				vertInfo.positionCS = TransformObjectToHClip(attrInfo.positionOS.xyz); // Clip space vertex position.

				vertInfo.normalWS = TransformObjectToWorldDir(attrInfo.normalOS);
				vertInfo.tangentWS = TransformObjectToWorldDir(attrInfo.tangentOS.xyz);
				vertInfo.biTangentWS = cross(vertInfo.normalWS.xyz, vertInfo.tangentWS.xyz) * attrInfo.tangentOS.w;

				vertInfo.uv = attrInfo.uv;
		
				return vertInfo;
			}

			real4 FragmentProgram(VertexOutput vertInfo) : SV_Target
			{
				real2 albedoMapUV = TRANSFORM_TEX(vertInfo.uv, _MainTex);
				real2 normalMapUV = TRANSFORM_TEX(vertInfo.uv, _NormalTexture);

				real3 surfaceNormal = normalize(vertInfo.normalWS);
				real3 surfaceTangent = normalize(vertInfo.tangentWS);
				real3 surfaceBiTangent = normalize(vertInfo.biTangentWS);
				real3x3 tangentToWorld = real3x3(surfaceTangent, surfaceBiTangent, surfaceNormal);

				real4 sampleNormal = SAMPLE_TEXTURE2D_X(_NormalTexture, sampler_NormalTexture, normalMapUV);
				if (sampleNormal.a > 0.01)
				{
					surfaceNormal = TransformTangentToWorldDir(UnpackNormal(sampleNormal), tangentToWorld, true);
				}

				real4 sampleAlbedo = SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, albedoMapUV);
				clip(sampleAlbedo - 0.5);

				real4 nU = SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, albedoMapUV + real2(0, _MainTex_TexelSize.y));
				real4 nD = SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, albedoMapUV - real2(0, _MainTex_TexelSize.y));
				real4 nL = SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, albedoMapUV - real2(_MainTex_TexelSize.x, 0));
				real4 nR = SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, albedoMapUV + real2(_MainTex_TexelSize.x, 0));

				#ifndef SHARPEN_AFTER_QUANTIZING
					nU *= _Sharpness * -1;
					nD *= _Sharpness * -1;
					nL *= _Sharpness * -1;
					nR *= _Sharpness * -1;
					real4 cen = sampleAlbedo * _Sharpness * 4 + 1 + nU + nD + nL + nR;
				#endif

				sampleAlbedo.r = floor((_RedColorCount - 1.0f) * sampleAlbedo.r + 0.5) / (_RedColorCount - 1.0f);
				sampleAlbedo.g = floor((_GreenColorCount - 1.0f) * sampleAlbedo.g + 0.5) / (_GreenColorCount - 1.0f);
				sampleAlbedo.b = floor((_BlueColorCount - 1.0f) * sampleAlbedo.b + 0.5) / (_BlueColorCount - 1.0f);

				sampleAlbedo = FindNearestColor(sampleAlbedo);

				#ifdef SHARPEN_AFTER_QUANTIZING
					nU.r = floor((_RedColorCount - 1.0f) * nU.r + 0.5) / (_RedColorCount - 1.0f);
					nU.g = floor((_GreenColorCount - 1.0f) * nU.g + 0.5) / (_GreenColorCount - 1.0f);
					nU.b = floor((_BlueColorCount - 1.0f) * nU.b + 0.5) / (_BlueColorCount - 1.0f);
					nU = FindNearestColor(nU);

					nD.r = floor((_RedColorCount - 1.0f) * nD.r + 0.5) / (_RedColorCount - 1.0f);
					nD.g = floor((_GreenColorCount - 1.0f) * nD.g + 0.5) / (_GreenColorCount - 1.0f);
					nD.b = floor((_BlueColorCount - 1.0f) * nD.b + 0.5) / (_BlueColorCount - 1.0f);
					nD = FindNearestColor(nD);

					nL.r = floor((_RedColorCount - 1.0f) * nL.r + 0.5) / (_RedColorCount - 1.0f);
					nL.g = floor((_GreenColorCount - 1.0f) * nL.g + 0.5) / (_GreenColorCount - 1.0f);
					nL.b = floor((_BlueColorCount - 1.0f) * nL.b + 0.5) / (_BlueColorCount - 1.0f);
					nL = FindNearestColor(nL);

					nR.r = floor((_RedColorCount - 1.0f) * nR.r + 0.5) / (_RedColorCount - 1.0f);
					nR.g = floor((_GreenColorCount - 1.0f) * nR.g + 0.5) / (_GreenColorCount - 1.0f);
					nR.b = floor((_BlueColorCount - 1.0f) * nR.b + 0.5) / (_BlueColorCount - 1.0f);
					nR = FindNearestColor(nR);

					nU *= _Sharpness * -1;
					nD *= _Sharpness * -1;
					nL *= _Sharpness * -1;
					nR *= _Sharpness * -1;
					real4 cen = sampleAlbedo * _Sharpness * 4 + 1 + nU + nD + nL + nR;
				#endif


				#ifdef DISPLAY_NORMALS_ONLY
					return real4(surfaceNormal * 0.5 + 0.5, 1);
				#else
					return sampleAlbedo * cen;
				#endif
			}

            ENDHLSL
		}
    }
}
