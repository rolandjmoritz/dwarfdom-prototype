#ifndef PIXELIZER
    #define PIXELIZER

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GlobalSamplers.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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
        float4 positionCS : SV_POSITION;
        float2 uv         : TEXCOORD0;
        UNITY_VERTEX_OUTPUT_STEREO
    };


    TEXTURE2D_X(_BlitTexture);
    TEXTURECUBE(_BlitCubeTexture);
    SAMPLER(sampler_BlitTexture);

    uniform float4 _BlitScaleBias;
    uniform float4 _BlitScaleBiasRt;
    uniform float _BlitMipLevel;
    uniform float2 _BlitTextureSize;
    uniform uint _BlitPaddingSize;
    uniform int _BlitTexArraySlice;
    uniform float4 _BlitDecodeInstructions;

    VertexOutput VertexProgram(Attributes attrInfo)
    {
        VertexOutput vertInfo;

        UNITY_SETUP_INSTANCE_ID(attrInfo);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(vertInfo);

        #if SHADER_API_GLES
            vertInfo.positionCS = TransformObjectToHClip(attrInfo.positionOS.xyz);
            vertInfo.uv = attrInfo.uv;
        #else
            vertInfo.positionCS = GetFullScreenTriangleVertexPosition(attrInfo.vertexID);
            vertInfo.uv = GetFullScreenTriangleTexCoord(attrInfo.vertexID);
        #endif

        vertInfo.uv = vertInfo.uv * _BlitScaleBias.xy + _BlitScaleBias.zw;

        return vertInfo;
    }

    real4 FragmentProgram(VertexOutput vertInfo) : SV_Target
    {
        #if defined(USE_TEXTURE2D_X_AS_ARRAY) && defined(BLIT_SINGLE_SLICE)
            return SAMPLE_TEXTURE2D_ARRAY_LOD(_BlitTexture, sampler_BlitTexture, vertInfo.uv, _BlitTexArraySlice, _BlitMipLevel);
        #else
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(vertInfo);
            return SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_BlitTexture, vertInfo.uv, _BlitMipLevel);
        #endif
    }
#endif