#ifndef CELSHADER
	#define CELSHADER

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
	TEXTURE2D_X(_BaseMap);
	TEXTURE2D_X(_NormalMap);
	TEXTURE2D_X(_AOMap);
	TEXTURE2D_X(_ShadingRamp);
	SAMPLER(sampler_BaseMap);
	SAMPLER(sampler_NormalMap);
	SAMPLER(sampler_AOMap);

    CBUFFER_START(UnityPerMaterial)
		real4 _BaseMap_ST;
		real4 _NormalMap_ST;
		real4 _AOMap_ST;

		real4 _Color, _AmbientColor;

		real4 _BaseShade;
		real _ShadeTones, _ShadeBlend;
		real _LowToneWeight, _MidToneWeight, _HighToneWeight;

		real _NormalStrength;
		real _Smoothness;
		real _RimThreshold;

		real _DiffuseSmoothing;
		real _SpecularSmoothing;
		real _RimStrength;
		real _RimSmoothing;
		real _DistanceAttenuation;
		real _ShadowAttenuation;
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
			vertInfo.viewDirection = GetCurrentViewPosition() - vertInfo.positionWS;
		}
		else // orthographic
		{
			vertInfo.viewDirection = -GetViewForwardDir();
		}
		
        return vertInfo;
    }

	// ----- //

	inline real MapNum(real currNum, real oldMin, real oldMax, real newMin, real newMax)
	{
		return (currNum - oldMin) / (oldMax - oldMin) * (newMax - newMin) + newMin;
	}

	inline real3 CalculateLight(Light lightSource, real3 surfaceNormal, real3 viewNormal)
	{
		real lightDiffuse = saturate(dot(surfaceNormal, lightSource.direction));
		real lightSpecular = _Smoothness <= 0 ? 0 : pow(saturate(dot(surfaceNormal, SafeNormalize(lightSource.direction + viewNormal))), _Smoothness * _Smoothness) * lightDiffuse;
		real lightRim = (1 - dot(viewNormal, surfaceNormal)) * pow(lightDiffuse, _RimThreshold * _RimThreshold);
		
		lightDiffuse = smoothstep(0, _DiffuseSmoothing, lightDiffuse);
		lightSpecular = smoothstep(0, _SpecularSmoothing, lightSpecular);
		lightRim = smoothstep(1 - _RimStrength - 0.5 * _RimSmoothing, 1 - _RimStrength + 0.5 * _RimSmoothing, lightRim);

		real3 attenuatedColor = lightSource.color * lightSource.distanceAttenuation * smoothstep(0, _ShadowAttenuation, lightSource.shadowAttenuation);
		return attenuatedColor * (lightDiffuse + max(lightSpecular, lightRim));
	}

	inline real3 GetLightingInfo(VertexOutput vertInfo, real3 surfaceNormal, real3 viewNormal)
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
		real3 mainLightColor = CalculateLight(mainLight, surfaceNormal, viewNormal);

		// Additional lights.
		real3 additionalLightColors = real3(0, 0, 0);
		int lightsCount = GetAdditionalLightsCount();
		for (int i = 0; i < lightsCount; ++i)
		{
			#if VERSION_GREATER_EQUAL(10, 1)
				Light currLight = GetAdditionalLight(i, vertInfo.positionWS, half4(1, 1, 1, 1));
			#else
				Light currLight = GetAdditionalLight(i, vertInfo.positionWS);
			#endif
			additionalLightColors += CalculateLight(currLight, surfaceNormal, viewNormal);
		}

		// Ambient light.
		real3 ambientLightColor = lerp(real3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w), _AmbientColor.rgb, _AmbientColor.a);
		
		return mainLightColor + additionalLightColors + ambientLightColor;
	}

	inline real GetShadeTone(real shadeValue, real blendValue, int numColors)
	{
		real _ShadesArray[10];

		// Calculate the weights.
		real colorStep = 1.f / numColors;
		real weightTotal = _LowToneWeight + _MidToneWeight + _HighToneWeight;
		real weightMax = max(_LowToneWeight, max(_MidToneWeight, _HighToneWeight));
		real lowToneMult = _LowToneWeight / weightMax;
		real midToneMult = _MidToneWeight / weightMax;
		real hiToneMult = _HighToneWeight / weightMax;

		int numLow = floor(_LowToneWeight / weightTotal * numColors);
		int numHigh = floor(_HighToneWeight / weightTotal * numColors);
		int numMid = numColors - numLow - numHigh - 1;

		real stepLow = colorStep * lowToneMult;
		real stepHigh = colorStep * hiToneMult;
		real stepMid = (1 - numLow * stepLow - numHigh * stepHigh) / numMid;

		// Determine color segment.
		_ShadesArray[0] = 0;
		_ShadesArray[numColors - 1] = 1;
		for (int i = 0; i < numLow; ++i)
			_ShadesArray[1 + i] = _ShadesArray[i] + stepLow;
		for (int i = 0; i < numHigh; ++i)
			_ShadesArray[numColors - 2 - i] = _ShadesArray[numColors - 1 - i] - stepHigh;
		for (int i = 0; i < numMid; ++i)
			_ShadesArray[numLow + 1 + i] = _ShadesArray[numLow + i] + stepMid;

		real segmentPrev, segmentNext;
		real segmentTop, segmentBottom;
		for (int k = 0; k < numColors; ++k)
		{
			real borderLow = _ShadesArray[k];
			real borderHigh = _ShadesArray[k + 1];
			if (shadeValue >= borderLow && shadeValue < borderHigh)
			{
				segmentTop = borderHigh;
				segmentBottom = borderLow;
				segmentPrev = (k == 0) ? borderLow : _ShadesArray[k - 1];
				segmentNext = (k == numColors - 1) ? _ShadesArray[k] : _ShadesArray[k + 1];
				break;
			}
		}

		// Determine blending.
		real topLimit = segmentTop - blendValue;
		real bottomLimit = segmentBottom + blendValue;
		if (shadeValue <= bottomLimit) // blend with previous
		{
			return lerp(segmentPrev, segmentBottom,
				smoothstep(segmentBottom - blendValue, bottomLimit, shadeValue));
		}
		else if (shadeValue >= topLimit) // blend with next
		{
			return lerp(segmentBottom, segmentNext,
				smoothstep(topLimit, segmentTop + blendValue, shadeValue));
		}
		else // no blend
		{
			return segmentBottom;
		}
	}

    real4 FragmentProgram(VertexOutput vertInfo) : SV_Target
    {
		// Calculate texture UV information.
		real2 diffuseMapUV = TRANSFORM_TEX(vertInfo.uv, _BaseMap);
		real2 normalMapUV = TRANSFORM_TEX(vertInfo.uv, _NormalMap);
		real2 aoMapUV = TRANSFORM_TEX(vertInfo.uv, _AOMap);

		// Calculate surface information.
		real3 viewNormal = normalize(vertInfo.viewDirection);
		real3 surfaceNormal = normalize(vertInfo.normalWS);
		real3 surfaceTangent = normalize(vertInfo.tangentWS);
		real3 surfaceBiTangent = normalize(vertInfo.biTangentWS);
		real3x3 tangentToWorld = real3x3(surfaceTangent, surfaceBiTangent, surfaceNormal);

		real4 sampleNormal = SAMPLE_TEXTURE2D_X(_NormalMap, sampler_NormalMap, normalMapUV);
		if (sampleNormal.a > 0.01)
			surfaceNormal = TransformTangentToWorldDir(UnpackNormalScale(sampleNormal, _NormalStrength), tangentToWorld, true); // transformed and normalized normal map value, using built-in function because there are multiple types of formats based on ifdefs

		// Calculate lighting information.
		real4 diffuseSample = SAMPLE_TEXTURE2D_X(_BaseMap, sampler_BaseMap, diffuseMapUV);
		real4 aoSample = SAMPLE_TEXTURE2D_X(_AOMap, sampler_AOMap, aoMapUV);
		real3 lightColor = GetLightingInfo(vertInfo, surfaceNormal, viewNormal) * aoSample;

		#ifdef USE_SHADING_RAMP
			/*real4 shadingSample = SAMPLE_TEXTURE2D_X(_ShadingRamp, sampler_PointClamp, real2(lightColor.b, 0.5));
			if (shadingSample.a > 0.01)
				lightColor.b = shadingSample.r;*/

			lightColor = RgbToHsv(lightColor);
			lightColor = lerp(_BaseShade, real3(1, 1, 1), GetShadeTone(lightColor.b, _ShadeBlend, _ShadeTones));
		#endif

		real3 finalColor = diffuseSample.rgb * _Color.rgb * lightColor;
		return real4(finalColor, 1);

		/*real3 sampleNormal = SAMPLE_TEXTURE2D(_NormalTexture, sampler_NormalTexture, vertInfo.uv);

		// main light in the scene
		Light mainLight = GetMainLight(0);
		real4 mainLightColor = real4(mainLight.color, 1);
		real shadowDistance = mainLight.distanceAttenuation;
		real shadowStrength = mainLight.shadowAttenuation;

		// diffuse lighting
		real3 surfaceNormal = SafeNormalize(vertInfo.normal); //SafeNormalize(cross(normalize(vertInfo.tangent), sampleNormal));
				
		real surfaceDotLight = dot(_MainLightPosition.xyz, surfaceNormal);
		real lightIntensity = smoothstep(0, 0.01 * _BlendStrengthAmb, surfaceDotLight) * shadowDistance * shadowStrength;
				
		real4 worldspaceLight = lightIntensity * mainLightColor;
		real4 ambientLight = _AmbientColor * mainLightColor * _ShadingStrength;
				
		// specular highlight
		real3 viewNormal = SafeNormalize(vertInfo.viewDirection);
		real3 lightToCam = SafeNormalize(_MainLightPosition.xyz + viewNormal);
		real surfaceDotReflection = real(saturate(dot(surfaceNormal, lightToCam)));
				
		real specularIntensity = smoothstep(0, 0.01 * _BlendStrengthSpec, pow(max(0, surfaceDotReflection * lightIntensity), _Smoothness * _Smoothness)) * shadowDistance * shadowStrength;
		real4 specularLight = _SpecularColor * mainLightColor * specularIntensity;
				
		// edge lighting
		real surfaceDotView = dot(viewNormal, surfaceNormal);
		real rimStrength = 1 - _RimStrength;
		real rimIntensity = (1 - surfaceDotView) * pow(max(0, surfaceDotLight), _RimThreshold); // only apply rim lighting to unshaded areas
		rimIntensity = smoothstep(rimStrength - 0.01, rimStrength + 0.01 * _BlendStrengthRim, rimIntensity);
				
		real4 rimLight = _RimColor * mainLightColor * rimIntensity;
		
		// ambient occlusion map color sample
		real aoIntensity = floor(SAMPLE_TEXTURE2D(_AOTexture, sampler_AOTexture, vertInfo.uv).r * (_AOMapLevels - 1) + _AOBrightPreference) / (_AOMapLevels - 1);
		aoIntensity = min(1, smoothstep(_AOIntensityMin, _AOIntensityMax, aoIntensity) + _AOIntensityMin);

		real4 aoColor = surfaceDotLight > 0 ? (mainLightColor * aoIntensity + ambientLight) : real4(1, 1, 1, 1); // don't apply AO map to already shaded areas

		// sample the diffuse texture
		real4 diffuseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, vertInfo.uv) * _Color;

		if (_EnergyConservation > 0)
		{
			// monochromatic light energy conservation
			real specularMax = max(max(_SpecularColor.r, _SpecularColor.g), _SpecularColor.b);
			diffuseColor *= 1 - specularMax;			
		}

		// sample texture and apply shading
        real4 finalColor = diffuseColor * (worldspaceLight + ambientLight + specularLight + rimLight) * aoColor;*/
    }

#endif