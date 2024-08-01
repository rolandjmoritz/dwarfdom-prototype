#ifndef CELSHADERPIXELART
	#define CELSHADERPIXELART

	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GlobalSamplers.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl" // utils for sampling depth info from camera: https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@17.0/manual/writing-shaders-urp-reconstruct-world-position.html
	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl" // for UnpackNormal

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
		real3 positionWS : POSITIONT;
		real3 normalWS : NORMAL;
		real3 tangentWS : TANGENT;
		real3 biTangentWS : TEXCOORD2;
		real3 viewDirection : TEXCOORD1;
        real2 uv : TEXCOORD0;
    };

	// macro defined in Core.hlsl references
	TEXTURE2D_X(_MainTex);
	TEXTURE2D_X(_NormalTexture);
	TEXTURE2D_X(_RampTexture);
	SAMPLER(sampler_MainTex);
	SAMPLER(sampler_NormalTexture);
	SAMPLER(sampler_RampTexture);

    CBUFFER_START(UnityPerMaterial)
		real4 _MainTex_ST;
		real4 _NormalTexture_ST;

		real4 _Color;
		real4 _AmbientColor;
		real4 _SpecularColor;
		real4 _RimColor;

		real4 _BaseShade;
		real _ShadeTones;
		real _ShadeBlend;

		real _Smoothness;
	CBUFFER_END

    VertexOutput VertexProgram(Attributes attrInfo)
    {
        VertexOutput vertInfo;

		vertInfo.positionCS = TransformObjectToHClip(attrInfo.positionOS.xyz); // Clip space vertex position.
		vertInfo.positionWS = TransformObjectToWorld(attrInfo.positionOS.xyz); // World spade vertex position.

		vertInfo.normalWS = TransformObjectToWorldDir(attrInfo.normalOS);
		vertInfo.tangentWS = TransformObjectToWorldDir(attrInfo.tangentOS.xyz);
		vertInfo.biTangentWS = cross(vertInfo.normalWS.xyz, vertInfo.tangentWS.xyz) * attrInfo.tangentOS.w; // last one is the sign

        vertInfo.uv = attrInfo.uv; // Need to transform the UV in the fragment program for multiple textures
		
		if (IsPerspectiveProjection()) // perspective
		{
			vertInfo.viewDirection = TransformWorldToObject(GetCurrentViewPosition()) - attrInfo.positionOS.xyz;
		}
		else // orthographic
		{
			vertInfo.viewDirection = TransformWorldToObjectNormal(-GetViewForwardDir());
		}
		
        return vertInfo;
    }

	// ----- //

	inline real MapNum(real currNum, real oldMin, real oldMax, real newMin, real newMax)
	{
		return (currNum - oldMin) / (oldMax - oldMin) * (newMax - newMin) + newMin;
	}

	// blend value should be 1 for 0.01 (1% blend)
	inline real3 GetShadeColor(real3 toneColor, real shadeValue, real blendValue, int numColors)
	{
		// Determine color segment.
		real shadeValClamp = saturate(shadeValue);
		real segmentBottom, segmentTop;
		real colorStep = 1.f / numColors;
		for (real i = 0; i < 1; i += colorStep)
		{
			if(shadeValClamp >= i && shadeValClamp <= i + colorStep)
			{
				segmentBottom = i;
				segmentTop = i + colorStep;
				break;
			}
		}

		// Determine blending.
		blendValue /= 100;
		toneColor = RgbToHsv(toneColor);

		real topLimit = segmentTop - blendValue;
		real bottomLimit = segmentBottom + blendValue;
		if (shadeValue <= bottomLimit) // blend with previous
		{
			toneColor = real3(toneColor.x, toneColor.y,
				lerp(segmentBottom - colorStep, segmentBottom,
					smoothstep(segmentBottom - blendValue, bottomLimit, shadeValue)
				)
			);
		}
		else if (shadeValue >= topLimit) // blend with next
		{
			toneColor = real3(toneColor.x, toneColor.y,
				lerp(segmentBottom, segmentBottom + colorStep,
					smoothstep(topLimit, segmentTop + blendValue, shadeValue)
				)
			);
		}
		else // no blend
		{
			toneColor = real3(toneColor.x, toneColor.y, segmentBottom);
		}

		return HsvToRgb(toneColor);
	}

	inline void GetLightingInfo(VertexOutput vertInfo, real3 surfaceNormal, real3 viewNormal, out real3 diffuseLight, out real3 specularLight)
	{
		real3 cumulativeColor = real3(0, 0, 0);

		// Main light.
		#if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) || defined(SHADOWS)
			#if SHADOWS_SCREEN
				real4 shadowCoord = ComputeScreenPos(vertInfo.positionCS);
			#else
				real4 shadowCoord = TransformWorldToShadowCoord(vertInfo.positionWS);
			#endif

			Light mainLight = GetMainLight(shadowCoord, vertInfo.positionWS, real4(1, 1, 1, 1));
		#else
			Light mainLight = GetMainLight();
		#endif
		real3 attenuatedColorMain = mainLight.color * mainLight.distanceAttenuation * mainLight.shadowAttenuation;
		real3 mainLightDiffuse = LightingLambert(attenuatedColorMain, _MainLightPosition.xyz, surfaceNormal);
		real3 mainLightSpecular = LightingSpecular(attenuatedColorMain, _MainLightPosition.xyz, surfaceNormal, viewNormal, _SpecularColor, _Smoothness);

		cumulativeColor += mainLight.color * mainLight.distanceAttenuation;

		// Additional lights.
		real3 additionalLightDiffuse, additionalLightSpecular;
		int lightsCount = GetAdditionalLightsCount();
		for (int i = 0; i < lightsCount; ++i)
		{
			#if VERSION_GREATER_EQUAL(10, 1)
				Light currLight = GetAdditionalLight(i, vertInfo.positionWS, half4(1, 1, 1, 1));
			#else
				Light currLight = GetAdditionalLight(i, vertInfo.positionWS);
			#endif

			real3 attenuatedColor = currLight.color * currLight.distanceAttenuation * currLight.shadowAttenuation;
			additionalLightDiffuse += LightingLambert(attenuatedColor, currLight.direction, surfaceNormal);
			additionalLightSpecular += LightingSpecular(attenuatedColor, currLight.direction, surfaceNormal, viewNormal, _SpecularColor, _Smoothness);

			cumulativeColor += currLight.color * currLight.distanceAttenuation;
		}

		// Ambient light.
		real3 ambientLightDiffuse = lerp(SampleSH(surfaceNormal), _AmbientColor.rgb, _AmbientColor.a) * cumulativeColor; //_AmbientColor * cumulativeColor * SampleSH(surfaceNormal);

		// Final colors.
		real specularMax = max(max(_SpecularColor.r, _SpecularColor.g), _SpecularColor.b);
		diffuseLight = mainLightDiffuse + additionalLightDiffuse + ambientLightDiffuse;
		specularLight = mainLightSpecular + additionalLightSpecular;
	}

    real4 FragmentProgram(VertexOutput vertInfo, real facingDir : VFACE) : SV_Target
    {
		// Calculate texture UV information.
		real2 albedoMapUV = TRANSFORM_TEX(vertInfo.uv, _MainTex);
		real2 normalMapUV = TRANSFORM_TEX(vertInfo.uv, _NormalTexture);

		real4 diffuseSample = SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, albedoMapUV);
		clip(diffuseSample.a - 0.1);

		// Calculate surface information.
		real3 viewNormal = normalize(vertInfo.viewDirection);
		real3 surfaceNormal = normalize(vertInfo.normalWS);
		real3 surfaceTangent = normalize(vertInfo.tangentWS);
		real3 surfaceBiTangent = normalize(vertInfo.biTangentWS);
		real3x3 tangentToWorld = real3x3(surfaceTangent, surfaceBiTangent, surfaceNormal);

		real4 sampleNormal = SAMPLE_TEXTURE2D_X(_NormalTexture, sampler_NormalTexture, normalMapUV);
		if (sampleNormal.a > 0.01)
		{
			sampleNormal *= facingDir; // rotate normal map dir when looking at triangles from behind
			surfaceNormal = TransformTangentToWorldDir(UnpackNormal(sampleNormal), tangentToWorld, true); // transformed and normalized normal map value, using built-in function because there are multiple types of formats based on ifdefs
		}

		// Calculate lighting information.
		real3 diffuseLight, specularLight;
		GetLightingInfo(vertInfo, surfaceNormal, viewNormal, diffuseLight, specularLight);

		diffuseLight = RgbToHsv(diffuseLight);
		specularLight = RgbToHsv(specularLight);

		real3 diffuseMult = GetShadeColor(_BaseShade.rgb, diffuseLight.b, _ShadeBlend, _ShadeTones);
		real3 specularMult = GetShadeColor(_BaseShade.rgb, specularLight.b, _ShadeBlend, _ShadeTones);
		// diffuseLight.b = SAMPLE_TEXTURE2D_X_LOD(_RampTexture, sampler_RampTexture, real2(diffuseLight.b, 0.5), 0);
		// specularLight.b = SAMPLE_TEXTURE2D_X_LOD(_RampTexture, sampler_RampTexture, real2(specularLight.b, 0.5), 0);

		diffuseLight = HsvToRgb(diffuseLight) * diffuseMult;
		specularLight = HsvToRgb(specularLight) * specularMult;

		real3 finalColor = diffuseSample.rgb * _Color * (diffuseLight + specularLight);

		return real4(finalColor, 1);
    }

#endif