#pragma once
#define API extern "C" __declspec(dllexport)

typedef struct Pixel {
	unsigned char B;
	unsigned char G;
	unsigned char R;
} Pixel;

struct ThreadParameters
{
	int GaussMaskSize;
	int CurrentImgOffset;
	int BlurLevel;
	int ImageWidth;
	int ImageHeight;
	int IdOfImgPart;
	int NumOfImgParts;
	unsigned char* ImgByteArrayPtr;
	unsigned char* TempImgByteArrayPtr;
};

API void ComputeGaussBlur(ThreadParameters threadParameters);
