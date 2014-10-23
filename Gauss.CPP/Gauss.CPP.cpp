#include "stdafx.h"
#include "Gauss.CPP.h"

Pixel** CopyPixels(Pixel** pixels, int height, int width)
{
	Pixel** toReturn = new Pixel*[height];

	for (int y = 0; y < height; y++)
	{
		toReturn[y] = new Pixel[width];
		for (int x = 0; x < width; x++)
		{
			toReturn[y][x] = pixels[y][x];
		}
	}
	return toReturn;
}

int* ComputePascalRow(int n){
	int* row = new int[n + 1];
	row[0] = 1; //First element is always 1
	for (int i = 1; i<n / 2 + 1; i++){ //Progress up, until reaching the middle value
		row[i] = row[i - 1] * (n - i + 1) / i;
	}
	for (int i = n / 2 + 1; i <= n; i++){ //Copy the inverse of the first part
		row[i] = row[n - i];
	}
	return row;
}

void ComputeGaussBlur(ThreadParameters params)
{
	int row_padded = (params.ImageWidth * 3 + 3) & (~3);

	Pixel** pixels = new Pixel*[params.ImageHeight];

	unsigned char* tmp = new unsigned char[row_padded];
	for (int y = 0; y < params.ImageHeight; y++)
	{
		memcpy(tmp, &params.ImgByteArrayPtr[params.CurrentImgOffset + y * row_padded], sizeof(unsigned char) * row_padded);
		pixels[y] = new Pixel[params.ImageWidth];

		for (int x = 0; x < params.ImageWidth; x++)
		{
			Pixel pixel;
			pixel.B = tmp[x * 3];
			pixel.G = tmp[x * 3 + 1];
			pixel.R = tmp[x * 3 + 2];

			pixels[y][x] = pixel;
		}
	}

	delete[] tmp;

	Pixel** temp = CopyPixels(pixels, params.ImageHeight, params.ImageWidth);
	Pixel color;

	double linc_r, linc_g, linc_b;

	const int gauss_w = 25; // must be odd
	int gauss_sum = 0;

	int* mask = ComputePascalRow(gauss_w - 1);
	for (int i = 0; i < gauss_w; i++){
		gauss_sum += mask[i];
	}

	//For every pixel on the temporary bitmap ...
	for (int i = gauss_w - 1; i<params.ImageHeight; i++)
	{
		for (int j = 0; j<params.ImageWidth; j++)
		{
			linc_r = 0;
			linc_g = 0;
			linc_b = 0;

			for (int k = 0; k<gauss_w; k++)
			{
				color = pixels[i - (gauss_w - 1) + k][j];
				linc_r += color.R * mask[k];
				linc_g += color.G * mask[k];
				linc_b += color.B * mask[k];
			}

			Pixel toSave;
			toSave.R = linc_r / gauss_sum;
			toSave.G = linc_g / gauss_sum;
			toSave.B = linc_b / gauss_sum;

			temp[i][j] = toSave;
		}
	}

	//For every pixel on the output bitmap ...
	for (int i = 0; i<params.ImageHeight; i++)
	{
		for (int j = gauss_w - 1; j<params.ImageWidth; j++)
		{
			linc_r = 0;
			linc_g = 0;
			linc_b = 0;

			for (int k = 0; k<gauss_w; k++)
			{
				color = temp[i][j - (gauss_w - 1) + k];
				linc_r += color.R * mask[k];
				linc_g += color.G * mask[k];
				linc_b += color.B * mask[k];
			}

			Pixel toSave;
			toSave.R = linc_r / gauss_sum;
			toSave.G = linc_g / gauss_sum;
			toSave.B = linc_b / gauss_sum;

			pixels[i][j] = toSave;
		}
	}

	delete[] mask;

	for (int y = 0; y < params.ImageHeight; y++)
		memcpy(&params.ImgByteArrayPtr[params.CurrentImgOffset + y * row_padded], pixels[y], sizeof(unsigned char) * 3 * params.ImageWidth);
}