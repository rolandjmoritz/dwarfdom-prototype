#ifndef OUTLINESSHADER
	#define OUTLINESSHADER

	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GlobalSamplers.hlsl"

#if SHADER_API_GLES
    struct Attributes
    {
        real4 positionOS       : POSITION;
        real2 uv               : TEXCOORD0;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };
#else
    struct Attributes
    {
        uint vertexID : SV_VertexID;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };
#endif

    struct VertexOutput
    {
        real4 positionCS : SV_POSITION;
        real3 positionWS : POSITIONT;
        real3 viewDirVS  : TEXCOORD1;
        real2 uv         : TEXCOORD0;
        UNITY_VERTEX_OUTPUT_STEREO
    };

    TEXTURE2D_X(_BlitTexture);
    TEXTURE2D_X(_NormalBuffer);
    TEXTURE2D_X(_CameraDepthTexture);
    TEXTURECUBE(_BlitCubeTexture);
    SAMPLER(sampler_BlitTexture);
    SAMPLER(sampler_NormalBuffer);
    SAMPLER(sampler_CameraDepthTexture);

    uniform float4 _BlitScaleBias;
    uniform float4 _BlitScaleBiasRt;
    uniform float _BlitMipLevel;
    uniform float2 _BlitTextureSize;
    uniform uint _BlitPaddingSize;
    uniform int _BlitTexArraySlice;
    uniform float4 _BlitDecodeInstructions;

    CBUFFER_START(UnityPerMaterial)
		real4 _BlitTexture_TexelSize;
        real4 _OutlineColor;
        real _OutlineScale;
        real _RobertsCrossMult;
        real _DepthThreshold;
        real _NormalThreshold;
        real _SteepAngleThreshold;
        real _SteepAngleMult;
	CBUFFER_END


    VertexOutput VertexProgram(Attributes attrInfo)
    {
        VertexOutput vertInfo;

        UNITY_SETUP_INSTANCE_ID(attrInfo);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(vertInfo);

        #if SHADER_API_GLES
            vertInfo.positionCS = TransformObjectToHClip(attrInfo.positionOS.xyz);
            vertInfo.positionWS = ComputeWorldSpacePosition(vertInfo.positionCS, UNITY_MATRIX_I_VP);
            vertInfo.uv = attrInfo.uv;
        #else
            vertInfo.positionCS = GetFullScreenTriangleVertexPosition(attrInfo.vertexID);
            vertInfo.positionWS = ComputeWorldSpacePosition(vertInfo.positionCS, UNITY_MATRIX_I_VP);
            vertInfo.uv = GetFullScreenTriangleTexCoord(attrInfo.vertexID);
        #endif

        vertInfo.uv = vertInfo.uv * _BlitScaleBias.xy + _BlitScaleBias.zw;
		if (IsPerspectiveProjection()) // perspective
		{
			vertInfo.viewDirVS = TransformWorldToView(GetCurrentViewPosition() - vertInfo.positionWS);
		}
		else // orthographic
		{
			vertInfo.viewDirVS = TransformWorldToView(-GetViewForwardDir());
		}

        return vertInfo;
    }

    real4 FragmentProgram(VertexOutput vertInfo) : SV_Target
    {
        _OutlineScale = 3;
        real2 uvTR = vertInfo.uv + _BlitTexture_TexelSize.xy * _OutlineScale;
        real2 uvBL = vertInfo.uv - _BlitTexture_TexelSize.xy * _OutlineScale;
        real2 uvTL = vertInfo.uv + real2(-_BlitTexture_TexelSize.x * _OutlineScale, _BlitTexture_TexelSize.y * _OutlineScale);
        real2 uvBR = vertInfo.uv + real2(_BlitTexture_TexelSize.x * _OutlineScale, -_BlitTexture_TexelSize.y * _OutlineScale);

        real4 depthOrig = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, vertInfo.uv).r;
        real4 depthSample1 = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, uvTR).r - SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, uvBL).r;
        real4 depthSample2 = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, uvTL).r - SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, uvBR).r;

        real4 normalOrig = SAMPLE_TEXTURE2D_X(_NormalBuffer, sampler_NormalBuffer, vertInfo.uv);
        real4 normalSample1 = SAMPLE_TEXTURE2D_X(_NormalBuffer, sampler_NormalBuffer, uvTR) - SAMPLE_TEXTURE2D_X(_NormalBuffer, sampler_NormalBuffer, uvBL);
        real4 normalSample2 = SAMPLE_TEXTURE2D_X(_NormalBuffer, sampler_NormalBuffer, uvTL) - SAMPLE_TEXTURE2D_X(_NormalBuffer, sampler_NormalBuffer, uvBR);

        _SteepAngleThreshold = 1;
        _SteepAngleMult = 1;
        vertInfo.viewDirVS = normalize(vertInfo.viewDirVS);
        real normalDotView = 1 - dot(normalOrig * 2 - 1, vertInfo.viewDirVS * -1);
        normalDotView = smoothstep(_SteepAngleThreshold, 2, normalDotView) * _SteepAngleMult + 1;

        

        _RobertsCrossMult = 1;
        _DepthThreshold = 0.2;
        _NormalThreshold = 0.4;
        real4 depthOutput = step(depthOrig * _DepthThreshold * normalDotView, sqrt(depthSample1 * depthSample1 + depthSample2 * depthSample2) * _RobertsCrossMult);
        real4 normalOutput = step(_NormalThreshold, sqrt(dot(normalSample1, normalSample1) + dot(normalSample2, normalSample2)) * _RobertsCrossMult);

        _OutlineColor = real4(0, 0, 0, 1);
        real4 fragOutput = max(depthOutput, normalOutput) * _OutlineColor;

        real4 texSample;
        #if defined(USE_TEXTURE2D_X_AS_ARRAY) && defined(BLIT_SINGLE_SLICE)
            texSample = SAMPLE_TEXTURE2D_ARRAY_LOD(_BlitTexture, sampler_BlitTexture, vertInfo.uv, _BlitTexArraySlice, _BlitMipLevel);
        #else
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(vertInfo);
            texSample = SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_BlitTexture, vertInfo.uv, _BlitMipLevel);
        #endif

        return fragOutput.a > 0.1 ? fragOutput : texSample;

    }

#endif