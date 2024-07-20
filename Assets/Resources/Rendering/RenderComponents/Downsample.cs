using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace CureAllGame
{
    [Serializable]
    [VolumeComponentMenuForRenderPipeline("Cure-All/Downsample", typeof(UniversalRenderPipeline))]
    public class Downsample : VolumeComponent, IPostProcessComponent
    {
        // Shader variables go here.
        [Header("Pixelization Settings")]
        public ClampedIntParameter m_DownscaleFactor = new(0, 0, 8, true);

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