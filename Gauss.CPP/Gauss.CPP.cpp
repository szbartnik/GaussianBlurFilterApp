#include "stdafx.h"
#include "Gauss.CPP.h"

BYTE* AllocateArray(int size)
{
	BYTE* toReturn = new BYTE[size];
	return toReturn;
}

int* ComputePascalRow(int n)
{
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

	// Compute difference between row_padded and real rowWidth
	int row_padded_diff = row_padded - params.ImageWidth * 3;

	int gaussHalf = params.GaussMaskSize / 2;

	BYTE* temp = AllocateArray(row_padded * params.ImageHeight);

	const int gauss_w = params.GaussMaskSize; // must be odd

	int* mask = ComputePascalRow(gauss_w - 1);

	// Compute gauss mask sum
	int gauss_sum = 0;
	for (int i = 0; i < gauss_w; i++){
		gauss_sum += mask[i];
	}

	int currPos = 0;
	int maxY = params.ImageHeight - gauss_w + 1;
	BYTE* imgOffset = &params.ImgByteArrayPtr[params.CurrentImgOffset];

	// Vertical iteration
	for (int y = 0; y < params.ImageHeight; y++)
	{
		int currY = y - gaussHalf;
		BYTE* offset1 = imgOffset + row_padded * currY;

		if (currY >= 0 && currY < maxY)
		{
			for (int x = 0; x < params.ImageWidth; x++)
			{
				BYTE* offset2 = offset1 + x * 3;

				double linc_b = 0;
				double linc_g = 0;
				double linc_r = 0;

				for (int k = 0; k < gauss_w; k++)
				{
					linc_b += offset2[0] * mask[k];
					linc_g += offset2[1] * mask[k];
					linc_r += offset2[2] * mask[k];

					offset2 += row_padded;
				}
				
				temp[currPos++] = linc_b / gauss_sum;
				temp[currPos++] = linc_g / gauss_sum;
				temp[currPos++] = linc_r / gauss_sum;
			}
		}
		else
		{
			BYTE* offset2 = offset1 + gaussHalf * row_padded;

			for (int x = 0; x < params.ImageWidth; x++)
			{
				temp[currPos++] = offset2[0];
				temp[currPos++] = offset2[1];
				temp[currPos++] = offset2[2];

				offset2 += 3;
			}
		}

		currPos += row_padded_diff;
	}

	currPos = 0;
	int maxX = params.ImageWidth - gauss_w + 1;

	int beginCopy = 0;
	int endCopy = params.ImageHeight;

	if (params.IdOfImgPart != 0)
	{
		beginCopy = gaussHalf;
		imgOffset += row_padded * gaussHalf;
	}
	if (params.IdOfImgPart != params.NumOfImgParts - 1)
		endCopy -= gaussHalf;

	// Horizontal iteration
	for (int y = beginCopy; y<endCopy; y++)
	{
		BYTE* offset1 = temp + row_padded * y - gaussHalf * 3;

		for (int x = 0; x < params.ImageWidth; x++)
		{
			double linc_b = 0;
			double linc_g = 0;
			double linc_r = 0;

			int currX = x - gaussHalf;
			BYTE* offset2 = offset1 + x * 3;

			if (currX >= 0 && currX < maxX)
			{

				for (int k = 0; k < gauss_w; k++)
				{

					linc_b += offset2[0] * mask[k];
					linc_g += offset2[1] * mask[k];
					linc_r += offset2[2] * mask[k];

					offset2 += 3;
				}

				imgOffset[currPos++] = linc_b / gauss_sum;
				imgOffset[currPos++] = linc_g / gauss_sum;
				imgOffset[currPos++] = linc_r / gauss_sum;
			}
			else
			{
				offset2 += gaussHalf * 3;
				imgOffset[currPos++] = offset2[0];
				imgOffset[currPos++] = offset2[1];
				imgOffset[currPos++] = offset2[2];
			}
		}

		currPos += row_padded_diff;
	}

	delete[] temp;
}