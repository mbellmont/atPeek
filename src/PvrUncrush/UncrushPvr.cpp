/*
 
 QuickLook plugin for PVR images
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

#include "UncrushPvr.h"

#include <ApplicationServices/ApplicationServices.h>
#include <QuickTime/QuickTime.h>
#include <QuickTime/ImageCompression.h>
#include <QuickTime/Movies.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "PVRTexLib.h"
using namespace pvrtexlib;

#define MAX_PATH_LENGTH 2048

void GetPvrInfo(CFURLRef url, PvrInfo *info)
{
	memset(info, 0x00, sizeof(PvrInfo));
	
	UInt8 *filePath = (UInt8*)malloc(MAX_PATH_LENGTH);
	CFURLGetFileSystemRepresentation(url, true, filePath, MAX_PATH_LENGTH);
	{
		PVRTRY
		{
			CPVRTexture texture((char*)filePath);
			CPVRTextureHeader header = texture.getHeader();
			
			info->width = texture.getWidth();
			info->height = texture.getHeight();
			info->depth = header.getBitsPerPixel();
			info->mipmapsCount = texture.getMipMapCount();
		}
		PVRCATCH (myException)
		{
			//printf("GetPvrInfo exception : %s", myException.what());
		}
	}
	free(filePath);
}

CGImageRef getPvrImage(char *path)
{
	CGImageRef imageRef = NULL;
	
	PVRTRY
	{
		PVRTextureUtilities *PVRU = PVRTextureUtilities::getPointer();
		CPVRTexture texture(path);
		CPVRTexture image;
		PVRU->DecompressPVR(texture, image);
		if (image.getPixelType() == DX10_R8G8B8A8_UNORM)
		{
			CPVRTextureData textureData = image.getData();
			
			size_t size = image.getWidth()*image.getHeight()*4;
			void *data = malloc(size);
			memcpy(data, textureData.getData(), size);
			CGDataProviderRef providerRef = CGDataProviderCreateWithData(NULL, data, size, NULL);
			CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
			imageRef = CGImageCreate(image.getWidth(), image.getHeight(), 8, 32, 4*image.getHeight(),
									 colorSpaceRef, kCGBitmapByteOrderDefault, providerRef, NULL, true, kCGRenderingIntentDefault);
			CGColorSpaceRelease(colorSpaceRef);
			CGDataProviderRelease(providerRef);
		}
	}
	PVRCATCH (myException)
	{
		printf("GetPvrInfo exception : %s", myException.what());
	}
	
	return imageRef;
}

CGImageRef GetPvrImage(CFURLRef url, CFStringRef contentTypeUTI)
{
	//CFShow(url);
	//CFShow(contentTypeUTI);
	
	CGImageRef imageRef = NULL;
	
	if (url != NULL)
	{
		UInt8 *filePath = (UInt8*)malloc(MAX_PATH_LENGTH);
		CFURLGetFileSystemRepresentation(url, true, filePath, MAX_PATH_LENGTH);
		{
			imageRef = getPvrImage((char*)filePath);
		}
		free(filePath);
	}
	return imageRef;
}

void FixPvrImageIfNeeded(char *path, char *pathFixed)
{
//	fprintf(stderr, "FixPvrImageIfNeeded\n");
//	fprintf(stderr, "	path: %s\n", path);
//	fprintf(stderr, "	pathFixed: %s\n", pathFixed);

    // FIXME
#if 0
    fprintf(stderr, "WARNING: atPeeks' UncrushPVR FixPvrImageIfNeeded() needs to be fixed\n");
	CGImageRef imageRef = getPvrImage(path);
	if (imageRef != NULL)
	{
		CFStringRef cfpathFixed = CFStringCreateWithCStringNoCopy(NULL, pathFixed, kCFStringEncodingUTF8, NULL);
		if (cfpathFixed != NULL)
		{
			Handle  dataRef = NULL;
			OSType  dataRefType;
			
			GraphicsExportComponent grex = 0;
			unsigned long sizeWritten;
			
			ComponentResult result;
			
			// create the data reference
			result = QTNewDataReferenceFromFullPathCFString(cfpathFixed, kQTNativeDefaultPathStyle,
															0, &dataRef, &dataRefType);
			
			if (NULL != dataRef && noErr == result) {
				// get the PNG exporter
				result = OpenADefaultComponent(GraphicsExporterComponentType, kQTFileTypePNG,
											   &grex);
				
				if (grex) {
					// tell the exporter where to find its source image
					result = GraphicsExportSetInputCGImage(grex, imageRef);
					
					if (noErr == result) {
						// tell the exporter where to save the exporter image
						result = GraphicsExportSetOutputDataReference(grex, dataRef, 
																	  dataRefType);
						
						if (noErr == result) {
							// write the PNG file
							result = GraphicsExportDoExport(grex, &sizeWritten);
						}
					}
					
					// remember to close the component
					CloseComponent(grex);
				}
				
				// remember to dispose of the data reference handle
				DisposeHandle(dataRef);
			}
		}
	}
#endif
}
