using System.Runtime.InteropServices;

namespace Gauss.GUI.Models.RunParameters
{
    [StructLayout(LayoutKind.Sequential)]
    public struct ThreadParameters
    {
        public unsafe uint* ImgByteArrayPtr;
        public int CurrentImgOffset;
        public int GaussMaskSize;
        public int BlurLevel;
        public int ImgWidth;
        public int ImgHeight;
        public int IdOfImgPart;
        public int NumOfImgParts;
    }
}