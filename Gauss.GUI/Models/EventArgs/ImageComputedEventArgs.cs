using System;

namespace Gauss.GUI.Core
{
    public class ImageComputedEventArgs : EventArgs
    {
        public TimeSpan ComputationTime { get; private set; }
        public byte[] ResultImage { get; private set; }

        public ImageComputedEventArgs(TimeSpan computationTime, byte[] resultImage)
        {
            ComputationTime = computationTime;
            ResultImage = resultImage;
        }
    }
}