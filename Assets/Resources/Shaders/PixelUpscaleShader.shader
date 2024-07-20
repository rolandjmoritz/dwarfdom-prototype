Shader"Cure-All/Pixelart Upscaling"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite", 2D) = "white" {}
        [Enum(CureAllGame.UpscaleFactor)] _UpscaleFactor ("Upscale Factor", Integer) = 1
        _PixelScale ("Pixel Scale", Range(0, 1)) = 1
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

        Cull Off
        Lighting Off
        ZWrite Off
        Blend One OneMinusSrcAlpha

        Pass
        {
            HLSLPROGRAM
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram

            #include "PixelUpscaleShader.hlsl"

            ENDHLSL
        }
    }
}
