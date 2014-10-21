#pragma once
#define API extern "C" __declspec(dllexport)

#define NUM_OF_LETTERS_IN_PATTERN 26

typedef struct Pixel {
	unsigned char B;
	unsigned char G;
	unsigned char R;
} Pixel;

API unsigned char* ComputeGaussBlurCpp(unsigned char* imgArr, int blurLevel, int imgWidth, int imgHeight);
