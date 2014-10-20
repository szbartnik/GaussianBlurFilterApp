using System;

namespace Gauss.GUI.Models
{
    public class ComputingProcessImageParameters
    {
        public int NumberOfThreads { get; set; }
        public int BlurLevel { get; set; }
        public GeneratingLibrary GeneratingLibrary { get; set; }

        public override string ToString()
        {
            return String.Format("NumOfThreads: {0}, BlurLvl: {1}, GenLib: {2}", NumberOfThreads, BlurLevel, GeneratingLibrary);
        }
    }
}