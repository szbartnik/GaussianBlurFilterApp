#pragma once
#define API extern "C" __declspec(dllexport)

typedef struct Pixel {
	unsigned char B;
	unsigned char G;
	unsigned char R;
} Pixel;

struct ThreadParameters
{
	unsigned char* ImgByteArrayPtr;
	int CurrentImgOffset;
	int GaussMaskSize;
	int BlurLevel;
	int ImageWidth;
	int ImageHeight;
	int IdOfImgPart;
	int NumOfImgParts;
};

API void ComputeGaussBlur(ThreadParameters threadParameters);
