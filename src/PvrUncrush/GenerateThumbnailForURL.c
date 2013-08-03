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

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
	if (url == NULL)
	{
		return -1;
	}
	
	//fprintf(stderr, "GenerateThumbnailForURL\n");
	//CFShow(url);
	//fprintf(stderr, "maxSize: %fx%f\n", maxSize.width, maxSize.height);
	if ((maxSize.width == 200.0f) && (maxSize.height == 202.0f))
	{
		// hack to keep atPeek preview nice
		maxSize.height = 200.0f;
	}
	//fprintf(stderr, "maxSize: %fx%f\n", maxSize.width, maxSize.height);
	//CFShow(options);
	
	Boolean opaque = false;
	if (CFDictionaryGetValue(options, CFSTR("opaque")) != NULL)
	{
		opaque = CFBooleanGetValue(CFDictionaryGetValue(options, CFSTR("opaque")));
	}
	
	CGImageRef imageRef = GetPvrImage(url, contentTypeUTI);
	if (imageRef != NULL)
	{
		CGRect imageRect = CGRectMake(0, 0, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
		float ratio = imageRect.size.width / imageRect.size.height;
		//fprintf(stderr, "imageSize: %dx%d, ratio: %f\n", (int)CGImageGetWidth(imageRef), (int)CGImageGetHeight(imageRef), ratio);
		if ((imageRect.size.width > maxSize.width) || (imageRect.size.height > maxSize.height))
		{
			if (imageRect.size.width > imageRect.size.height)
			{
				imageRect.size.width = maxSize.width;
				imageRect.size.height = maxSize.height/ratio;
			}
			else
			{
				imageRect.size.width = maxSize.width*ratio;
				imageRect.size.height = maxSize.height;
			}
		}
		imageRect.origin.x = (int)(((maxSize.width - imageRect.size.width) / 2.0) + 0.5);
		imageRect.origin.y = (int)(((maxSize.height - imageRect.size.height) / 2.0) + 0.5);
		//fprintf(stderr, "imageRect: %f,%f %fx%f\n", imageRect.origin.x , imageRect.origin.y, imageRect.size.width, imageRect.size.height);
		
		CGContextRef cgContext = QLThumbnailRequestCreateContext(thumbnail, maxSize, TRUE, NULL);
		if (cgContext != NULL)
		{
			CGContextSaveGState(cgContext);
			{
				if (opaque == 1)
				{
					CGRect contextRect = CGRectMake(0, 0, maxSize.width, maxSize.height);
					CGContextSetRGBFillColor(cgContext, 0.57, 0.57, 0.57, 1);
					CGContextFillRect(cgContext, contextRect);
				}
				
				CGContextDrawImage(cgContext, imageRect, imageRef);
			}
			CGContextRestoreGState(cgContext);
			
			QLThumbnailRequestFlushContext(thumbnail, cgContext);
			CFRelease(cgContext);
		}
		
		CFRelease(imageRef);
	}
	
    return noErr;
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}
