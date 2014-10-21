using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Windows;
using Gauss.GUI.Models;

namespace Gauss.GUI.Core
{
    public class GaussImageManager
    {
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
                throw;
            }
        }

        public Task GenerateBlurredImageAsync(ComputingProcessImageParameters processImageParameters)
        {
            MessageBox.Show(processImageParameters.ToString());
        }
    }
}