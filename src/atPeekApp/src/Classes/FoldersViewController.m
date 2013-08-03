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

#import "FoldersViewController.h"

@implementation FoldersOutlineView : NSOutlineView

@synthesize backgroundColor;

- (void)awakeFromNib
{
	//[self setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"BackgroundGreyIcon"]]];
}

#if 0
- (void)drawRect:(NSRect)dirtyRect
{
	NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(dirtyRect.origin.x, dirtyRect.origin.y, dirtyRect.size.width, dirtyRect.size.height)];
	[self->backgroundColor set];
	[path fill];
	
	[super drawRect:dirtyRect];
}
#endif

@end

@implementation FoldersTreeController : NSTreeController

@synthesize delegate;

- (BOOL)setSelectionIndexPaths:(NSArray *)indexPaths;
{
	BOOL changed = [super setSelectionIndexPaths:indexPaths];
	
	id object = nil;
	if ([[self selectedObjects] count] > 0)
	{
		object = [[self selectedObjects] objectAtIndex:0];
	}
	[self->delegate selectionChanged:object];
	
	return changed;
}

@end

@implementation FoldersViewController : NSViewController

@synthesize folders, sortingMode, tempFolder, assetsController, assetsFiles, assetsSizes, assetsIpa, assetsName;

#define KEY_FOLDER					@"folder"
#define KEY_PATH					@"path"
#define KEY_IS_LEAF					@"isLeaf"
#define KEY_CHILDREN				@"children"

#define FOLDER_DICTIONARY_SIZE		4

- (void)awakeFromNib
{
	[self setTempFolder:[NSTemporaryDirectory() stringByAppendingPathComponent:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]]];
}

- (void)selectionChanged:(id)selection
{
	[self->assetsController assetsChanged:[self->assetsFiles objectForKey:[selection objectForKey:KEY_PATH]] withSizes:self->assetsSizes forIpa:self->assetsIpa forApp:self->assetsName forFolder:@""];
}

- (void)filesChanged:(NSDictionary*)newFiles withSizes:(NSDictionary*)sizes forIpa:(NSString*)ipa forApp:(NSString*)name
{
	//NSLog(@"filesChanged:\n%@", newFiles);
	//NSLog(@"sizes: %@", sizes);
	@try
	{
		[self setAssetsFiles:newFiles];
		[self setAssetsSizes:sizes];
		[self setAssetsIpa:ipa];
		[self setAssetsName:name];
		
		NSArray *allFolders = [[newFiles allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		//NSLog(@"allFolders: %@", allFolders);
		if ([allFolders count] > 0)
		{
			NSMutableArray *list = [NSMutableArray arrayWithCapacity:1];
			
			int startIndex = 0;
			NSString *appPrefixPath = [allFolders objectAtIndex:startIndex];
			while (startIndex < ([allFolders count]-1))
			{
				NSRange range = [appPrefixPath rangeOfString:@".app"];
				if (range.location != NSNotFound)
				{
					break;
				}
				appPrefixPath = [allFolders objectAtIndex:++startIndex];
			}
			//NSLog(@"appPrefixPath: %@", appPrefixPath);
			
			for (int i=0; i<[allFolders count]; i++) // start in "Payload" folder
			{
				//NSLog(@"\n---------------------------------------------------------------");
				
				NSString *folderPath = [allFolders objectAtIndex:i];
				//NSLog(@"	folderPath: %@", folderPath);
				
				NSArray *relativeFolderPathComponents = [folderPath componentsSeparatedByString:@"/"];
				//NSLog(@"	relativeFolderPathComponents: %@", relativeFolderPathComponents);
				int count = [relativeFolderPathComponents count];
				//NSLog(@"	count: %d", count);
				
				NSString *relativeFolderPath = [folderPath lastPathComponent];
				while (count > 0)
				{
					relativeFolderPath = [@"   " stringByAppendingString:relativeFolderPath];
					count--;
				}
				
				//NSLog(@"	relativeFolderPath: %@", relativeFolderPath);
#if 1
				relativeFolderPath = [relativeFolderPath stringByAppendingFormat:@" (%d)", [[newFiles objectForKey:folderPath] count]];
#endif
				//NSLog(@"	relativeFolderPath: %@", relativeFolderPath);
				
				NSMutableDictionary *folderDictionary = [NSMutableDictionary dictionaryWithCapacity:FOLDER_DICTIONARY_SIZE];
				[folderDictionary setObject:folderPath forKey:KEY_PATH];
				[folderDictionary setObject:relativeFolderPath forKey:KEY_FOLDER];
				[folderDictionary setObject:[NSNumber numberWithBool:YES] forKey:KEY_IS_LEAF];
				//NSLog(@"folderDictionary: %@", folderDictionary);
				
				[list addObject:folderDictionary];
			}
			
			[self setFolders:list];
			
			[self->assetsController assetsChanged:[newFiles objectForKey:@"/"] withSizes:sizes forIpa:ipa forApp:name forFolder:@"/"];
		}
	}
	@catch (NSException *e)
	{
		[NSApp reportException:e];
	}
}

- (void)reset
{
	[self->treeController setContent:nil];
}

- (void)finishLaunching
{
	[self->treeController setDelegate:self];
}

- (void)willTerminate
{
	
}

- (void)setSortingMode:(NSUInteger)newMode
{
	[self->assetsController setSortingMode:newMode];
}

@end
