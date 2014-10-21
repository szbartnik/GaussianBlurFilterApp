using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using System.Windows;
using Gauss.GUI.Models;

namespace Gauss.GUI.Core
{
    public class GaussImageManager
    {
        #region DLL Imports

        [DllImport("Gauss.ASM.dll")]
        private static extern unsafe byte* ComputeGaussBlurAsm(byte* imgArr, int blurLevel, int imgWidth, int imgHeight);

        [DllImport("Gauss.CPP.dll", CallingConvention = CallingConvention.Cdecl)]
        private static extern unsafe byte* ComputeGaussBlurCpp(byte* imgArr, int blurLevel, int imgWidth, int imgHeight);

        #endregion

        public delegate void ImageComputedEventHandler(ImageComputedEventArgs e);
        public event ImageComputedEventHandler ImageComputed;

        private byte[] SourceFile { get; set; }

        public GaussImageManager(IEnumerable<string> filenames)
        {
            try
            {
                SourceFile = File.ReadAllBytes(filenames.First());
            }
            catch (Exception e)
            {
                MessageBox.Show(e.Message);
            }
        }

        public unsafe void GenerateBlurredImageAsync(ComputingProcessImageParameters processImageParameters)
        {
            fixed (byte* imgArray = SourceFile)
            {
                var result = ComputeGaussBlurCpp(imgArray, 100, SourceFile.Length, 0);
                for (int i = 0; i < SourceFile.Length; i++)
                    SourceFile[i] = result[i];
            }

            if (ImageComputed != null)
            {
                ImageComputed(new ImageComputedEventArgs(TimeSpan.Zero, SourceFile));
            }

            MessageBox.Show(processImageParameters.ToString());
        }
    }
}