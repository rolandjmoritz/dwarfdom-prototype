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


    TEXTURE2D_X(_FilterBuffer);
    TEXTURE2D_X(_BlitTexture);
    TEXTURECUBE(_BlitCubeTexture);
    SAMPLER(sampler_FilterBuffer);
    SAMPLER(sampler_BlitTexture);

    uniform float4 _BlitScaleBias;
    uniform float4 _BlitScaleBiasRt;
    uniform float _BlitMipLevel;
    uniform float2 _BlitTextureSize;
    uniform uint _BlitPaddingSize;
    uniform int _BlitTexArraySlice;
    uniform float4 _BlitDecodeInstructions;

    CBUFFER_START(UnityPerMaterial)
        real4 _BlitTexture_ST;
        real4 _BlitTexture_TexelSize;
        real _Spread;
        int _RedColorCount, _GreenColorCount, _BlueColorCount , _BayerLevel;
    CBUFFER_END

    static const uint _Bayer2[2 * 2] =
    {
        0, 2,
        3, 1
    };

    static const uint _Bayer4[4 * 4] =
    {
        0, 8, 2, 10,
        12, 4, 14, 6,
        3, 11, 1, 9,
        15, 7, 13, 5
    };

    static const uint _Bayer8[8 * 8] =
    {
        0, 32, 8, 40, 2, 34, 10, 42,
        48, 16, 56, 24, 50, 18, 58, 26,  
        12, 44,  4, 36, 14, 46,  6, 38, 
        60, 28, 52, 20, 62, 30, 54, 22,  
        3, 35, 11, 43,  1, 33,  9, 41,  
        51, 19, 59, 27, 49, 17, 57, 25, 
        15, 47,  7, 39, 13, 45,  5, 37, 
        63, 31, 55, 23, 61, 29, 53, 21
    };

    real GetBayer2(uint x, uint y)
    {
        return real(_Bayer2[(x % (uint)2) + (y % (uint)2) * 2]) * (1.0f / 4.0f) - 0.5f;
    }

    real GetBayer4(uint x, uint y)
    {
        return real(_Bayer4[(x % (uint)4) + (y % (uint)4) * 4]) * (1.0f / 16.0f) - 0.5f;
    }

    real GetBayer8(uint x, uint y)
    {
        return real(_Bayer8[(x % (uint)8) + (y % (uint)8) * 8]) * (1.0f / 64.0f) - 0.5f;
    }

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
        real4 filterColor = SAMPLE_TEXTURE2D_X(_FilterBuffer, sampler_FilterBuffer, vertInfo.uv);
        if (filterColor.r < 0.1 && filterColor.g < 0.1 && filterColor.b < 0.1)
        {
            clip(-1);
            return (0, 0, 0, 0);
        }

        #if defined(USE_TEXTURE2D_X_AS_ARRAY) && defined(BLIT_SINGLE_SLICE)
            real4 col = SAMPLE_TEXTURE2D_ARRAY_LOD(_BlitTexture, sampler_BlitTexture, vertInfo.uv, _BlitTexArraySlice, _BlitMipLevel);
        #else
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(vertInfo);
            real4 col = SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_BlitTexture, vertInfo.uv, _BlitMipLevel);
        #endif

        uint x = vertInfo.uv.x * _BlitTexture_TexelSize.z;
        uint y = vertInfo.uv.y * _BlitTexture_TexelSize.w;
        real bayerValues[3] =
        {
            GetBayer2(x, y),
            GetBayer4(x, y),
            GetBayer8(x, y)
        };

        real4 output = col + _Spread * bayerValues[_BayerLevel];

        output.r = floor((_RedColorCount - 1.0f) * output.r + 0.5) / (_RedColorCount - 1.0f);
        output.g = floor((_GreenColorCount - 1.0f) * output.g + 0.5) / (_GreenColorCount - 1.0f);
        output.b = floor((_BlueColorCount - 1.0f) * output.b + 0.5) / (_BlueColorCount - 1.0f);

        return output;
    }
#endif