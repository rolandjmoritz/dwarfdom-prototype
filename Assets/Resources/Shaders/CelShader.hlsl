#ifndef CELSHADER
	#define CELSHADER

	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl" // utils for sampling depth info from camera: https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@17.0/manual/writing-shaders-urp-reconstruct-world-position.html

    struct Attributes // world position
    {
        float4 position : POSITION;
		float4 tangent : TANGENT;
		float3 normal : NORMAL;
        float2 uv : TEXCOORD0;
    };

    struct VertexOutput // local position
    {
        float4 position : POSITION0;
		float4 shadowCoord : TEXCOORD2;
		float3 normal : NORMAL;
		float3 positionWS : POSITIONT;
		float3 viewDirection : TEXCOORD1;
        float2 uv : TEXCOORD0;
    };

	// macro defined in Core.hlsl references
	TEXTURE2D(_MainTex);
	TEXTURE2D(_NormalTexture);
	TEXTURE2D(_AOTexture);
	SAMPLER(sampler_MainTex);
	SAMPLER(sampler_NormalTexture);
	SAMPLER(sampler_AOTexture);

    CBUFFER_START(UnityPerMaterial)
		float4 _MainTex_ST;

		float4 _Color;
		float4 _AmbientColor;
		float4 _SpecularColor;
		float4 _RimColor;

		float _EnergyConservation;
		float _Smoothness;
		float _ShadingStrength;
		float _RimStrength;
		float _RimThreshold;
		float _BlendStrengthAmb;
		float _BlendStrengthSpec;
		float _BlendStrengthRim;

		float _AOMapLevels;
		float _AOBrightPreference;
		float _AOIntensityMin;
		float _AOIntensityMax;

	CBUFFER_END

	float MapNum(float currNum, float oldMin, float oldMax, float newMin, float newMax)
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

    float4 FragmentProgram(VertexOutput vertInfo) : SV_Target
    {
		float3 sampleNormal = SAMPLE_TEXTURE2D(_NormalTexture, sampler_NormalTexture, vertInfo.uv);

		// main light in the scene
		Light mainLight = GetMainLight(0);
		float4 mainLightColor = float4(mainLight.color, 1);
		float shadowDistance = mainLight.distanceAttenuation;
		float shadowStrength = mainLight.shadowAttenuation;

		// diffuse lighting
		float3 surfaceNormal = SafeNormalize(vertInfo.normal); //SafeNormalize(cross(normalize(vertInfo.tangent), sampleNormal));
				
		float surfaceDotLight = dot(_MainLightPosition.xyz, surfaceNormal);
		float lightIntensity = smoothstep(0, 0.01 * _BlendStrengthAmb, surfaceDotLight) * shadowDistance * shadowStrength;
				
		float4 worldspaceLight = lightIntensity * mainLightColor;
		float4 ambientLight = _AmbientColor * mainLightColor * _ShadingStrength;
				
		// specular highlight
		float3 viewNormal = SafeNormalize(vertInfo.viewDirection);
		float3 lightToCam = SafeNormalize(_MainLightPosition.xyz + viewNormal);
		float surfaceDotReflection = float(saturate(dot(surfaceNormal, lightToCam)));
				
		float specularIntensity = smoothstep(0, 0.01 * _BlendStrengthSpec, pow(surfaceDotReflection * lightIntensity, _Smoothness * _Smoothness)) * shadowDistance * shadowStrength;
		float4 specularLight = _SpecularColor * mainLightColor * specularIntensity;
				
		// edge lighting
		float surfaceDotView = dot(viewNormal, surfaceNormal);
		float rimStrength = 1 - _RimStrength;
		float rimIntensity = (1 - surfaceDotView) * pow(surfaceDotLight, _RimThreshold); // only apply rim lighting to unshaded areas
		rimIntensity = smoothstep(rimStrength - 0.01, rimStrength + 0.01 * _BlendStrengthRim, rimIntensity);
				
		float4 rimLight = _RimColor * mainLightColor * rimIntensity;
		
		// ambient occlusion map color sample
		float aoIntensity = floor(SAMPLE_TEXTURE2D(_AOTexture, sampler_AOTexture, vertInfo.uv).r * (_AOMapLevels - 1) + _AOBrightPreference) / (_AOMapLevels - 1);
		aoIntensity = min(1, smoothstep(_AOIntensityMin, _AOIntensityMax, aoIntensity) + _AOIntensityMin);

		float4 aoColor = surfaceDotLight > 0 ? (mainLightColor * aoIntensity + ambientLight) : float4(1, 1, 1, 1); // don't apply AO map to already shaded areas

		// sample the diffuse texture
		float4 diffuseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, vertInfo.uv) * _Color;

		if (_EnergyConservation > 0)
		{
			// monochromatic light energy conservation
			float specularMax = max(max(_SpecularColor.r, _SpecularColor.g), _SpecularColor.b);
			diffuseColor *= 1 - specularMax;			
		}

		// sample texture and apply shading
        float4 finalColor = diffuseColor * (worldspaceLight + ambientLight + specularLight + rimLight) * aoColor;

        return finalColor;
    }

#endif