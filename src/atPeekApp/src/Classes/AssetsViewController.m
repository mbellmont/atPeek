/*
 
 atPeek - iPhone app browsing tool
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

#import <QuickLook/QuickLook.h>
#import <Quartz/Quartz.h>

#import "AssetsViewController.h"
#import "Utilities.h"
#import "UncrushPng.h"
#import "UncrushPvr.h"

#define IPHONE_WIDTH			320
#define IPHONE_HEIGHT			480
#define IPHONE_PREVIEW_WIDTH	IPHONE_WIDTH+42 // iphone is 320 but preview takes 42
#define IPHONE_PREVIEW_HEIGHT	IPHONE_HEIGHT+64 // iphone is 320 but preview takes 64
#define ITEM_VIEW_WIDTH			128
#define ITEM_VIEW_HEIGHT		95
#define PREVIEW_ICON_SIZE		220
#define PREVIEW_MARGIN			10
#define ASSET_ICON_SIZE			40

#define IPHONE_CRUSH			@"PNG image (iPhone),"
#define PVR_TETURE				@"PVR texture,"
#define ITUNES_ARTWORK			@"iTunesArtwork"
#define ITUNES_ARTWORK			@"iTunesArtwork"
#define ITUNES_ARTWORK_EXT		@".jpg"

@implementation AssetsNSBox : NSBox

@end

@implementation AssetsScrollView : NSScrollView

- (void)drawRect:(NSRect)dirtyRect
{
	NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(dirtyRect.origin.x, dirtyRect.origin.y, dirtyRect.size.width, dirtyRect.size.height)];
	[[NSColor whiteColor] set];
	[path fill];
	
	[super drawRect:dirtyRect];
}

@end

@implementation AssetsArrayController : NSArrayController

@synthesize delegate;

- (BOOL)setSelectionIndexes:(NSIndexSet *)indexes
{
	BOOL changed = [super setSelectionIndexes:indexes];
	
	id object = nil;
	if ([[self selectedObjects] count] > 0)
	{
		object = [[self selectedObjects] objectAtIndex:0];
	}
	[self->delegate selectionChanged:object];
	
	return changed;
}

@end

@implementation AssetsViewController

@synthesize delegate, assetPreviewButton, assets, sortingMode, tempFolder, defaultIcon, ipaFile, thumbnailIcon, previewTitle, previewUrl, lock;

#define KEY_ASSETS_NAME					@"name"
#define KEY_ASSETS_ICON					@"icon"
#define KEY_ASSETS_THUMBNAIL			@"preview"
#define KEY_ASSETS_THUMBNAIL_LOADING	@"previewLoading"
#define KEY_ASSETS_IPA_FILE				@"ipaFile"
#define KEY_ASSETS_IPA_PATH				@"ipaPath"
#define KEY_ASSETS_IPA_FOLDER			@"ipaFolder"
#define KEY_ASSETS_IPA_FOLDER_FULL		@"ipaFolderFull"
#define KEY_ASSETS_TMP_PATH				@"tmpPath"
#define KEY_ASSETS_SIZE					@"size"
#define KEY_ASSETS_KIND					@"kind"

#define ASSETS_DICTIONARY_SIZE			11

- (void)awakeFromNib
{
	[self->collectionView setMinItemSize:NSMakeSize(ITEM_VIEW_WIDTH, ITEM_VIEW_HEIGHT)];
	[self->collectionView setMaxItemSize:NSMakeSize(ITEM_VIEW_WIDTH, ITEM_VIEW_HEIGHT)];
	[self setDefaultIcon:[[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericDocumentIcon.icns"]];
	[self setTempFolder:[NSTemporaryDirectory() stringByAppendingPathComponent:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]]];
	[self setLock:[[NSLock alloc] init]];
	self->seed = 0;
}

- (void)assetsChanged:(NSArray*)newAssets withSizes:(NSDictionary*)sizes forIpa:(NSString*)ipa forApp:(NSString*)name forFolder:(NSString*)folder
{
	//NSLog(@"newAssets:\n%@", newAssets);
	//NSLog(@"sizes:\n%@", sizes);
	//NSLog(@"ipa:%@", ipa);
	//NSLog(@"folder:%@", folder);
	int index = 0;
	@try
	{
		[self->lock lock];
		self->seed++;
		
		[self setIpaFile:ipa];
		
		NSString *folderPath = [self->tempFolder stringByAppendingPathComponent:name];
		//NSLog(@"folderPath: %@", folderPath);
		
		NSMutableArray *list = [NSMutableArray arrayWithCapacity:[newAssets count]];
		for (int i=0; i<[newAssets count]; i++)
		{
			NSString *ipaPath = [newAssets objectAtIndex:i];
			//NSLog(@"	ipaPath: %@", ipaPath);
			
			NSString *tmpPath = [folderPath stringByAppendingPathComponent:ipaPath];
			//NSLog(@"	tmpPath: %@", tmpPath);
			
			NSString *size = [NSString stringWithFormat:@"%s", utf8StringFor([[sizes objectForKey:ipaPath] doubleValue], BASE_10_KB, TWO_DIGIT)];
			//NSLog(@"	size: %@", size);
			
			NSMutableDictionary *assetDictionary = [NSMutableDictionary dictionaryWithCapacity:ASSETS_DICTIONARY_SIZE];
			[assetDictionary setObject:ipa forKey:KEY_ASSETS_IPA_FILE];
			[assetDictionary setObject:[ipaPath lastPathComponent] forKey:KEY_ASSETS_NAME];
			[assetDictionary setObject:self->defaultIcon forKey:KEY_ASSETS_ICON];
			//[assetDictionary setObject:self->defaultIcon forKey:KEY_ASSETS_THUMBNAIL];
			[assetDictionary setObject:[NSNumber numberWithBool:NO] forKey:KEY_ASSETS_THUMBNAIL_LOADING];
			[assetDictionary setObject:ipaPath forKey:KEY_ASSETS_IPA_PATH];
			[assetDictionary setObject:[ipaPath stringByDeletingLastPathComponent] forKey:KEY_ASSETS_IPA_FOLDER];
			[assetDictionary setObject:[NSString stringWithFormat:@"/%@", [ipaPath stringByDeletingLastPathComponent]] forKey:KEY_ASSETS_IPA_FOLDER_FULL];
			[assetDictionary setObject:tmpPath forKey:KEY_ASSETS_TMP_PATH];
			[assetDictionary setObject:size forKey:KEY_ASSETS_SIZE];
			[assetDictionary setObject:@"unknown" forKey:KEY_ASSETS_KIND];
			//NSLog(@"assetDictionary: %@", assetDictionary);
			
			[list addObject:assetDictionary];
		}
		
		//NSLog(@"list:\n%@", list);
		[self setAssets:list];
		
		if ([folder isEqual:@"/"] == YES)
		{
			int index = 0;
			for (int i=0; i<[list count]; i++)
			{
				NSDictionary *dictionary = [list objectAtIndex:i];
				if ([[dictionary objectForKey:KEY_ASSETS_NAME] isEqual:ITUNES_ARTWORK] == YES)
				{
					index = i; // select iTunesArtwork file
					break;
				}
			}
		}
	}
	@catch (NSException *e)
	{
		[NSApp reportException:e];
	}
	@finally
	{
		[self->lock unlock];
	}
	
	[self->arrayController setSelectionIndexes:[NSIndexSet indexSetWithIndex:index]];
	
	[self performSelectorInBackground:@selector(getPreviews) withObject:nil];
}

- (BOOL)isImage:(NSString*)path
{
	NSString *ext = [path pathExtension];
	if ([ext caseInsensitiveCompare:@"png"] == NSOrderedSame)
	{
		return YES;
	}
	else if ([ext caseInsensitiveCompare:@"pvr"] == NSOrderedSame)
	{
		return YES;
	}
	else if ([ext caseInsensitiveCompare:@"pvrt"] == NSOrderedSame)
	{
		return YES;
	}
	else if ([ext caseInsensitiveCompare:@"jpg"] == NSOrderedSame)
	{
		return YES;
	}
	else if ([ext caseInsensitiveCompare:@"jpeg"] == NSOrderedSame)
	{
		return YES;
	}
	else if ([ext caseInsensitiveCompare:@"tif"] == NSOrderedSame)
	{
		return YES;
	}
	else if ([ext caseInsensitiveCompare:@"tiff"] == NSOrderedSame)
	{
		return YES;
	}
	else if ([ext caseInsensitiveCompare:@"gif"] == NSOrderedSame)
	{
		return YES;
	}
	else if ([ext caseInsensitiveCompare:@"ico"] == NSOrderedSame)
	{
		return YES;
	}
	else if ([ext caseInsensitiveCompare:@"jp2"] == NSOrderedSame)
	{
		return YES;
	}
	else if ([ext caseInsensitiveCompare:@"pic"] == NSOrderedSame)
	{
		return YES;
	}
	else if ([ext caseInsensitiveCompare:@"pict"] == NSOrderedSame)
	{
		return YES;
	}
	else if ([ext caseInsensitiveCompare:@"pct"] == NSOrderedSame)
	{
		return YES;
	}
	else if ([ext caseInsensitiveCompare:@"icns"] == NSOrderedSame)
	{
		return YES;
	}
	else if ([ext caseInsensitiveCompare:@"bmp"] == NSOrderedSame)
	{
		return YES;
	}
	else if ([ext caseInsensitiveCompare:@"tga"] == NSOrderedSame)
	{
		return YES;
	}
	else if ([ext caseInsensitiveCompare:@"sgi"] == NSOrderedSame)
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

- (void)extractAsset:(id)selection
{
	NSString *tmpPath = [selection objectForKey:KEY_ASSETS_TMP_PATH];
	//NSLog(@"tmpPath: %@", tmpPath);
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:tmpPath] == NO)
	{
		NSString *tmpFolder = [tmpPath stringByDeletingLastPathComponent];
		//NSLog(@"tmpFolder: %@", tmpFolder);		
		
		NSString *ipaPath = [selection objectForKey:KEY_ASSETS_IPA_PATH];
		//NSLog(@"ipaPath: %@", ipaPath);
		
		NSString *ipaFolder = [ipaPath stringByDeletingLastPathComponent];
		//NSLog(@"ipaFolder: %@", ipaFolder);
		
		NSString *dstFolder = [tmpFolder stringByReplacingOccurrencesOfString:ipaFolder withString:@""];
		//NSLog(@"dstFolder: %@", dstFolder);
		
		NSString *command = [NSString stringWithFormat:@"/usr/bin/unzip -qqo \"%@\" \"%@\" -d \"%@\"", self->ipaFile, ipaPath, dstFolder];
		//NSLog(@"command: %@", command);
		runCommandUsingPopen(command);
		
		if ([fileManager fileExistsAtPath:tmpPath] == NO)
		{
			//NSLog(@"repeating command: %@", command);
			runCommandUsingNSTask(command);
		}
		
		NSDictionary *attributes = [fileManager attributesOfItemAtPath:tmpPath error:nil];
		//NSLog(@"attributes:\n%@", attributes);
		if ([attributes filePosixPermissions] == 0)
		{
			command = [NSString stringWithFormat:@"/bin/chmod a+rw \"%@\"", tmpPath];
			runCommandUsingNSTask(command);
		}
	}
}

- (void)getPreview:(id)selection
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	UInt32 localSeedPreview = ++self->seedPreview;
	
	[selection setObject:[NSNumber numberWithBool:YES] forKey:KEY_ASSETS_THUMBNAIL_LOADING];
	
	NSString *tmpPath = [selection objectForKey:KEY_ASSETS_TMP_PATH];
	if ([[tmpPath lastPathComponent] isEqual:ITUNES_ARTWORK] == YES)
	{
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if ([fileManager fileExistsAtPath:[tmpPath stringByAppendingString:ITUNES_ARTWORK_EXT]] == YES)
		{
			tmpPath = [tmpPath stringByAppendingString:ITUNES_ARTWORK_EXT];
		}
	}
	
	[self setPreviewUrl:[NSURL fileURLWithPath:tmpPath]];
	[self setPreviewTitle:[selection objectForKey:KEY_ASSETS_NAME]];
	
	NSDictionary *quickLookOptions = [[NSDictionary alloc] initWithObjectsAndKeys:(id)kCFBooleanTrue, (id)kQLThumbnailOptionIconModeKey, (id)kCFBooleanTrue, (id)CFSTR("opaque"), nil];
	CGImageRef cgIcon = QLThumbnailImageCreate(NULL, (CFURLRef)self->previewUrl, CGSizeMake(PREVIEW_ICON_SIZE, PREVIEW_ICON_SIZE), (CFDictionaryRef)quickLookOptions);
	if (cgIcon != NULL)
	{
		NSImage* nsIcon = [[NSImage alloc] initWithCGImage:cgIcon size:NSMakeSize(CGImageGetWidth(cgIcon), CGImageGetWidth(cgIcon))];
		[selection setObject:nsIcon forKey:KEY_ASSETS_THUMBNAIL];
		[nsIcon release];
		
		CFRelease(cgIcon);
	}
	else
	{
		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[selection objectForKey:KEY_ASSETS_TMP_PATH]];
		[selection setObject:icon forKey:KEY_ASSETS_THUMBNAIL];
	}
	[quickLookOptions release];
	
	[self setThumbnailIcon:[selection objectForKey:KEY_ASSETS_THUMBNAIL]];
	
	// let the background task do this
	//[self getPreviewIcon:selection forPath:tmpPath];
	
	if ((localSeedPreview == self->seedPreview) && ([[QLPreviewPanel sharedPreviewPanel] currentController] != nil))
	{
		[[QLPreviewPanel sharedPreviewPanel] reloadData];
		[[QLPreviewPanel sharedPreviewPanel] refreshCurrentPreviewItem];
	}
	
	[selection setObject:[NSNumber numberWithBool:NO] forKey:KEY_ASSETS_THUMBNAIL_LOADING];
	
    [pool drain];
}

- (void)getPreviewIcon:(id)selection
{
	NSString *path = [selection objectForKey:KEY_ASSETS_TMP_PATH];
	NSString *name = [selection objectForKey:KEY_ASSETS_NAME];
	if ([name isEqual:ITUNES_ARTWORK] == YES)
	{
		path = [path stringByAppendingString:ITUNES_ARTWORK_EXT];
	}
	
	NSDictionary *quickLookOptions = nil;
	if ([self isImage:path] == YES)
	{
		quickLookOptions = [[NSDictionary alloc] initWithObjectsAndKeys:(id)kCFBooleanFalse, (id)kQLThumbnailOptionIconModeKey, (id)kCFBooleanFalse, (id)CFSTR("opaque"), nil];
	}
	else
	{
		quickLookOptions = [[NSDictionary alloc] initWithObjectsAndKeys:(id)kCFBooleanTrue, (id)kQLThumbnailOptionIconModeKey, (id)kCFBooleanFalse, (id)CFSTR("opaque"), nil];
	}
	
	CGImageRef cgIcon = QLThumbnailImageCreate(NULL, (CFURLRef)[NSURL fileURLWithPath:path], CGSizeMake(ASSET_ICON_SIZE, ASSET_ICON_SIZE), (CFDictionaryRef)quickLookOptions);
	if (cgIcon != NULL)
	{
		NSImage* nsIcon = [[NSImage alloc] initWithCGImage:cgIcon size:NSMakeSize(CGImageGetWidth(cgIcon), CGImageGetWidth(cgIcon))];
		[selection setObject:nsIcon forKey:KEY_ASSETS_ICON];
		[nsIcon release];
		
		CFRelease(cgIcon);
	}
	else
	{
		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[selection objectForKey:KEY_ASSETS_TMP_PATH]];
		[selection setObject:icon forKey:KEY_ASSETS_ICON];
	}
	[quickLookOptions release];
}

- (void)getPreviews
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	UInt seedStamp = 0;
	[self->lock lock];
	{
		seedStamp = self->seed;
	}
	[self->lock unlock];
	
	for (int i=0; i<[self->assets count]; i++)
	{
		[self->lock lock];
		{
			@try
			{
				if (seedStamp == self->seed)
				{
					id selection = [self->assets objectAtIndex:i];
					if ([selection objectForKey:KEY_ASSETS_ICON] == self->defaultIcon)
					{
						[self extractAsset:selection];
						[self getPreviewIcon:selection];
					}
				}
			}
			@catch (NSException * e)
			{
				[NSApp reportException:e];
			}
			@finally
			{
				[self->lock unlock];
			}
		}
		
		if (seedStamp != self->seed)
		{
			break;
		}
	}
	
    [pool drain];
}

- (void)selectionChanged:(id)selection
{
	if (selection != nil)
	{
		@try
		{
			[self->lock lock];
			{
				NSString *tmpPath = [selection objectForKey:KEY_ASSETS_TMP_PATH];
				//NSLog(@"tmpPath: %@", tmpPath);
				
				NSString *tmpFolder = [tmpPath stringByDeletingLastPathComponent];
				//NSLog(@"tmpFolder: %@", tmpFolder);		
				
				NSString *ipaPath = [selection objectForKey:KEY_ASSETS_IPA_PATH];
				//NSLog(@"ipaPath: %@", ipaPath);
				
				NSString *ipaFolder = [ipaPath stringByDeletingLastPathComponent];
				//NSLog(@"ipaFolder: %@", ipaFolder);
				
				NSString *dstFolder = [tmpFolder stringByReplacingOccurrencesOfString:ipaFolder withString:@""];
				//NSLog(@"dstFolder: %@", dstFolder);
				
				NSError *error = nil;
				NSFileManager *fileManager = [NSFileManager defaultManager];
				if ([fileManager fileExistsAtPath:tmpFolder] == NO)
				{
					if ([fileManager createDirectoryAtPath:tmpFolder withIntermediateDirectories:YES attributes:nil error:&error] == NO)
					{
						NSLog(@"[NSFileManager createDirectoryAtPath:\"%@\"] failed!.", self->tempFolder);
						[NSApp presentError:error];
						[NSApp terminate:self];
					}
				}
				
				if ([fileManager fileExistsAtPath:tmpPath] == NO)
				{
					[self extractAsset:selection];
				}
				
				NSString *command = [NSString stringWithFormat:@"/usr/bin/file -b \"%@\"", tmpPath];
				//NSLog(@"command: %@", command);
				NSString *fileResult = runCommandUsingPopen(command);
				if (fileResult == nil)
				{
					//NSLog(@"repeating command: %@", command);
					fileResult = runCommandUsingNSTask(command);
				}
				//NSLog(@"fileResult: %@", fileResult);
				
				if (fileResult != nil)
				{
					[selection setObject:fileResult forKey:KEY_ASSETS_KIND];
				}
				
				if ([ipaPath isEqual:ITUNES_ARTWORK] == YES)
				{
					NSString *fixedPath = [tmpPath stringByAppendingString:ITUNES_ARTWORK_EXT];
					if ([fileManager fileExistsAtPath:fixedPath] == NO)
					{
						[fileManager copyItemAtPath:tmpPath toPath:fixedPath error:&error];
					}
				}
				else if ([[tmpPath pathExtension] caseInsensitiveCompare:@"png"] == NSOrderedSame)
				{
					NSURL *url = [NSURL fileURLWithPath:tmpPath];
					PngInfo info;
					GetPngInfo((CFURLRef)url, &info);
					if (info.crushed == 1)
					{
						if (info.interlaced == 0)
						{
							[selection setObject:[NSString stringWithFormat:@"%@ %d x %d, %d-bit, non-interlaced", IPHONE_CRUSH, info.width, info.height, info.depth] forKey:KEY_ASSETS_KIND];
						}
						else
						{
							[selection setObject:[NSString stringWithFormat:@"%@ %d x %d, %d-bit, interlaced", IPHONE_CRUSH, info.width, info.height, info.depth] forKey:KEY_ASSETS_KIND];
						}
					}
				}
				else if (([[tmpPath pathExtension] caseInsensitiveCompare:@"pvr"] == NSOrderedSame) || ([[tmpPath pathExtension] caseInsensitiveCompare:@"pvrt"] == NSOrderedSame))
				{
					NSURL *url = [NSURL fileURLWithPath:tmpPath];
					
					PvrInfo info;
					GetPvrInfo((CFURLRef)url, &info);
					[selection setObject:[NSString stringWithFormat:@"%@ %d x %d, %d-bit, %d-mipmaps", PVR_TETURE, info.width, info.height, info.depth, info.mipmapsCount] forKey:KEY_ASSETS_KIND];
				}
			}
		}
		@catch (NSException *e)
		{
			[NSApp reportException:e];
		}
		@finally
		{
			[self->lock unlock];
		}
		
		[self performSelectorInBackground:@selector(getPreview:) withObject:selection];
	}
	else
	{
		[self setThumbnailIcon:nil];
		[self setPreviewTitle:nil];
		[self setPreviewUrl:nil];
		
		if ([[QLPreviewPanel sharedPreviewPanel] currentController] != nil)
		{
			[[QLPreviewPanel sharedPreviewPanel] reloadData];
			[[QLPreviewPanel sharedPreviewPanel] refreshCurrentPreviewItem];
		}
	}
	
	[self->delegate assetChanged:selection];
}

- (void)reset
{
	[self->arrayController setContent:nil];
}

- (void)finishLaunching
{
	[self->arrayController setDelegate:self];
}

- (void)willTerminate
{
	self->seed++;
}

- (void)setSortingMode:(NSUInteger)newMode
{
    self->sortingMode = newMode;
    NSSortDescriptor *sort = [[[NSSortDescriptor alloc] initWithKey:KEY_ASSETS_NAME ascending:(self->sortingMode == 0) selector:@selector(caseInsensitiveCompare:)] autorelease];
    [self->arrayController setSortDescriptors:[NSArray arrayWithObject:sort]];
}

# pragma mark -- Quick Look panel support --

- (NSURL *)previewItemURL
{
    return self->previewUrl;
}

- (NSString *)previewItemTitle
{
	return self->previewTitle;
}

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel;
{
    return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel
{
	[panel setDelegate:self];
	[panel setDataSource:self];
	[panel setFrame:NSMakeRect([panel frame].origin.x, [panel frame].origin.y, IPHONE_PREVIEW_WIDTH, IPHONE_PREVIEW_HEIGHT) display:YES];
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
	
}

# pragma mark -- Quick Look panel data source --

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
	if (self->previewTitle != nil)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
    return self;
}

# pragma mark -- Quick Look panel delegate --

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event
{
    return NO;
}

// This delegate method provides the rect on screen from which the panel will zoom.
- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item
{
	if ([[self->assetPreviewButton window] isVisible] == YES)
	{
		NSRect frame = [self->assetPreviewButton bounds];
		
		NSPoint pointInWindowCoordinates = [self->assetPreviewButton convertPoint:frame.origin toView:nil];
		NSPoint pointInScreenCoords = [[self->assetPreviewButton window] convertBaseToScreen:pointInWindowCoordinates];
		
		frame.origin = pointInScreenCoords;
		frame.origin.y -= frame.size.height;
		return frame;
	}
	else
	{
		return NSZeroRect;
	}
}

// This delegate method provides a transition image between the table view and the preview panel
- (id)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id <QLPreviewItem>)item contentRect:(NSRect *)contentRect
{
    return self->thumbnailIcon;
}

@end
