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
#import <Quartz/Quartz.h>

#import "AssetChangedDelegate.h"

@interface AssetsNSBox : NSBox

@end

@interface AssetsScrollView : NSScrollView

@end

@interface AssetsArrayController : NSArrayController
{
	id								delegate;
}

@property(retain) id delegate;

@end

@interface AssetsViewController : NSViewController <NSCollectionViewDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate, QLPreviewItem>
{
    IBOutlet NSCollectionView		*collectionView;
    IBOutlet AssetsArrayController	*arrayController;
	
	id								delegate;
	NSButton						*assetPreviewButton;
    NSMutableArray					*assets;
    NSUInteger						sortingMode;
	NSString						*tempFolder;
	NSImage							*defaultIcon;
	NSString						*ipaFile;
	
	NSImage							*thumbnailIcon;
	NSString						*previewTitle;
	NSURL							*previewUrl;
	
	NSLock							*lock;
	UInt32							seed;
	UInt32							seedPreview;
}

@property(retain) id delegate;
@property(assign) NSButton *assetPreviewButton;
@property(assign) NSMutableArray *assets;
@property(assign) NSUInteger sortingMode;
@property(retain) NSString *tempFolder;
@property(assign) NSImage *defaultIcon;
@property(retain) NSString *ipaFile;
@property(retain) NSImage *thumbnailIcon;
@property(retain) NSString *previewTitle;
@property(retain) NSURL *previewUrl;
@property(assign) NSLock *lock;

- (void)selectionChanged:(id)selection;
- (void)assetsChanged:(NSArray*)newAssets withSizes:(NSDictionary*)sizes forIpa:(NSString*)ipa forApp:(NSString*)name forFolder:(NSString*)folder;
- (void)reset;
- (void)finishLaunching;
- (void)willTerminate;

@end
