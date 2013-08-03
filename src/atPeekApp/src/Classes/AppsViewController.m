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

#import "AppsViewController.h"
#import "Utilities.h"
#import "RoundRect.h"

#define DEBUG_LIMIT_QUICK_READ_APPS		0

#define ITEM_VIEW_WIDTH					128
#define ITEM_VIEW_HEIGHT				95

@implementation AppsScrollView : NSScrollView

@synthesize backgroundColor;

-(void)awakeFromNib
{
	[self setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"BackgroundIcon"]]];
}

- (void)drawRect:(NSRect)dirtyRect
{
	NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(dirtyRect.origin.x, dirtyRect.origin.y, dirtyRect.size.width, dirtyRect.size.height)];
	[self->backgroundColor set];
	[path fill];
	
	[super drawRect:dirtyRect];
}

@end

@implementation AppsArrayController : NSArrayController

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

@implementation AppsViewController

@synthesize apps, sortingMode, drawerMode, tempFolder, defaultIcon, shineIcon, window, assetPreviewButton, foldersController, splitter, lock;

#define KEY_APP_IPA_PATH			@"ipaPath"
#define KEY_APP_NAME				@"name"
#define KEY_APP_SIZE				@"size"
#define KEY_APP_ICON				@"icon"
#define KEY_APP_FILES				@"files"
#define KEY_APP_SIZES				@"sizes"

#define KEY_ITUNES_ARTIST			@"artistName"
#define KEY_ITUNES_COPYRIGHT		@"copyright"
#define KEY_ITUNES_GENRE			@"genre"
#define KEY_ITUNES_NAME				@"itemName"
#define KEY_ITUNES_PRICE			@"priceDisplay"
#define KEY_ITUNES_PURCHASE_DATE	@"purchaseDate"
#define KEY_ITUNES_RELEASE_DATE		@"releaseDate"
#define KEY_ITUNES_CONTENT			@"content"
#define KEY_ITUNES_LABEL			@"label"
#define KEY_ITUNES_URL				@"url"
#define KEY_ITUNES_FILES_COUNT		@"fileCount"
#define KEY_ITUNES_FOLDERS_COUNT	@"folderCount"

#define APP_DICTIONARY_SIZE			18

- (void)setSearch:(NSSearchField*)search
{
	self->searchField = search;	
}

- (void)getFilesForApp:(NSMutableDictionary *)appDictionary
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *name = [appDictionary objectForKey:KEY_APP_NAME];
	//NSLog(@"name: %@", name);
	
	[self->progressPanelIndicator setIndeterminate:YES];
	[self->progressPanelIndicator startAnimation:self];
	[self->progressPanelLabel setStringValue:[NSString stringWithFormat:@"processing %@", name]];
	[NSApp beginSheet:self->progressPanel modalForWindow:self->window modalDelegate:self->window didEndSelector:nil contextInfo:nil];
    [self->progressPanel makeKeyAndOrderFront:self];
	
	if ([appDictionary objectForKey:KEY_APP_FILES] == nil)
	{
		int folderCount = 0;
		int fileCount = 0;
		for (int i=0; i<[self->apps count]; i++)
		{
			if (appDictionary == [self->apps objectAtIndex:i])
			{
				NSMutableDictionary *folders = [NSMutableDictionary dictionaryWithCapacity:1];
				//[folders setObject:[NSMutableArray arrayWithCapacity:1] forKey:@"/"];
				
				NSMutableDictionary *sizes = [NSMutableDictionary dictionaryWithCapacity:1];
				
				NSString *command = [NSString stringWithFormat:@"/usr/bin/unzip -qql \"%@\"", [appDictionary objectForKey:KEY_APP_IPA_PATH]];
				NSString *unzipResults = runCommandUsingNSTask(command);
				//NSLog(@"unzipResults:\n%@", unzipResults);
				
				NSArray *lines = [unzipResults componentsSeparatedByString:@"\n"];
				lines = [lines sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
				for (int j=0; j<[lines count]; j++)
				{
					NSString *line = [lines objectAtIndex:j];
					//NSLog(@"	line: %@", line);

					NSArray *components = [line componentsSeparatedByString:@"   "];
					//NSLog(@"	components: %@", components);
					
					NSString *filePath = [NSString stringWithFormat:@"/%@", [components objectAtIndex:[components count]-1]];
					//NSLog(@"	filePath: %@", filePath);
					if ([filePath length] > 0)
					{
						if ([filePath characterAtIndex:[filePath length]-1] == '/')
						{
							folderCount++;
							//NSLog(@"		folder: %@", filePath);
							
							[folders setObject:[NSMutableArray arrayWithCapacity:1] forKey:filePath];
						}
						else
						{
							fileCount++;
							//NSLog(@"		file: %@", filePath);
							
							NSString *folderPath = [filePath stringByDeletingLastPathComponent];
							if ([folderPath characterAtIndex:[folderPath length]-1] != '/')
							{
								folderPath = [folderPath stringByAppendingString:@"/"];
							}
							//NSLog(@"		folderPath: %@", folderPath);
							
							NSMutableArray *folder = [folders objectForKey:folderPath];
							//NSLog(@"		folder: %p", folder);
							
							NSString *relativeFilePath = [filePath substringFromIndex:1];
							//NSLog(@"		relativeFilePath: %p", relativeFilePath);
							[folder addObject:relativeFilePath];
							
							components = [line componentsSeparatedByString:@" "];
							int index = 0;
							while ([[components objectAtIndex:index] isEqual:@""] == YES)
							{
								index++;
							}
							[sizes setObject:[components objectAtIndex:index] forKey:relativeFilePath];
						}
					}
				}
				
				NSMutableDictionary *foldersSorted = [NSMutableDictionary dictionaryWithCapacity:1];
				NSEnumerator *foldersKeyEnumerator = [folders keyEnumerator];
				NSString *foldersKey = nil;
				while ((foldersKey = [foldersKeyEnumerator nextObject]) != nil)
				{
					NSArray *array = [folders objectForKey:foldersKey];
					NSArray *sortedArray = [array sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
					[foldersSorted setObject:sortedArray forKey:foldersKey];
				}
				
				//NSLog(@"folders: %@", folders);
				//NSLog(@"foldersSorted: %@", foldersSorted);
				//NSLog(@"sizes: %@", sizes);
				[appDictionary setObject:foldersSorted forKey:KEY_APP_FILES];
				[appDictionary setObject:sizes forKey:KEY_APP_SIZES];
				[appDictionary setObject:[NSNumber numberWithInt:fileCount] forKey:KEY_ITUNES_FILES_COUNT];
				[appDictionary setObject:[NSNumber numberWithInt:folderCount] forKey:KEY_ITUNES_FOLDERS_COUNT];
			}
		}
	}
	
	[self->foldersController filesChanged:[appDictionary objectForKey:KEY_APP_FILES] withSizes:[appDictionary objectForKey:KEY_APP_SIZES] forIpa:[appDictionary objectForKey:KEY_APP_IPA_PATH] forApp:name];
	
	[self->progressPanelIndicator setDoubleValue:[self->apps count]];
	[self->progressPanelIndicator stopAnimation:self];
	[NSApp endSheet:self->progressPanel];
	[self->progressPanel orderOut:self];
	
    [pool drain];
}

- (void)quickReadApp:(NSString *)name
{
	NSDateFormatter *outputFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[outputFormatter setDateStyle:NSDateFormatterLongStyle];
	
	NSDateFormatter *inputFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[inputFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];

	@try
	{
		for (int i=0; i<[self->apps count]; i++)
		{
			NSMutableDictionary *appDictionary = [self->apps objectAtIndex:i];
			if ([name isEqual:[appDictionary objectForKey:KEY_APP_NAME]] == YES)
			{
				//NSLog(@"appDictionary: %@", appDictionary);
				
				NSString *ipaPath = [appDictionary objectForKey:KEY_APP_IPA_PATH];
				//NSLog(@"ipaPath: %@", ipaPath);
				NSString *tmpFolder = [self->tempFolder stringByAppendingPathComponent:name];
				//NSLog(@"tmpFolder: %@", tmpFolder);
				
				NSError *error = nil;
				NSFileManager *fileManager = [NSFileManager defaultManager];
				if ([fileManager fileExistsAtPath:tmpFolder] == NO)
				{
					if ([fileManager createDirectoryAtPath:tmpFolder withIntermediateDirectories:YES attributes:nil error:&error] == NO)
					{
						NSLog(@"[NSFileManager createDirectoryAtPath:\"%@\"] failed!.", tmpFolder);
						[NSApp presentError:error];
						[NSApp terminate:self];
					}
				}
				
				{
					NSString *command = [NSString stringWithFormat:@"/usr/bin/unzip -qqo \"%@\" iTunesArtwork -d \"%@\"", ipaPath, tmpFolder];
					//NSLog(@"command: %@", command);
					runCommandUsingPopen(command);
					
					NSString *iTunesIconPath = [tmpFolder stringByAppendingPathComponent:@"iTunesArtwork"];
					//NSLog(@"iTunesIconPath: %@", iTunesIconPath);
					if ([fileManager fileExistsAtPath:iTunesIconPath] == NO)
					{
						//NSLog(@"repeating command: %@", command);
						runCommandUsingNSTask(command);
					}
					
					if ([fileManager fileExistsAtPath:iTunesIconPath] == YES)
					{
						command = [NSString stringWithFormat:@"/bin/chmod a+rw \"%@\"", iTunesIconPath];
						runCommandUsingPopen(command);
						
						NSImage *iTunesIcon = [[NSImage alloc] initWithContentsOfFile:iTunesIconPath];
						if (iTunesIcon == nil)
						{
							//NSLog(@"repeating command: %@", command);
							runCommandUsingNSTask(command);
							iTunesIcon = [[NSImage alloc] initWithContentsOfFile:iTunesIconPath];
						}
						
						//NSLog(@"iTunesIcon: %@", iTunesIcon);
						if (iTunesIcon != nil)
						{
							NSImage *iconWithCorners = [[NSImage alloc] initWithSize:[iTunesIcon size]];
							[iconWithCorners lockFocus];
							{
								float radius = 75;
								NSBezierPath *clipPath = [NSBezierPath bezierPathWithRoundRect:NSMakeRect(0, 0, [iTunesIcon size].width, [iTunesIcon size].height) xRadius:radius yRadius:radius];
								[clipPath addClip];
								
								[iTunesIcon drawAtPoint:NSMakePoint(0, 0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
							}
							[iconWithCorners unlockFocus];
							
							NSImage *iconWithShadow = [[NSImage alloc] initWithSize:[iTunesIcon size]];
							[iconWithShadow lockFocus];
							{
								float scale = 0.9;
								float x = ([iTunesIcon size].width - ([iTunesIcon size].width * scale)) / 2.0;
								float y = ([iTunesIcon size].height - ([iTunesIcon size].height * scale)) / 2.0;
								
								NSAffineTransform* xform = [NSAffineTransform transform];
								[xform scaleXBy:scale yBy:scale];
								[xform concat];
								
								NSShadow* shadow = [[NSShadow alloc] init];
								[shadow setShadowOffset:NSMakeSize(10.0, -10.0)];
								[shadow setShadowBlurRadius:5.0];
								[shadow setShadowColor:[[NSColor lightGrayColor] colorWithAlphaComponent:1.0]];
								[shadow set];
								
								[iconWithCorners drawAtPoint:NSMakePoint(x, y) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
								
								[shadow release];
							}
							[iconWithShadow unlockFocus];
							
							[appDictionary setObject:iconWithShadow forKey:KEY_APP_ICON];
							
							[iconWithShadow release];
							[iconWithCorners release];
							[iTunesIcon release];
						}
					}
				}
				
				{
					NSString *command = [NSString stringWithFormat:@"/usr/bin/unzip -qqo \"%@\" iTunesMetadata.plist -d \"%@\"", ipaPath, tmpFolder];
					//NSLog(@"command: %@", command);
					runCommandUsingPopen(command);
					
					NSString *iTunesInfoPath = [tmpFolder stringByAppendingPathComponent:@"iTunesMetadata.plist"];
					//NSLog(@"iTunesInfoPath: %@", iTunesInfoPath);
					if ([fileManager fileExistsAtPath:iTunesInfoPath] == NO)
					{
						//NSLog(@"repeating command: %@", command);
						runCommandUsingNSTask(command);
					}
					
					if ([fileManager fileExistsAtPath:iTunesInfoPath] == YES)
					{
						command = [NSString stringWithFormat:@"/bin/chmod a+rw \"%@\"", iTunesInfoPath];
						runCommandUsingPopen(command);
						
						NSDictionary *iTunesInfoPlist = [[[NSDictionary alloc] initWithContentsOfFile:iTunesInfoPath] autorelease];	
						if (iTunesInfoPlist == nil)
						{
							//NSLog(@"repeating command: %@", command);
							runCommandUsingNSTask(command);
							iTunesInfoPlist = [[[NSDictionary alloc] initWithContentsOfFile:iTunesInfoPath] autorelease];
						}
						
						//NSLog(@"iTunesInfoPlist: %@", iTunesInfoPlist);
						if (iTunesInfoPlist != nil)
						{
							if ([iTunesInfoPlist objectForKey:KEY_ITUNES_ARTIST] != nil)
							{
								[appDictionary setObject:[iTunesInfoPlist objectForKey:KEY_ITUNES_ARTIST] forKey:KEY_ITUNES_ARTIST];
							}
							if ([iTunesInfoPlist objectForKey:KEY_ITUNES_COPYRIGHT] != nil)
							{
								[appDictionary setObject:[iTunesInfoPlist objectForKey:KEY_ITUNES_COPYRIGHT] forKey:KEY_ITUNES_COPYRIGHT];
							}
							if ([iTunesInfoPlist objectForKey:KEY_ITUNES_GENRE] != nil)
							{
								[appDictionary setObject:[iTunesInfoPlist objectForKey:KEY_ITUNES_GENRE] forKey:KEY_ITUNES_GENRE];
							}
							if ([iTunesInfoPlist objectForKey:KEY_ITUNES_NAME] != nil)
							{
								[appDictionary setObject:[iTunesInfoPlist objectForKey:KEY_ITUNES_NAME] forKey:KEY_ITUNES_NAME];
							}
							if ([iTunesInfoPlist objectForKey:KEY_ITUNES_PRICE] != nil)
							{
								[appDictionary setObject:[iTunesInfoPlist objectForKey:KEY_ITUNES_PRICE] forKey:KEY_ITUNES_PRICE];
							}
							if ([iTunesInfoPlist objectForKey:KEY_ITUNES_PURCHASE_DATE] != nil)
							{
								NSDate *date = [iTunesInfoPlist objectForKey:KEY_ITUNES_PURCHASE_DATE];
								[appDictionary setObject:[outputFormatter stringFromDate:date] forKey:KEY_ITUNES_PURCHASE_DATE];
							}
							if ([iTunesInfoPlist objectForKey:KEY_ITUNES_RELEASE_DATE] != nil)
							{
								NSString *dateStr = [iTunesInfoPlist objectForKey:KEY_ITUNES_RELEASE_DATE];
								NSDate *date = [inputFormatter dateFromString:dateStr];
								if ([outputFormatter stringFromDate:date] != nil)
								{
									[appDictionary setObject:[outputFormatter stringFromDate:date] forKey:KEY_ITUNES_RELEASE_DATE];
								}
								else
								{
									[appDictionary setObject:dateStr forKey:KEY_ITUNES_RELEASE_DATE];
								}
							}
							if ([iTunesInfoPlist objectForKey:@"rating"] != nil)
							{
								NSDictionary *rating = [iTunesInfoPlist objectForKey:@"rating"];
								if ([rating objectForKey:KEY_ITUNES_CONTENT] != nil)
								{
									[appDictionary setObject:[rating objectForKey:KEY_ITUNES_CONTENT] forKey:KEY_ITUNES_CONTENT];
								}
								if ([rating objectForKey:KEY_ITUNES_LABEL] != nil)
								{
									[appDictionary setObject:[rating objectForKey:KEY_ITUNES_LABEL] forKey:KEY_ITUNES_LABEL];
								}
							}
							if ([iTunesInfoPlist objectForKey:KEY_ITUNES_URL] != nil)
							{
								[appDictionary setObject:[iTunesInfoPlist objectForKey:KEY_ITUNES_URL] forKey:KEY_ITUNES_URL];
							}
						}
					}
				}
			}
		}
	}
	@catch (NSException * e)
	{
		[NSApp reportException:e];
	}
}

- (void)quickReadApps:(NSMutableArray*)list
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	@try
	{
		[self->lock lock];
		
		[self performSelectorOnMainThread:@selector(setApps:) withObject:list waitUntilDone:YES];
		[list release];
		
		[self->progressPanelIndicator setIndeterminate:NO];
		[self->progressPanelIndicator setDoubleValue:0.0];
		[self->progressPanelIndicator setMinValue:0.0];
		[self->progressPanelIndicator setMaxValue:[self->apps count]];
		[NSApp beginSheet:self->progressPanel modalForWindow:self->window modalDelegate:self->window didEndSelector:nil contextInfo:nil];
		[self->progressPanel makeKeyAndOrderFront:self];
		
#if DEBUG_LIMIT_QUICK_READ_APPS
		for (int i=0; i<5; i++)
#else
		for (int i=0; i<[self->apps count]; i++)
#endif
		{
			NSDictionary *appDictionary = [self->apps objectAtIndex:i];
			
			//NSLog(@"loading %@ ...", [appDictionary objectForKey:KEY_APP_NAME]);
			[self->progressPanelIndicator setDoubleValue:i];
			[self->progressPanelLabel setStringValue:[NSString stringWithFormat:@"processing %@", [appDictionary objectForKey:KEY_APP_NAME]]];
			
			[self quickReadApp:[appDictionary objectForKey:KEY_APP_NAME]];
		}
		
		[self->progressPanelIndicator setDoubleValue:[self->apps count]];
		[NSApp endSheet:self->progressPanel];
		[self->progressPanel orderOut:self];
	}
	@catch (NSException * e)
	{
		[NSApp reportException:e];
	}
	@finally
	{
		[self->lock unlock];
	}
	
    [pool drain];
}

- (void)cleanupApps:(NSArray *)list
{
	[self->progressPanelIndicator setIndeterminate:NO];
	[self->progressPanelIndicator setDoubleValue:0.0];
	[self->progressPanelIndicator setMinValue:0.0];
	[self->progressPanelIndicator setMaxValue:[self->apps count]];
	[self->progressPanelLabel setStringValue:[NSString stringWithFormat:@"cleaning up ..."]];
	[NSApp beginSheet:self->progressPanel modalForWindow:self->window modalDelegate:self->window didEndSelector:nil contextInfo:nil];
    [self->progressPanel makeKeyAndOrderFront:self];
	
    NSFileManager *fileManager = [[NSFileManager defaultManager] retain];
	for (int i=0; i<[list count]; i++)
	{
		NSDictionary *appDictionary = [list objectAtIndex:i];
		
		NSString *name = [appDictionary objectForKey:KEY_APP_NAME];
		NSString *folderPath = [self->tempFolder stringByAppendingPathComponent:name];
		if ([fileManager fileExistsAtPath:folderPath] == YES)
		{
			//NSLog(@"cleaning up %@", [appDictionary objectForKey:KEY_APP_NAME]);
			[self->progressPanelIndicator setDoubleValue:i];
			[self->progressPanelLabel setStringValue:[NSString stringWithFormat:@"cleaning up %@", name]];
			
			[fileManager removeItemAtPath:folderPath error:nil];
		}
	}
	
	[self->progressPanelIndicator setDoubleValue:[self->apps count]];
	[NSApp endSheet:self->progressPanel];
    [self->progressPanel orderOut:self];
}

- (void)awakeFromNib
{
	self->firstClick = NO;
		
	[self->collectionView setMinItemSize:NSMakeSize(ITEM_VIEW_WIDTH, ITEM_VIEW_HEIGHT)];
	[self->collectionView setMaxItemSize:NSMakeSize(ITEM_VIEW_WIDTH, ITEM_VIEW_HEIGHT)];
	
	[self->progressPanelIndicator setUsesThreadedAnimation:YES];
    [self setSortingMode:0];
    [self setDrawerMode:0];
	[self setTempFolder:[NSTemporaryDirectory() stringByAppendingPathComponent:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]]];
	[self setDefaultIcon:[NSImage imageNamed:@"iAppIcon"]];
	[self setShineIcon:[NSImage imageNamed:@"iAppShineIcon"]];
	
	[self setLock:[[NSLock alloc] init]];
}

- (void)showPreviewForFirstTime
{
	[[QLPreviewPanel sharedPreviewPanel] updateController];
	[[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
	
	[window makeKeyAndOrderFront:nil];
}

- (void)waitUntilDrawerShown
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	while ([[self->assetPreviewButton window] isVisible] == NO)
	{
		usleep(1000);
	}
	[self performSelectorOnMainThread:@selector(showPreviewForFirstTime) withObject:nil waitUntilDone:NO];
	
    [pool drain];
}

- (void)selectionChanged:(id)selection
{
	[self->searchField setStringValue:@""];
	@try
	{
		[self->searchField textDidChange:[NSNotification notificationWithName:NSControlTextDidChangeNotification object:nil]];
	}
	@catch (NSException * e)
	{
		//NSLog(@"e: %@", e);
	}
	
	@try
	{
		if ((self->firstClick == NO) && (selection != nil))
		{
			self->firstClick = YES;
			
			[self setDrawerMode:1];
			[self->splitter setToggleMode:1];
			
			if ([[[self->collectionView window] title] length] == 6)
			{
				[self performSelectorInBackground:@selector(waitUntilDrawerShown) withObject:nil];
			}
		}
		
		if (selection != nil)
		{
			[self getFilesForApp:selection];
		}
	}
	@catch (NSException *e)
	{
		[NSApp reportException:e];
	}
}

- (void)openFolder:(NSString*)path
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *array = [fileManager contentsOfDirectoryAtPath:path error:nil];
	//NSLog(@"array: %@", array);

	NSMutableArray *list = [NSMutableArray arrayWithCapacity:[array count]];
	for (int i=0; i<[array count]; i++)
	{
		NSString *entry = [array objectAtIndex:i];
		if ([[entry pathExtension] isEqual:@"ipa"] == YES)
		{
			NSString *appIpaPath = [path stringByAppendingPathComponent:entry];
			//NSLog(@"appIpaPath: %@", appIpaPath);
			
			NSDictionary *appContainerAttributes = [fileManager attributesOfItemAtPath:appIpaPath error:nil];
			//NSLog(@"appContainerAttributes: %@", appContainerAttributes);
			
			NSString *appName = [[appIpaPath lastPathComponent] stringByDeletingPathExtension];
			//NSLog(@"appName: %@", appName);
			//NSLog(@"found: %@", appName);
			
			NSMutableDictionary *appDictionary = [NSMutableDictionary dictionaryWithCapacity:APP_DICTIONARY_SIZE];
			[appDictionary setObject:appIpaPath forKey:KEY_APP_IPA_PATH];
			[appDictionary setObject:appName forKey:KEY_APP_NAME];
			[appDictionary setObject:[NSString stringWithFormat:@"%s", utf8StringFor([[appContainerAttributes objectForKey:NSFileSize] doubleValue], BASE_10_KB, TWO_DIGIT)] forKey:KEY_APP_SIZE];
			[appDictionary setObject:self->defaultIcon forKey:KEY_APP_ICON];
			[appDictionary setObject:@"N/A" forKey:KEY_ITUNES_ARTIST];
			[appDictionary setObject:@"N/A" forKey:KEY_ITUNES_COPYRIGHT];
			[appDictionary setObject:@"N/A" forKey:KEY_ITUNES_GENRE];
			[appDictionary setObject:@"N/A" forKey:KEY_ITUNES_NAME];
			[appDictionary setObject:@"N/A" forKey:KEY_ITUNES_PRICE];
			[appDictionary setObject:@"N/A" forKey:KEY_ITUNES_PURCHASE_DATE];
			[appDictionary setObject:@"N/A" forKey:KEY_ITUNES_RELEASE_DATE];
			[appDictionary setObject:@"N/A" forKey:KEY_ITUNES_CONTENT];
			[appDictionary setObject:@"N/A" forKey:KEY_ITUNES_LABEL];
			[appDictionary setObject:@"N/A" forKey:KEY_ITUNES_URL];
			[appDictionary setObject:@"N/A" forKey:KEY_ITUNES_FILES_COUNT];
			[appDictionary setObject:@"N/A" forKey:KEY_ITUNES_FOLDERS_COUNT];
			//NSLog(@"appDictionary: %@", appDictionary);
			
			[list addObject:appDictionary];
		}
	}
		
	[self performSelectorInBackground:@selector(quickReadApps:) withObject:[list retain]];
}

- (void)reset
{
	
}

- (void)finishLaunching
{
	[self->arrayController setDelegate:self];
	
	NSError *error = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager createDirectoryAtPath:self->tempFolder withIntermediateDirectories:YES attributes:nil error:&error] == NO)
	{
		//NSLog(@"[NSFileManager createDirectoryAtPath:\"%@\"] failed!.", self->tempFolder);
		[NSApp presentError:error];
		[NSApp terminate:self];
	}
	//NSLog(@"self->tempFolder: %@", self->tempFolder);
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSMusicDirectory, NSUserDomainMask, YES);
	//NSLog(@"paths: %@", paths);
	
	NSString *MusicFolder = [paths objectAtIndex:0];
	//NSLog(@"MusicFolder: %@", MusicFolder);
	
	NSString *iTunesFolder = [MusicFolder stringByAppendingPathComponent:@"iTunes"];
	//NSLog(@"iTunesFolder: %@", iTunesFolder);
	
	NSString *MobileApplicationsFolder = [iTunesFolder stringByAppendingPathComponent:@"Mobile Applications"];
	//NSLog(@"MobileApplicationsFolder: %@", MobileApplicationsFolder);
	
	NSString *answer = runCommandUsingPopen([NSString stringWithFormat:@"find \"%@\" | grep ipa", MobileApplicationsFolder]);
	//NSLog(@"answer1: %@", answer);
	if (answer != nil)
	{
		[self openFolder:MobileApplicationsFolder];
	}
	else
	{
		MobileApplicationsFolder = [iTunesFolder stringByAppendingPathComponent:@"Media/Mobile Applications"];
		answer = runCommandUsingPopen([NSString stringWithFormat:@"find \"%@\" | grep ipa", MobileApplicationsFolder]);
		//NSLog(@"answer2: %@", answer);
		if (answer != nil)
		{
			[self openFolder:MobileApplicationsFolder];
		}
		else
		{
			NSString *answer = runCommandUsingPopen([NSString stringWithFormat:@"find \"%@\" | grep ipa", iTunesFolder]);
			//NSLog(@"answer3: %@", answer);
			if (answer != nil)
			{
				NSArray *array = [answer componentsSeparatedByString:@"\n"];
				if ([array count] > 0)
				{
					NSString *path = [array objectAtIndex:0];
					
					MobileApplicationsFolder = [path stringByDeletingLastPathComponent];
					if (MobileApplicationsFolder != nil)
					{
						[self openFolder:MobileApplicationsFolder];
					}
				}
			}
		}
	}
}

- (void)willTerminate
{
	[self cleanupApps:self->apps];
	
    NSFileManager *fileManager = [NSFileManager defaultManager];
	if (([fileManager fileExistsAtPath:self->tempFolder] == YES) && ([fileManager removeItemAtPath:self->tempFolder error:nil] == NO))
	{
		NSLog(@"[NSFileManager removeItemAtPath:\"%@\"] failed!.", self->tempFolder);
	}
}

- (void)setSortingMode:(NSUInteger)newMode
{
    self->sortingMode = newMode;
    NSSortDescriptor *sort = [[[NSSortDescriptor alloc] initWithKey:KEY_APP_NAME ascending:(self->sortingMode == 0) selector:@selector(caseInsensitiveCompare:)] autorelease];
    [self->arrayController setSortDescriptors:[NSArray arrayWithObject:sort]];
	
    [self->foldersController setSortingMode:newMode];
}

- (void)setDrawerMode:(NSUInteger)newMode
{
    self->drawerMode = newMode;
}

@end
