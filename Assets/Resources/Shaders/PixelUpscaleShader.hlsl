#ifndef SPRITESCALER2X
    #define SPRITESCALER2X

	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GlobalSamplers.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    struct Attributes
    {
        float4 position : POSITION;
        float2 uv : TEXCOORD0;
    };

    struct VertexOutput
    {
        float4 position : SV_POSITION;
        float2 uv : TEXCOORD0;
    };

    TEXTURE2D(_MainTex);
	SAMPLER(sampler_MainTex);

    CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float4 _MainTex_TexelSize;
        half _PixelScale;
		int _UpscaleFactor;
	CBUFFER_END
    
    float ColorDistance(half4 col1, half4 col2)
    {
        return col1 == col2 ? 0 : abs(col1.r - col2.r) + abs(col1.g - col2.g) + abs(col1.b - col2.b);
    }

    bool IsSimilar(half4 col1, half4 col2, half4 inputCol)
    {
        float colorDistance = ColorDistance(col1, col2);
        return col1 == col2 || (colorDistance <= ColorDistance(inputCol, col2) && colorDistance <= ColorDistance(inputCol, col1));
    }

    VertexOutput VertexProgram(Attributes attrInfo)
    {
        VertexOutput vertInfo;

        vertInfo.position = TransformObjectToHClip(attrInfo.position);
        vertInfo.uv = TRANSFORM_TEX(attrInfo.uv, _MainTex);

        return vertInfo;
    }
   
    // RotSprite 3x Enlargement Algorithm:
    // Looking at input pixel cE which is surrounded by 8 other pixels:
    //  cA cB cC
    //  cD cE cF
    //  cG cH cI
    // For input pixel cE we want to output 8 extra pixels (3x):
    //  E0 E1 E2
    //  E3 cE E5
    //  E6 E7 E8
	// For input pixel cE we want to output 4 new pixels (2x):
    //  E0 E1
    //  E2 E3
    half4 FragmentProgram(VertexOutput vertInfo) : SV_Target
    {
		const half2 pixelSize = _MainTex_TexelSize.xy * _PixelScale;
        const half4 cBackground = half4(1, 1, 1, 0);
	    half4 cE = SAMPLE_TEXTURE2D(_MainTex, sampler_PointClamp, vertInfo.uv);    cE = cE.a == 0.0 ? cBackground : cE;
	
	    half4 cA = SAMPLE_TEXTURE2D(_MainTex, sampler_PointClamp, vertInfo.uv + pixelSize * half2(-1, -1));   cA = cA.a == 0.0 ? cBackground : cA;
	    half4 cB = SAMPLE_TEXTURE2D(_MainTex, sampler_PointClamp, vertInfo.uv + pixelSize * half2(0,  -1));   cB = cB.a == 0.0 ? cBackground : cB;
	    half4 cC = SAMPLE_TEXTURE2D(_MainTex, sampler_PointClamp, vertInfo.uv + pixelSize * half2(1,  -1));   cC = cC.a == 0.0 ? cBackground : cC;
	    half4 cD = SAMPLE_TEXTURE2D(_MainTex, sampler_PointClamp, vertInfo.uv + pixelSize * half2(-1,  0));   cD = cD.a == 0.0 ? cBackground : cD;
	    half4 cF = SAMPLE_TEXTURE2D(_MainTex, sampler_PointClamp, vertInfo.uv + pixelSize * half2(1,	0));   cF = cF.a == 0.0 ? cBackground : cF;
	    half4 cG = SAMPLE_TEXTURE2D(_MainTex, sampler_PointClamp, vertInfo.uv + pixelSize * half2(-1,	1));   cG = cG.a == 0.0 ? cBackground : cG;
	    half4 cH = SAMPLE_TEXTURE2D(_MainTex, sampler_PointClamp, vertInfo.uv + pixelSize * half2(0,	1));   cH = cH.a == 0.0 ? cBackground : cH;
	    half4 cI = SAMPLE_TEXTURE2D(_MainTex, sampler_PointClamp, vertInfo.uv + pixelSize * half2(1,	1));   cI = cI.a == 0.0 ? cBackground : cI;
	
        half4 finalColor;
	    if (!IsSimilar(cD, cF, cE) && !IsSimilar(cH, cB, cE) &&
         (
			(
				IsSimilar(cE, cD, cE) || IsSimilar(cE, cH, cE) || IsSimilar(cE, cF, cE) || IsSimilar(cE, cB, cE) ||
				(
					(
						!IsSimilar(cA, cI, cE) || IsSimilar(cE, cG, cE) || IsSimilar(cE, cC, cE)
					)
					&&
					(
						!IsSimilar(cG, cC, cE) || IsSimilar(cE, cA, cE) || IsSimilar(cE, cI, cE)
					)
				)
			)
		 )
		)
        {
			half2 pixelUnit = vertInfo.uv - (floor(vertInfo.uv / pixelSize) * pixelSize);
			if (_UpscaleFactor > 0) // 3X Upscale
			{
				half2 pixelThirdSize = pixelSize / 3.0;
				if (pixelUnit.x < pixelThirdSize.x && pixelUnit.y < pixelThirdSize.y) // E0
				{
					finalColor = IsSimilar(cB, cD, cE) ? cB : cE;
				}
				else if (pixelUnit.x < pixelThirdSize.x * 2.0 && pixelUnit.y < pixelThirdSize.y) // E1
				{
					finalColor = (IsSimilar(cB, cD, cE) && !IsSimilar(cE, cC, cE)) || (IsSimilar(cB, cF, cE) && !IsSimilar(cE, cA, cE)) ? cB : cE;
				}
				else if (pixelUnit.y < pixelThirdSize.y) // E2
				{
					finalColor = IsSimilar(cB, cF, cE) ? cB : cE;
				}
				else if (pixelUnit.x < pixelThirdSize.x && pixelUnit.y < pixelThirdSize.y * 2.0) // E3
				{
					finalColor = (IsSimilar(cB, cD, cE) && !IsSimilar(cE, cG, cE) || (IsSimilar(cH, cD, cE) && !IsSimilar(cE, cA, cE))) ? cD : cE;
				}
				else if (pixelUnit.x >= pixelThirdSize.x * 2.0 && pixelUnit.x < pixelThirdSize.x * 3.0 && pixelUnit.y < pixelThirdSize.y * 2.0) // E5
				{
					finalColor = (IsSimilar(cB, cF, cE) && !IsSimilar(cE, cI, cE)) || (IsSimilar(cH, cF, cE) && !IsSimilar(cE, cC, cE)) ? cF : cE;
				}
				else if (pixelUnit.x < pixelThirdSize.x && pixelUnit.y >= pixelThirdSize.y * 2.0) // E6
				{
					finalColor = IsSimilar(cH, cD, cE) ? cH : cE;
				}
				else if (pixelUnit.x < pixelThirdSize.x * 2.0 && pixelUnit.y >= pixelThirdSize.y * 2.0) // E7
				{
					finalColor = (IsSimilar(cH, cD, cE) && !IsSimilar(cE, cI, cE)) || (IsSimilar(cH, cF, cE) && !IsSimilar(cE, cG, cE)) ? cH : cE;
				}
				else if (pixelUnit.y >= pixelThirdSize.y * 2.0) // E8
				{
					finalColor = IsSimilar(cH, cF, cE) ? cH : cE;
				}
			}
			else // 2X Upscale
			{
				half2 pixelHalfSize = pixelSize / 2.0;
				if (pixelUnit.x < pixelHalfSize.x && pixelUnit.y < pixelHalfSize.y) // E1
				{
					finalColor = (IsSimilar(cB, cD, cE) && ((!IsSimilar(cE, cA, cE) || !IsSimilar(cB, cBackground, cE)) && (!IsSimilar(cE, cA, cE) || !IsSimilar(cE, cI, cE) || !IsSimilar(cB, cC, cE) || !IsSimilar(cD, cG, cE)))) ? cB : cE;
				}
				else if (pixelUnit.x >= pixelHalfSize.x && pixelUnit.y < pixelHalfSize.y) // E2
				{
					finalColor = (IsSimilar(cF, cB, cE) && ((!IsSimilar(cE, cC, cE) || !IsSimilar(cF, cBackground, cE)) && (!IsSimilar(cE, cC, cE) || !IsSimilar(cE, cG, cE) || !IsSimilar(cF, cI, cE) || !IsSimilar(cB, cA, cE)))) ? cF : cE;
				}
				else if (pixelUnit.x < pixelHalfSize.x && pixelUnit.y >= pixelHalfSize.y) // E3
				{
					finalColor = (IsSimilar(cD, cH, cE) && ((!IsSimilar(cE, cG, cE) || !IsSimilar(cD, cBackground, cE)) && (!IsSimilar(cE, cG, cE) || !IsSimilar(cE, cC, cE) || !IsSimilar(cD, cA, cE) || !IsSimilar(cH, cI, cE)))) ? cD : cE;
				}
				else // E4
				{
					finalColor = (IsSimilar(cH, cF, cE) && ((!IsSimilar(cE, cI, cE) || !IsSimilar(cH, cBackground, cE)) && (!IsSimilar(cE, cI, cE) || !IsSimilar(cE, cA, cE) || !IsSimilar(cH, cG, cE) || !IsSimilar(cF, cC, cE)))) ? cH : cE;			
				}
			}	
		}
		else
		{
			finalColor = cE;
		}

		clip(finalColor.a - 0.1);
		return finalColor;
	}
#endif