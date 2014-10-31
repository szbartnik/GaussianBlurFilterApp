using System.Runtime.InteropServices;

namespace Gauss.GUI.Models.RunParameters
{
    [StructLayout(LayoutKind.Sequential)]
    public struct ThreadParameters
    {
        public int GaussMaskSize;
        public int CurrentImgOffset;
        public int BlurLevel;
        public int ImgWidth;
        public int ImgHeight;
        public int IdOfImgPart;
        public int NumOfImgParts;
        public unsafe uint* ImgByteArrayPtr;

        public override string ToString()
        {
            return string.Format("ThreadID: {0}; Width: {1}; Height: {2}; NumOfParts: {3}; ThreadOffset: {4}", IdOfImgPart, ImgWidth, ImgHeight, NumOfImgParts, CurrentImgOffset);
        }
    }
}