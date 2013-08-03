/*
 
 QuickLook plugin for (iOS) PNG images
 Copyright (C) 2008  atPurpose
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>
 
 */

#include <fcntl.h>
#include <sys/stat.h>
#include <arpa/inet.h>
#include <zlib.h>

#include "UncrushPng.h"

#define DEBUG_DUMP_IMAGE		0

#define SWAP_R_AND_B			1
#define MAX_PATH_LENGTH			2048
#define MIN_IMAGE_BUFFER_SIZE	2048*2048*4 // iphone's current max texture size is 1024x1024

static UInt8 PngHeader[8] = {137, 80, 78, 71, 13, 10, 26, 10};

static UInt8 swapRandBiCPP[] = {0x00,0x00,0x01,0xCD,0x69,0x43,0x43,0x50,0x53,0x77,0x61,0x70,0x70,0x65,0x64,0x20,0x72,0x65,0x64,0x20,0x26,0x20,0x62,0x6C,0x75,0x65,0x20,0x63,0x68,0x61,0x6E,0x6E,0x65,0x6C,0x00,0x00,0x78,0x9C,0x65,0x91,0xBF,0x4B,0x1C,0x41,0x14,0xC7,0xDF,0x9D,0x85,0x41,0xF0,0x47,0x11,0x24,0x9D,0x4F,0x11,0xAB,0xBB,0x5B,0x31,0x98,0x88,0x95,0x7A,0xC5,0x81,0x88,0xE2,0xC5,0x90,0x5F,0x4D,0x76,0x67,0x9F,0x7B,0x4B,0x76,0x67,0x86,0x99,0xD9,0x3B,0xAF,0xD2,0xE2,0xB0,0xB6,0xB4,0xB0,0xD0,0xBF,0x41,0xD0,0x22,0x65,0x8A,0x20,0xA4,0x0B,0x09,0x24,0xF9,0x33,0x82,0x56,0x29,0x32,0xB3,0x7B,0xB0,0x26,0x7E,0x61,0x79,0x1F,0xBE,0xF3,0xDE,0x77,0xDF,0xEE,0x00,0x54,0x07,0x09,0x4B,0x75,0x75,0x0D,0x20,0xE5,0x46,0xB5,0x5B,0x1B,0xF8,0xFA,0xCD,0x5B,0x1C,0xFD,0x06,0x8F,0x60,0x1C,0xA6,0x61,0x16,0x6A,0x3E,0xD3,0xF2,0xC5,0xCB,0xED,0x57,0x60,0xC5,0x05,0x27,0x78,0xA0,0xBB,0xEF,0x50,0x71,0xF5,0x6B,0xBD,0xA5,0x28,0xFA,0x3C,0xF3,0x63,0xE7,0xF2,0xF0,0xD7,0xE4,0xD9,0xA7,0x74,0xD3,0xEB,0x7E,0x7C,0xF7,0xB0,0xFF,0x1F,0x8D,0x85,0xA4,0x99,0xAD,0x7F,0xEC,0x33,0x60,0x52,0x19,0x80,0xCA,0x91,0xE5,0x93,0x9E,0x91,0x96,0xAB,0x53,0x96,0x1F,0x07,0x1F,0x72,0x9E,0x77,0xAC,0xEC,0x82,0x96,0x57,0x1C,0x47,0x05,0x6F,0xE5,0x3D,0x05,0xBF,0xCF,0x7B,0xF6,0xDA,0x4D,0xCB,0x76,0x06,0x26,0xA2,0x7B,0x1C,0xDC,0xE3,0xE1,0x7B,0x9D,0x16,0xE6,0xF4,0x46,0xAB,0x3D,0xB7,0x8A,0x8A,0x42,0xF4,0x79,0x88,0x41,0x92,0x11,0xB2,0x8E,0xCF,0x39,0x25,0x1A,0x75,0xCF,0x97,0x92,0xC2,0xFF,0x16,0x7F,0xF6,0x1C,0x83,0xBE,0x21,0x8D,0x62,0x1F,0x7B,0xBE,0x36,0x76,0x54,0x4B,0x9F,0x51,0x0D,0x99,0xC8,0x94,0x3D,0xE8,0xBB,0x93,0x75,0x29,0x13,0xC2,0xA6,0x48,0x65,0x66,0x48,0xD5,0x30,0xCC,0x52,0x0C,0xC9,0x95,0x86,0xCD,0x30,0x74,0xE0,0x76,0x81,0xA6,0x90,0x7D,0x15,0x47,0x1D,0x83,0x4B,0x8B,0x8B,0xCB,0xE8,0x7E,0x23,0xB6,0x05,0x25,0x62,0x5F,0x37,0x70,0x2B,0x66,0xC4,0xB5,0x8D,0xCF,0x78,0x48,0x0A,0x9B,0x8A,0x7C,0x13,0x77,0xF3,0xD0,0x54,0x70,0x8D,0xEB,0xC6,0xA8,0x38,0xC8,0x4C,0x2C,0x78,0x7D,0x5B,0x70,0x67,0x93,0x62,0xB1,0x9F,0xD4,0xB0,0x63,0x8C,0x5C,0xF5,0x3C,0x36,0x1C,0x61,0xC5,0x44,0x43,0xA8,0xC8,0x4B,0x8A,0x54,0xED,0x05,0xFD,0x3A,0x67,0xDE,0x52,0x63,0xD9,0x43,0x70,0x77,0x5F,0x7C,0xDD,0xEF,0xDD,0xFC,0x4E,0x2B,0xD3,0x5F,0x4A,0xAF,0x54,0xE9,0xCD,0x9F,0x03,0x4C,0x0E,0x00,0xAE,0x6E,0x4A,0x2F,0x38,0x05,0xB8,0x3E,0x06,0x78,0xF2,0xB3,0xF4,0xC4,0x05,0xC0,0xCA,0x2D,0xC0,0xC8,0x09,0xCB,0x54,0x77,0x18,0x53,0xA9,0x3E,0x05,0xF8,0x0B,0xF7,0x9F,0x97,0xAA,0x95,0x7D,0xF0,0xA5};

struct 
{
	UInt32		length;
	UInt8		type[4];
	UInt8		*data;
	UInt32		crc;
	UInt32		valid;
}
typedef PngChunk;

static inline UInt8 *decompressData(UInt8 *compressedData, off_t compressedDataSize, off_t *decompressedDataSize, int windowBits)
{
	off_t availableSize = 5 * compressedDataSize; // 5:1 should be large enough
	if (availableSize < MIN_IMAGE_BUFFER_SIZE)
	{
		availableSize = MIN_IMAGE_BUFFER_SIZE;
	}
	//fprintf(stderr, "--------- availableSize: %d\n", (int)availableSize);
	UInt8 *decompressedData = (UInt8 *)malloc(availableSize);
	
	if (decompressedData != NULL)
	{
		z_stream stream;
		memset(&stream, 0x00, sizeof(stream));
		stream.next_in = compressedData;
		stream.avail_in = compressedDataSize;
		stream.total_in = 0;
		stream.next_out = decompressedData;
		stream.avail_out = availableSize;
		stream.total_out = 0;
		stream.zalloc = Z_NULL;
		stream.zfree = Z_NULL;
		stream.data_type = Z_BINARY;
		
		if (inflateInit2(&stream, windowBits) == Z_OK)
		{
			if (inflate(&stream, Z_FINISH) == Z_STREAM_END)
			{
				*decompressedDataSize = stream.total_out;
			}
			else
			{
				*decompressedDataSize = 0;
			}
			
			inflateEnd(&stream);
		}
		else
		{
			*decompressedDataSize = 0;
		}
	}
	
	return decompressedData;
}

static inline UInt8 *recompressData(UInt8 *decompressedData, off_t decompressedDataSize, off_t *recompressedDataSize)
{
	off_t availableSize = decompressedDataSize;
	UInt8 *recompressedData = (UInt8 *)malloc(availableSize);
	
	if ((recompressedData != NULL) && (decompressedDataSize > 0))
	{
		z_stream stream;
		memset(&stream, 0x00, sizeof(stream));
		stream.next_in = decompressedData;
		stream.avail_in = decompressedDataSize;
		stream.total_in = 0;
		stream.next_out = recompressedData;
		stream.avail_out = availableSize;
		stream.total_out = 0;
		stream.zalloc = Z_NULL;
		stream.zfree = Z_NULL;
		stream.data_type = Z_BINARY;
		
		if (deflateInit(&stream, Z_DEFAULT_COMPRESSION) == Z_OK)
		{
			deflate(&stream, Z_FINISH);
			deflateEnd(&stream);
			*recompressedDataSize = stream.total_out;
		}
		else
		{
			*recompressedDataSize = 0;
		}
	}
	else
	{
		*recompressedDataSize = 0;
	}
	
	return recompressedData;
}

static inline off_t grabChunk(PngChunk *chunk, UInt8 *data, off_t offset)
{
#if 0
	UInt8 *ptr = data;
#endif
	
	memset(chunk, 0x00, sizeof(PngChunk));
	
	data += offset;
	memcpy(&chunk->length, data, 4);
	chunk->length = CFSwapInt32BigToHost(chunk->length);
	
	data += 4;
	memcpy(&chunk->type, data, 4);
	
	data += 4;
	chunk->data = data;
	
	data += chunk->length;
	memcpy(&chunk->crc, data, 4);
	chunk->crc = CFSwapInt32BigToHost(chunk->crc);
	
	UInt32 crc = crc32(0, (unsigned char *)&chunk->type, 4);
	crc = crc32(crc, chunk->data, chunk->length);
	chunk->valid = (crc == chunk->crc);
	if (chunk->valid == 0)
	{
		fprintf(stderr, "<Error>: incorrect header check for %c%c%c%c 0x%x vs 0x%x\n", chunk->type[0], chunk->type[1], chunk->type[2], chunk->type[3], (unsigned int)crc, (unsigned int)chunk->crc);
	}
	
#if 0
	fprintf(stderr, "chunk type: %c%c%c%c\n", chunk->type[0], chunk->type[1], chunk->type[2], chunk->type[3]);
	fprintf(stderr, "	length: %d\n", chunk->length);
	int count = chunk->length;
	if (count > 16)
	{
		count = 16;
	}
	fprintf(stderr, "	data: ");
	for (int i=0; i<count; i++)
	{
		fprintf(stderr, "0x%x ", chunk->data[i]);
	}
	fprintf(stderr, "\n");
	fprintf(stderr, "	crc: Ox%x\n", chunk->crc);
	fprintf(stderr, "	valid: %d\n", chunk->valid);
#endif
	
#if 0
	if ((chunk->type[0] == 'i') && (chunk->type[1] == 'C') && (chunk->type[2] == 'C') && (chunk->type[3] == 'P'))
	{
		UInt32 count = 4+4+chunk->length+4;
		fprintf(stderr, "------------\n");
		for (int i=offset; i<offset+count; i++)
		{
			fprintf(stderr, "%X", ptr[i]);
		}
		fprintf(stderr, "\n");
	}
#endif
	
	return (offset+4+4+chunk->length+4);
}

void uncrush(UInt8 **dataHndl, off_t *dataLength)
{
	UInt8 *data = *dataHndl;
	
	off_t pngHeaderLength = sizeof(PngHeader);
	PngChunk firstChunk;
	off_t offset = grabChunk(&firstChunk, data, pngHeaderLength);
	if ((firstChunk.type[0] == 'C') && (firstChunk.type[1] == 'g') && (firstChunk.type[2] == 'B') && (firstChunk.type[3] == 'I'))
	{
		UInt8 *compressedPixels = NULL;
		off_t compressedPixelsSize = 0;
		
		UInt8 *newData = (UInt8 *)malloc(pngHeaderLength);
		off_t newOffset = pngHeaderLength;
		off_t newSize = pngHeaderLength;
		memcpy(newData, &PngHeader, pngHeaderLength);
		
		PngChunk chunk;
		while (offset < *dataLength)
		{
			offset = grabChunk(&chunk, data, offset);
			if ((chunk.type[0] == 'I') && (chunk.type[1] == 'D') && (chunk.type[2] == 'A') && (chunk.type[3] == 'T'))
			{
				compressedPixels = (UInt8 *)realloc(compressedPixels, (compressedPixelsSize+chunk.length));
				memcpy((compressedPixels+compressedPixelsSize), chunk.data, chunk.length);
				compressedPixelsSize += chunk.length;
			}
			else if ((chunk.type[0] == 'z') && (chunk.type[1] == 'T') && (chunk.type[2] == 'X') && (chunk.type[3] == 't'))
			{
				// skip
			}
			else if ((chunk.type[0] == 'i') && (chunk.type[1] == 'C') && (chunk.type[2] == 'C') && (chunk.type[3] == 'P'))
			{
#if 0
				fprintf(stderr, "--------- chunk.length: %d\n", chunk.length);
				UInt8 *name = chunk.data;
				off_t nameLength = strlen((char *)name);
				fprintf(stderr, "--------- name: %s\n", name);
				fprintf(stderr, "--------- nameLength: %d\n", (int)nameLength);
				
				UInt8 *compressedData = (chunk.data + (nameLength+1+1));
				off_t compressedDataSize = chunk.length - (nameLength+1+1);
				fprintf(stderr, "--------- compressedDataSize: %d\n", (int)compressedDataSize);
				
				off_t decompressedDataSize = 0;
				UInt8 *decompressedData = decompressData(compressedData, compressedDataSize, &decompressedDataSize, -8);
				fprintf(stderr, "--------- decompressedDataSize: %d\n", (int)decompressedDataSize);
				
				off_t recompressedDataSize = 0;
				UInt8 *recompressedData = recompressData(decompressedData, decompressedDataSize, &recompressedDataSize);
				fprintf(stderr, "--------- recompressedDataSize: %d\n", (int)recompressedDataSize);
				
				off_t newChunkDataSize = nameLength+1+1+recompressedDataSize;
				newSize += 4+4+newChunkDataSize+4;
				newData = realloc(newData, newSize);
				
				UInt32 length = CFSwapInt32HostToBig(newChunkDataSize);
				memcpy((newData+newOffset), &length, 4);
				
				newOffset += 4;
				memcpy((newData+newOffset), "iCCP", 4);
				UInt32 crc = crc32(0, (newData+newOffset), 4);
				
				newOffset += 4;
				memcpy((newData+newOffset), name, nameLength+2);
				newOffset += nameLength+2;
				memcpy((newData+newOffset), recompressedData, recompressedDataSize);
				
				crc = crc32(crc, (newData+newOffset-nameLength-2), recompressedDataSize+nameLength+2);
				
				newOffset += recompressedDataSize;
				crc = CFSwapInt32HostToBig(crc);
				memcpy((newData+newOffset), &crc, 4);
				
				newOffset += 4;
				
				free(recompressedData);
				free(decompressedData);
#endif
			}
			else
			{
				if ((chunk.type[0] == 'I') && (chunk.type[1] == 'E') && (chunk.type[2] == 'N') && (chunk.type[3] == 'D'))
				{
#if SWAP_R_AND_B
					newSize += sizeof(swapRandBiCPP);
					newData = (UInt8 *)realloc(newData, newSize);
					memcpy((newData+newOffset), swapRandBiCPP, sizeof(swapRandBiCPP));
					newOffset += sizeof(swapRandBiCPP);
#endif
					
					off_t decompressedPixelsSize = 0;
					UInt8 *decompressedPixels = decompressData(compressedPixels, compressedPixelsSize, &decompressedPixelsSize, -8);
					
					off_t recompressedPixelsSize = 0;
					UInt8 *recompressedPixels = recompressData(decompressedPixels, decompressedPixelsSize, &recompressedPixelsSize);
					
					newSize += 4+4+recompressedPixelsSize+4;
					newData = (UInt8 *)realloc(newData, newSize);
					
					UInt32 length = CFSwapInt32HostToBig(recompressedPixelsSize);
					memcpy((newData+newOffset), &length, 4);
					
					newOffset += 4;
					memcpy((newData+newOffset), "IDAT", 4);
					UInt32 crc = crc32(0, (newData+newOffset), 4);
					
					newOffset += 4;
					memcpy((newData+newOffset), recompressedPixels, recompressedPixelsSize);
					crc = crc32(crc, (newData+newOffset), recompressedPixelsSize);
					
					newOffset += recompressedPixelsSize;
					crc = CFSwapInt32HostToBig(crc);
					memcpy((newData+newOffset), &crc, 4);
					
					newOffset += 4;
					
					free(recompressedPixels);
					free(decompressedPixels);
					free(compressedPixels);
				}
				
				off_t chunkTotalLength = 4+4+chunk.length+4;
				newSize += chunkTotalLength;
				newData = (UInt8 *)realloc(newData, newSize);
				
				memcpy((newData+newOffset), (data+offset-chunkTotalLength), chunkTotalLength);
				newOffset += chunkTotalLength;
			}
		}
		
		free(data);
		*dataHndl = newData;
		*dataLength = newSize;
	}
	else
	{
		PngChunk chunk;
		while (offset < *dataLength)
		{
			offset = grabChunk(&chunk, data, offset);
		}
	}
}

void getPngInfo(char *filePath, PngInfo *info)
{
	memset(info, 0x00, sizeof(PngInfo));
	
	int file = open((const char *)filePath, O_RDONLY, O_NOFOLLOW);
	if (file > 0)
	{
		struct stat fileStat;
		if (fstat(file, &fileStat) == 0)
		{
			off_t dataLength = fileStat.st_size;
			UInt8 *data = (UInt8 *)malloc(dataLength);
			if (data != NULL)
			{
				if (read(file, data, dataLength) == dataLength)
				{
					if (memcmp(data, PngHeader, sizeof(PngHeader)) == 0)
					{
						PngChunk chunkIHDR;
						off_t offset = grabChunk(&chunkIHDR, data, sizeof(PngHeader));
						if ((chunkIHDR.type[0] != 'I') || (chunkIHDR.type[1] != 'H') || (chunkIHDR.type[2] != 'D') || (chunkIHDR.type[3] != 'R'))
						{
							info->crushed = 1;
							grabChunk(&chunkIHDR, data, offset);
						}
						
						if ((chunkIHDR.type[0] == 'I') && (chunkIHDR.type[1] == 'H') && (chunkIHDR.type[2] == 'D') && (chunkIHDR.type[3] == 'R'))
						{
							UInt8 *chunkData = chunkIHDR.data;
							
							memcpy(&info->width, chunkData, 4);
							info->width = CFSwapInt32BigToHost(info->width);
							
							memcpy(&info->height, (chunkData+4), 4);
							info->height = CFSwapInt32BigToHost(info->height);
							
							memcpy(&info->depth, (chunkData+8), 1);
							
							memcpy(&info->color, (chunkData+9), 1);
							
							memcpy(&info->interlaced, (chunkData+12), 1);
						}
					}
				}
				free(data);
			}
		}
		close(file);
	}
	
#if 0
	fprintf(stderr, "Png file: %s\n", filePath);
	fprintf(stderr, "	crushed: %u\n", *crushed);
	fprintf(stderr, "	width: %u\n", (unsigned int)*width);
	fprintf(stderr, "	height: %u\n", (unsigned int)*height);
	fprintf(stderr, "	depth: %u\n", *depth);
	fprintf(stderr, "	color: %u\n", *color);
	fprintf(stderr, "	interlaced: %u\n", *interlaced);
#endif
	
}
void GetPngInfo(CFURLRef url, PngInfo *info)
{
	UInt8 *filePath = (UInt8 *)malloc(MAX_PATH_LENGTH);
	CFURLGetFileSystemRepresentation(url, true, filePath, MAX_PATH_LENGTH);
	
	getPngInfo((char*)filePath, info);
	
	free(filePath);
}

CGImageRef GetPngImage(CFURLRef url, CFStringRef contentTypeUTI)
{
	CGImageRef imageRef = NULL;
	
	if (url != NULL)
	{
		PngInfo info;
		GetPngInfo(url, &info);
		
		UInt8 *data = NULL;
		off_t dataLength = 0;
		UInt8 *filePath = (UInt8 *)malloc(MAX_PATH_LENGTH);
		CFURLGetFileSystemRepresentation(url, true, filePath, MAX_PATH_LENGTH);
		int file = open((const char *)filePath, O_RDONLY, O_NOFOLLOW);
		if (file > 0)
		{
			struct stat fileStat;
			if (fstat(file, &fileStat) == 0)
			{
				dataLength = fileStat.st_size;
				data = (UInt8 *)malloc(dataLength);
				if (data != NULL)
				{
					if (read(file, data, dataLength) != dataLength)
					{
						free(data);
						data = NULL;
						dataLength = 0;
					}
				}
			}
			close(file);
			file = 0;
		}
		free(filePath);
		
#if DEBUG_DUMP_IMAGE
		if (info.crushed == 1)
		{
			file = open("/tmp/imgCrushed.png", O_CREAT|O_WRONLY, S_IRUSR|S_IWUSR);
			if (file > 0)
			{
				struct stat fileStat;
				if (fstat(file, &fileStat) == 0)
				{
					lseek(file, 0L, SEEK_SET);
					write(file, data, dataLength);
				}
				close(file);
				file = 0;
			}
		}
#endif
		
		if (info.crushed == 1)
		{
			uncrush(&data, &dataLength);
		}
		
#if DEBUG_DUMP_IMAGE
		file = open("/tmp/img.png", O_CREAT|O_WRONLY, S_IRUSR|S_IWUSR);
		if (file > 0)
		{
			struct stat fileStat;
			if (fstat(file, &fileStat) == 0)
			{
				lseek(file, 0L, SEEK_SET);
				write(file, data, dataLength);
			}
			close(file);
			file = 0;
		}
#endif
		
		CGImageSourceRef sourceRef = NULL;
		if (data != NULL)
		{
			CFDataRef cfDataRe = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, data, dataLength, kCFAllocatorDefault) ;// data buffer will be released automatically
			if (cfDataRe != NULL)
			{
				sourceRef = CGImageSourceCreateWithData(cfDataRe, NULL);
				CFRelease(cfDataRe);
			}
			else
			{
				free(data);
			}
		}
		if (sourceRef == NULL)
		{
			sourceRef = CGImageSourceCreateWithURL(url, NULL);
		}
		
		if (sourceRef != NULL)
		{
			imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
		}
		
		CFRelease(sourceRef);
	}
	
	return imageRef;
}

void FixPngImageIfNeeded(char *path, char *pathFixed)
{
#if 0
	fprintf(stderr, "FixPngImageIfNeeded\n");
	fprintf(stderr, "	path: %s\n", path);
	fprintf(stderr, "	pathFixed: %s\n", pathFixed);
#endif
	
	PngInfo info;
	getPngInfo(path, &info);
	
	if (info.crushed == 1)
	{
		UInt8 *data = NULL;
		off_t dataLength = 0;
		int fileRd = open((const char *)path, O_RDONLY, O_NOFOLLOW);
		if (fileRd > 0)
		{
			struct stat fileStat;
			if (fstat(fileRd, &fileStat) == 0)
			{
				dataLength = fileStat.st_size;
				data = (UInt8 *)malloc(dataLength);
				if (data != NULL)
				{
					if (read(fileRd, data, dataLength) == dataLength)
					{
						uncrush(&data, &dataLength);
						
						int fileWr = open((const char *)pathFixed, O_CREAT|O_WRONLY, O_NOFOLLOW);
						if (fileWr > 0)
						{
							lseek(fileWr, 0L, SEEK_SET);
							write(fileWr, data, dataLength);
							
							close(fileWr);
							fileWr = 0;
						}
					}
					
					free(data);
					data = NULL;
					dataLength = 0;
				}
			}
		}
		
		close(fileRd);
		fileRd = 0;
	}
}
