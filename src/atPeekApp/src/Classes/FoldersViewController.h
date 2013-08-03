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

#import <Cocoa/Cocoa.h>

#import "AssetsViewController.h"

@interface FoldersOutlineView : NSOutlineView
{
	NSColor							*backgroundColor;
}

@property(retain) NSColor *backgroundColor;

@end

@interface FoldersTreeController : NSTreeController
{
	id								delegate;
}

@property(retain) id delegate;

@end

@interface FoldersViewController : NSViewController
{
	IBOutlet FoldersOutlineView		*outlineView;
	IBOutlet FoldersTreeController	*treeController;
	
    NSMutableArray					*folders;
    NSUInteger						sortingMode;
	NSString						*tempFolder;
	AssetsViewController			*assetsController;
	NSDictionary					*assetsFiles;
	NSDictionary					*assetsSizes;
	NSString						*assetsIpa;
	NSString						*assetsName;
}

@property(assign) NSMutableArray *folders;
@property(assign) NSUInteger sortingMode;
@property(retain) NSString *tempFolder;
@property(assign) AssetsViewController *assetsController;
@property(retain) NSDictionary *assetsFiles;
@property(retain) NSDictionary *assetsSizes;
@property(retain) NSString *assetsIpa;
@property(retain) NSString *assetsName;

- (void)selectionChanged:(id)selection;
- (void)filesChanged:(NSDictionary*)newFiles withSizes:(NSDictionary*)sizes forIpa:(NSString*)ipa forApp:(NSString*)name;
- (void)reset;
- (void)finishLaunching;
- (void)willTerminate;

@end
