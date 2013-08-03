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

#import "AssetChangedDelegate.h"
#import "AppsViewController.h"
#import "FoldersViewController.h"
#import "AssetsViewController.h"
#import "ToggleableSplitView.h"

@interface MainWindow : NSWindow

@end

@interface MyWindowController : NSWindowController <NSApplicationDelegate, NSWindowDelegate, AssetChangedDelegate>
{
    IBOutlet NSPanel				*progressPanel;
    IBOutlet NSTextField			*progressPanelLabel;
    IBOutlet NSProgressIndicator	*progressPanelIndicator;
	
    IBOutlet NSView					*topTargetView;
    IBOutlet NSView					*bottomLeftTargetView;
    IBOutlet NSView					*bottomRightTargetView;
	
    IBOutlet NSView					*appDetailView;
    IBOutlet NSButton				*assetPreviewButton;
    IBOutlet ToggleableSplitView	*splitter;
	
    IBOutlet NSPanel				*licenseWindow;
    IBOutlet NSTextView				*licenseView;
    IBOutlet NSButton				*licenseAcceptButton;
    IBOutlet NSButton				*licenseDeclineButton;
	
    IBOutlet NSTextField			*licenseEmailTextField;
    IBOutlet NSTextField			*licenseKeyTextField;
	
    IBOutlet NSButton				*exportAssetButton;
    IBOutlet NSButton				*exportFolderButton;
	
	IBOutlet NSSearchField			*searchField;
	IBOutlet NSSearchFieldCell		*searchFieldCell;
	
    AppsViewController				*appsViewController;
    FoldersViewController			*foldersViewController;
    AssetsViewController			*assetsViewController;
	
    NSDictionary					*defaults;
    NSUserDefaults					*preferences;
    NSString						*defaultExportFolder;
	
	NSDictionary					*asset;
}

@property(retain) NSString *defaultExportFolder;
@property(retain) NSDictionary *asset;

- (IBAction)open:(id)sender;
- (IBAction)openItunes:(id)sender;
- (IBAction)openReadMe:(id)sender;
- (IBAction)openPreferences:(id)sender;
- (IBAction)togglePreviewPanel:(id)sender;
- (IBAction)launchUrl:(id)sender;
- (IBAction)acceptLicense:(id)sender;
- (IBAction)declineLicense:(id)sender;
- (IBAction)registerLicense:(id)sender;
- (IBAction)buyLicense:(id)sender;
- (IBAction)exportAsset:(id)sender;
- (IBAction)exportFolder:(id)sender;

- (void)assetChanged:(id)selection;

@end
