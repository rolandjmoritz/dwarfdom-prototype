#ifndef CELSHADER
	#define CELSHADER

	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GlobalSamplers.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl" // utils for sampling depth info from camera: https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@17.0/manual/writing-shaders-urp-reconstruct-world-position.html

    struct Attributes // world position
    {
        real4 position : POSITION;
		real4 tangent : TANGENT;
		real3 normal : NORMAL;
        real2 uv : TEXCOORD0;
    };

    struct VertexOutput // local position
    {
        real4 position : POSITION0;
		real4 shadowCoord : TEXCOORD2;
		real3 normal : NORMAL;
		real3 positionWS : POSITIONT;
		real3 viewDirection : TEXCOORD1;
        real2 uv : TEXCOORD0;
    };

	// macro defined in Core.hlsl references
	TEXTURE2D(_MainTex);
	TEXTURE2D(_NormalTexture);
	TEXTURE2D(_AOTexture);

    CBUFFER_START(UnityPerMaterial)
		real4 _MainTex_ST;

		real4 _Color;
		real4 _AmbientColor;
		real4 _SpecularColor;
		real4 _RimColor;

		real _EnergyConservation;
		real _Smoothness;
		real _ShadingStrength;
		real _RimStrength;
		real _RimThreshold;
		real _BlendStrengthAmb;
		real _BlendStrengthSpec;
		real _BlendStrengthRim;

		real _AOMapLevels;
		real _AOBrightPreference;
		real _AOIntensityMin;
		real _AOIntensityMax;
	CBUFFER_END

	real MapNum(real currNum, real oldMin, real oldMax, real newMin, real newMax)
	{
		return (currNum - oldMin) / (oldMax - oldMin) * (newMax - newMin) + newMin;
	}

    VertexOutput VertexProgram(Attributes attrInfo)
    {
        VertexOutput vertInfo;

		vertInfo.position = TransformObjectToHClip(attrInfo.position);
		vertInfo.normal = TransformObjectToWorldNormal(attrInfo.normal);
        vertInfo.uv = TRANSFORM_TEX(attrInfo.uv, _MainTex); // macro defined in Macros.hlsl
		vertInfo.positionWS = TransformObjectToWorld(attrInfo.position);
		
		VertexPositionInputs vertexInput = GetVertexPositionInputs(attrInfo.position);
		vertInfo.shadowCoord = GetShadowCoord(vertexInput);

		if (IsPerspectiveProjection()) // perspective
		{
			vertInfo.viewDirection = TransformWorldToObject(GetCurrentViewPosition()) - attrInfo.position;
		}
		else // orthographic
		{
			vertInfo.viewDirection = TransformWorldToObjectNormal(-GetViewForwardDir());
		}
		
        return vertInfo;
    }

    real4 FragmentProgram(VertexOutput vertInfo) : SV_Target
    {
		real3 sampleNormal = SAMPLE_TEXTURE2D(_NormalTexture, sampler_LinearClamp, vertInfo.uv);

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
		real aoIntensity = floor(SAMPLE_TEXTURE2D(_AOTexture, sampler_LinearClamp, vertInfo.uv).r * (_AOMapLevels - 1) + _AOBrightPreference) / (_AOMapLevels - 1);
		aoIntensity = min(1, smoothstep(_AOIntensityMin, _AOIntensityMax, aoIntensity) + _AOIntensityMin);

		real4 aoColor = surfaceDotLight > 0 ? (mainLightColor * aoIntensity + ambientLight) : real4(1, 1, 1, 1); // don't apply AO map to already shaded areas

		// sample the diffuse texture
		real4 diffuseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, vertInfo.uv) * _Color;

		if (_EnergyConservation > 0)
		{
			// monochromatic light energy conservation
			real specularMax = max(max(_SpecularColor.r, _SpecularColor.g), _SpecularColor.b);
			diffuseColor *= 1 - specularMax;			
		}

		// sample texture and apply shading
        real4 finalColor = diffuseColor * (worldspaceLight + ambientLight + specularLight + rimLight) * aoColor;

        return finalColor;
    }

#endif