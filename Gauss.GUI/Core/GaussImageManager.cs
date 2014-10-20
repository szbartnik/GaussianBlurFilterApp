using System.Windows;
using Gauss.GUI.Models;

namespace Gauss.GUI.Core
{
    public class GaussImageManager
    {
        public GaussImageManager(string[] filenames)
        {
            
        }

        public void GenerateBlurredImage(ComputingProcessImageParameters computeImageParameters)
        {
            MessageBox.Show(computeImageParameters.ToString());
        }
    }
}