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
        private static extern void ComputeGaussBlurAsm(ThreadParameters threadParameters);

        [DllImport("Gauss.CPP.dll", CallingConvention = CallingConvention.Cdecl, EntryPoint = "ComputeGaussBlur")]
        private static extern void ComputeGaussBlurCpp(ThreadParameters threadParameters);

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

                    RunUnsafeImageGenerationCode(currentThreadParams, generatorParams.GeneratingLibrary);
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
            //var imagePartArrayPtr = 

            return new ThreadParameters
            {
                GaussMaskSize   = generatorParams.GaussMaskSize,
                BlurLevel       = generatorParams.BlurLevel,
                ImgWidth        = imageSizes.Width,
                ImgHeight       = imageSizes.Height,
                IdOfImgPart     = threadNum,
                NumOfImgParts   = generatorParams.NumberOfThreads,
            };
        }

        private unsafe void RunUnsafeImageGenerationCode(ThreadParameters currentThreadParams, GeneratingLibrary genLibrary)
        {
            fixed (byte* imgArray = SourceFile)
            {
                currentThreadParams.ImgByteArrayPtr = (uint*)imgArray;

                switch (genLibrary)
                {
                    case GeneratingLibrary.ASM:
                        ComputeGaussBlurAsm(currentThreadParams);
                        break;
                    case GeneratingLibrary.CPP:
                        ComputeGaussBlurCpp(currentThreadParams);
                        break;
                    default: throw new NotImplementedException();
                }
            }
        }
    }
}