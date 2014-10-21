#pragma once
#define API extern "C" __declspec(dllexport)

typedef struct Pixel {
	unsigned char B;
	unsigned char G;
	unsigned char R;
} Pixel;

API unsigned char* ComputeGaussBlurCpp(unsigned char* imgArr, int blurLevel, int imgWidth, int imgHeight);
