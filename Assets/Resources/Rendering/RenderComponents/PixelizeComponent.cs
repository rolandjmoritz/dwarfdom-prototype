using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace CureAllGame
{
    [Serializable]
    [VolumeComponentMenuForRenderPipeline("Cure-All/Pixelize", typeof(UniversalRenderPipeline))]
    public class PixelizeComponent : VolumeComponent, IPostProcessComponent
    {
        [Header("Pixelization Settings")]
        public ClampedIntParameter m_DownscaleFactor = new(0, 0, 8, true);

        [Header("Dithering Settings")]
        public ClampedFloatParameter m_Spread = new(0.5f, 0, 1, true);
        [Space]
        public ClampedIntParameter m_BayerLevel = new(0, 0, 2, true);

        [Header("Color Quantization")]
        [Space]
        public ClampedIntParameter m_RedColorCount = new(2, 2, 256, true);
        public ClampedIntParameter m_GreenColorCount = new(2, 2, 256, true);
        public ClampedIntParameter m_BlueColorCount = new(2, 2, 256, true);

        public bool IsActive()
        {
            return true;
        }

        public bool IsTileCompatible()
        {
            return true;
        }
    }

}