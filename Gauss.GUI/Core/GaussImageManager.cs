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
                        threadId: num, 
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
                width  = *(int*)&imgArray[18];
                height = *(int*)&imgArray[22];
            }

            return new Size<int>(width, height);
        }

        private ThreadParameters ComputeThreadParams(int threadId, GeneratorParameters generatorParams, Size<int> imageSizes)
        {
            int rowPadded = (imageSizes.Width * 3 + 3) & (~3);
            int currentThreadImgHeight = 0;
            int sumOfOffsetLines = 0;


            for (int i = 0; i <= threadId; i++) 
            {
                var numOfLinesOfCurrentThread = ComputeNumberOfLinesPerThread(
                    threadId:      i,
                    numOfThreads:  generatorParams.NumberOfThreads,
                    gaussMaskSize: generatorParams.GaussMaskSize,
                    imgHeight:     imageSizes.Height);

                if (i == threadId)
                    currentThreadImgHeight = numOfLinesOfCurrentThread;
                else
                    sumOfOffsetLines += numOfLinesOfCurrentThread;
            }

            sumOfOffsetLines -= threadId*(generatorParams.GaussMaskSize - 1);

            return new ThreadParameters
            {
                CurrentImgOffset = sumOfOffsetLines * rowPadded,
                GaussMaskSize    = generatorParams.GaussMaskSize,
                BlurLevel        = generatorParams.BlurLevel,
                ImgWidth         = imageSizes.Width,
                ImgHeight        = currentThreadImgHeight,
                IdOfImgPart      = threadId,
                NumOfImgParts    = generatorParams.NumberOfThreads,
            };
        }

        private int ComputeNumberOfLinesPerThread(int threadId, int numOfThreads, int gaussMaskSize, int imgHeight)
        {
            var numOfLinesPerThread = imgHeight / numOfThreads;

            if (numOfThreads > 1)
            {
                if ((threadId == 0 || threadId == (numOfThreads - 1)))
                    numOfLinesPerThread += gaussMaskSize / 2;
                else
                    numOfLinesPerThread += gaussMaskSize - 1;
            }

            return numOfLinesPerThread;
        }

        private unsafe void RunUnsafeImageGenerationCode(ThreadParameters currentThreadParams, GeneratingLibrary genLibrary)
        {
            fixed (byte* imgArray = SourceFile)
            {
                currentThreadParams.ImgByteArrayPtr = (uint*)(&imgArray[54]);

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