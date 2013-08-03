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

#import "FoldersViewController.h"
#import "ToggleableSplitView.h"

@interface AppsScrollView : NSScrollView
{
	NSColor							*backgroundColor;
}

@property(retain) NSColor *backgroundColor;

@end

@interface AppsArrayController : NSArrayController
{
	id								delegate;
}

@property(retain) id delegate;

@end

@interface AppsViewController : NSViewController <NSCollectionViewDelegate>
{
    IBOutlet NSCollectionView		*collectionView;
    IBOutlet AppsArrayController	*arrayController;
	
    IBOutlet NSPanel				*progressPanel;
    IBOutlet NSTextField			*progressPanelLabel;
    IBOutlet NSProgressIndicator	*progressPanelIndicator;
	
	NSSearchField					*searchField;
	
    NSMutableArray					*apps;
    NSUInteger						sortingMode;
    NSUInteger						drawerMode;
	NSString						*tempFolder;
	NSImage							*defaultIcon;
	NSImage							*shineIcon;
	
	NSWindow						*window;
	NSButton						*assetPreviewButton;
	FoldersViewController			*foldersController;
	ToggleableSplitView				*splitter;
	
	NSLock							*lock;
	
	BOOL							firstClick;
}

@property(assign) NSMutableArray *apps;
@property(assign) NSUInteger sortingMode;
@property(assign) NSUInteger drawerMode;
@property(retain) NSString *tempFolder;
@property(retain) NSImage *defaultIcon;
@property(retain) NSImage *shineIcon;
@property(assign) NSWindow *window;
@property(assign) NSButton *assetPreviewButton;
@property(assign) FoldersViewController *foldersController;
@property(assign) ToggleableSplitView *splitter;
@property(assign) NSLock *lock;

- (void)setSearch:(NSSearchField*)search;
- (void)selectionChanged:(id)selection;
- (void)reset;
- (void)openFolder:(NSString*)path;
- (void)finishLaunching;
- (void)willTerminate;

@end
