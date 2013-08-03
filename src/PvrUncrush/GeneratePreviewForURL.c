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

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#include "UncrushPvr.h"

#define MIN_SIZE 256.0
#define MAX_SIZE 1024.0

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
	if (url == NULL)
	{
		return -1;
	}
	
	//fprintf(stderr, "GeneratePreviewForURL\n");
	CGImageRef imageRef = GetPvrImage(url, contentTypeUTI);
	if (imageRef != NULL)
	{
		CGSize contextSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
		float ratio = contextSize.width / contextSize.height;
		//fprintf(stderr, "imageSize: %fx%f, ratio: %f\n", contextSize.width, contextSize.height, ratio);
		if ((contextSize.width > MAX_SIZE) || (contextSize.height > MAX_SIZE))
		{
			if (contextSize.width > contextSize.height)
			{
				contextSize.width = MAX_SIZE;
				contextSize.height = MAX_SIZE/ratio;
			}
			else
			{
				contextSize.width = MAX_SIZE*ratio;
				contextSize.height = MAX_SIZE;
			}
		}
		else if ((contextSize.width < MIN_SIZE) || (contextSize.height < MIN_SIZE))
		{
			if (contextSize.width < contextSize.height)
			{
				contextSize.width = MIN_SIZE;
				contextSize.height = MIN_SIZE/ratio;
			}
			else
			{
				contextSize.width = MIN_SIZE*ratio;
				contextSize.height = MIN_SIZE;
			}
			
			if ((contextSize.width > MAX_SIZE) || (contextSize.height > MAX_SIZE))
			{
				if (contextSize.width > contextSize.height)
				{
					contextSize.width = MAX_SIZE;
					contextSize.height = MAX_SIZE/ratio;
				}
				else
				{
					contextSize.width = MAX_SIZE*ratio;
					contextSize.height = MAX_SIZE;
				}
			}
		}
		//fprintf(stderr, "contextSize: %fx%f\n", contextSize.width, contextSize.height);
		
		CGContextRef cgContext = QLPreviewRequestCreateContext(preview, contextSize, TRUE, NULL);
		if (cgContext != NULL)
		{
			CGContextSaveGState(cgContext);
			{
				CGRect contextRect = CGRectMake(0, 0, contextSize.width, contextSize.height);
				CGContextDrawImage(cgContext, contextRect, imageRef);
			}
			CGContextRestoreGState(cgContext);
			
			QLPreviewRequestFlushContext(preview, cgContext);
			CFRelease(cgContext);
		}
		CFRelease(imageRef);
	}
	
    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
