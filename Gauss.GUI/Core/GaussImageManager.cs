using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using System.Windows;
using Gauss.GUI.Models;
using Gauss.GUI.Models.RunParameters;

namespace Gauss.GUI.Core
{
    public class GaussImageManager
    {
        #region DLL Imports

        [DllImport("Gauss.ASM.dll", EntryPoint = "ComputeGaussBlur")]
        private static extern unsafe byte* ComputeGaussBlurAsm(byte* imgArr, int blurLevel, int imgWidth, int imgHeight);

        [DllImport("Gauss.CPP.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint = "ComputeGaussBlur")]
        private static extern unsafe byte* ComputeGaussBlurCpp(byte* imgArr, int blurLevel, int imgWidth, int imgHeight);

        private int w, h;

        #endregion

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

        public async Task<byte[]> GenerateBlurredImageAsync(GeneratorParameters generatorParams)
        {
            var tasks = new Task[generatorParams.NumberOfThreads];
            var imgSizes = GetLoadedImageSizes();

            for (int threadNum = 0; threadNum < tasks.Length; threadNum++)
            {
                int num = threadNum;
                tasks[threadNum] = Task.Run(() =>
                {
                    var currentThreadParams = ComputeThreadParams(
                        threadNum: num, 
                        generatorParams: generatorParams,
                        imageSizes: imgSizes);

                    RunUnsafeImageGenerationCode(currentThreadParams);
                });
            }

            await Task.WhenAll(tasks);
            return SourceFile;
        }

        private unsafe Size<int> GetLoadedImageSizes()
        {
            int width, height;

            fixed (byte* imgArray = SourceFile)
            {
                width =  *(int*)&imgArray[18];
                height = *(int*)&imgArray[22];
            }

            return new Size<int>(width, height);
        }

        private ThreadParameters ComputeThreadParams(int threadNum, GeneratorParameters generatorParams, Size<int> imageSizes)
        {
            return new ThreadParameters
            {
                ThreadNumber = threadNum,
                GeneratorParameters = generatorParams,
                ImageSizes = imageSizes,
            };
        }

        private unsafe void RunUnsafeImageGenerationCode(ThreadParameters currentThreadParams)
        {
            fixed (byte* imgArray = SourceFile)
            {
                ComputeGaussBlurCpp(imgArray, 100, SourceFile.Length, 0);
            }
        }
    }
}