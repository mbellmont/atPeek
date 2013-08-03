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

#import "MyWindowController.h"
#import "AppPreferences.h"
#import "NSPreferences.h"
#import "Utilities.h"
#import "SizzeledString.h"
#import "UncrushPng.h"
#import "UncrushPvr.h"

#import "Sparkle/Sparkle.h"

#define LICENSE_ACCEPTED_KEY		@"License Accepted"
#define LICENSE_TEXT_NAME			@"License"

#define BUY_ATPEEK_URL				@"http://www.atpurpose.com/atPeek/buy/"

@implementation MainWindow

- (void)sendEvent:(NSEvent *)event
{
	if (([event type] == NSKeyDown) && ([event keyCode] == 49))
	{
		[[self delegate] performSelector:@selector(togglePreviewPanel:) withObject:nil];
	}
	else
	{
		[super sendEvent:event];
	}
}

@end

@implementation MyWindowController

@synthesize defaultExportFolder, asset;

- (void)awakeFromNib
{
	[NSPreferences setDefaultPreferencesClass:[AppPreferences class]];
	
    [NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	
	if ([[SUUpdater sharedUpdater] automaticallyChecksForUpdates] == YES)
	{
		[[SUUpdater sharedUpdater] checkForUpdatesInBackground];
	}
	
	{
		[self willChangeValueForKey:@"appsViewController"];
		self->appsViewController = [[AppsViewController alloc] initWithNibName:@"AppsCollection" bundle:nil];
		[self didChangeValueForKey:@"appsViewController"];
		
		[self->topTargetView addSubview:[self->appsViewController view]];
		[[self->appsViewController view] setFrame:[self->topTargetView bounds]];
	}
	
	{
		[self willChangeValueForKey:@"foldersViewController"];
		self->foldersViewController = [[FoldersViewController alloc] initWithNibName:@"FoldersTree" bundle:nil];
		[self didChangeValueForKey:@"foldersViewController"];
		
		[self->bottomLeftTargetView addSubview:[self->foldersViewController view]];
		[[self->foldersViewController view] setFrame:[self->bottomLeftTargetView bounds]];
	}
	
	{
		[self willChangeValueForKey:@"assetsViewController"];
		self->assetsViewController = [[AssetsViewController alloc] initWithNibName:@"AssetsCollection" bundle:nil];
		[self didChangeValueForKey:@"assetsViewController"];
		
		[self->bottomRightTargetView addSubview:[self->assetsViewController view]];
		[[self->assetsViewController view] setFrame:[self->bottomRightTargetView bounds]];
	}
	
	[self->appsViewController setSearch:self->searchField];
	[self->appsViewController setWindow:[self window]];
	[self->appsViewController setSplitter:self->splitter];
	[self->appsViewController setAssetPreviewButton:self->assetPreviewButton];
	
	[self->appsViewController setFoldersController:self->foldersViewController];
	[self->foldersViewController setAssetsController:self->assetsViewController];
	
	[self->assetsViewController setAssetPreviewButton:self->assetPreviewButton];
	[self->assetsViewController setDelegate:self];
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0)
	{
		[self setDefaultExportFolder:[paths objectAtIndex:0]];
	}
	else
	{
		[self setDefaultExportFolder:[@"~/Desktop" stringByExpandingTildeInPath]];
	}
	
	[[self window] setNextResponder:self->assetsViewController];
	[[QLPreviewPanel sharedPreviewPanel] updateController];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[self->appsViewController willTerminate];
	[self->foldersViewController willTerminate];
	[self->assetsViewController willTerminate];
}

- (void)assertLicenseAccepted
{
    NSNumber *number = (NSNumber *)[self->preferences objectForKey:LICENSE_ACCEPTED_KEY];
    if ([number boolValue] == NO)
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:LICENSE_TEXT_NAME ofType:@"rtf"];
        
        [self->licenseView readRTFDFromFile:path];
        [self->licenseView setEditable:NO];
        [NSApp runModalForWindow:self->licenseWindow];
    }
}

- (BOOL)assertLicenseKey
{
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	self->defaults = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"]] retain];
	self->preferences = [[NSUserDefaults standardUserDefaults] retain];
	[self->preferences registerDefaults:self->defaults];
	
	[self assertLicenseAccepted];
	[self assertLicenseKey];
	
    [[self window] setTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];
    [self->exportAssetButton setEnabled:YES];
    [self->exportFolderButton setEnabled:YES];
	
	[[self window] setShowsResizeIndicator:YES];
    [[self window] makeKeyAndOrderFront:self];
	
	[self->appsViewController finishLaunching];
	[self->foldersViewController finishLaunching];
	[self->assetsViewController finishLaunching];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return NO;
}

- (void)windowWillClose:(NSNotification *)notification
{
	[NSApp hide:nil];
	[NSApp terminate:nil];
}

BOOL needToShowPreview;
- (void)selectFolderPanelDidEnd:(NSOpenPanel*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
    if (returnCode == 1)
    {
		NSString *path = [[sheet filename] retain];
		[sheet orderOut:self];
		
		[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:path]];
		
		[self->appsViewController reset];
		[self->foldersViewController reset];
		[self->assetsViewController reset];
		[self->appsViewController openFolder:path];
    }
	
//	if (needToShowPreview == YES)
//	{
//		[[QLPreviewPanel sharedPreviewPanel] updateController];
//		[[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
//		
//		[[self window] makeKeyAndOrderFront:self];
//	}
}

- (IBAction)open:(id)sender
{
    if (([QLPreviewPanel sharedPreviewPanelExists] == YES) && ([[QLPreviewPanel sharedPreviewPanel] isVisible] == YES))
	{
		needToShowPreview = YES;
        [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
    }
	
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:NO];
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseDirectories:YES];
	[panel setCanCreateDirectories:NO];
	[panel setPrompt:@"Select"];
	
	[panel beginSheetForDirectory:nil file:nil types:nil modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(selectFolderPanelDidEnd: returnCode: contextInfo:) contextInfo:nil];
}

- (IBAction)openItunes:(id)sender;
{
	[self->appsViewController finishLaunching];
	[self->appsViewController reset];
	[self->foldersViewController reset];
	[self->assetsViewController reset];
}

- (IBAction)openReadMe:(id)sender
{
	NSString* fullPath = [[NSBundle mainBundle] pathForResource:@"FAQ" ofType:@"rtf"];
	[[NSWorkspace sharedWorkspace] openFile:fullPath];
}

- (IBAction)openPreferences:(id)sender
{
	[[NSPreferences sharedPreferences] showPreferencesPanel];
    
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)togglePreviewPanel:(id)sender
{
    if ([[QLPreviewPanel sharedPreviewPanel] isVisible] == YES)
	{
		if ([QLPreviewPanel sharedPreviewPanelExists] == YES)
		{
			[[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
		}
    }
	else
	{
		[[QLPreviewPanel sharedPreviewPanel] updateController];
        [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
		
		[[QLPreviewPanel sharedPreviewPanel] reloadData];
		[[QLPreviewPanel sharedPreviewPanel] refreshCurrentPreviewItem];
		
		[[self window] makeKeyAndOrderFront:self];
    }
}

- (IBAction)launchUrl:(id)sender
{
	//[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[sender toolTip]]];
}

- (IBAction)acceptLicense:(id)sender
{
    [NSApp stopModal];
    
    [self->licenseWindow orderOut:self];
    [self->licenseWindow close];
    
    [self->preferences setValue:[NSNumber numberWithBool:YES] forKey:LICENSE_ACCEPTED_KEY];
    [self->preferences synchronize];
	
	[[self window] center];
}

- (IBAction)declineLicense:(id)sender
{
    [[NSApplication sharedApplication] terminate: self];
}

- (IBAction)registerLicense:(id)sender
{
	[[sender window] performClose:sender];
	
	NSString *licenseKey = [self->licenseKeyTextField stringValue];
	NSString *licenseEmail = [self->licenseEmailTextField stringValue];
    // always validate
	{
		[[self window] setTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];

		[self->exportAssetButton setEnabled:YES];
		[self->exportFolderButton setEnabled:YES];
        
		[self->preferences synchronize];
		
		if ([[QLPreviewPanel sharedPreviewPanel] isVisible] == NO)
		{
			[[QLPreviewPanel sharedPreviewPanel] updateController];

			if ([[QLPreviewPanel sharedPreviewPanel] currentController] != nil)
			{
				[[QLPreviewPanel sharedPreviewPanel] reloadData];
				[[QLPreviewPanel sharedPreviewPanel] refreshCurrentPreviewItem];
			}
			
			[[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
		}
		else
		{
			if ([[QLPreviewPanel sharedPreviewPanel] currentController] != nil)
			{
				[[QLPreviewPanel sharedPreviewPanel] reloadData];
				[[QLPreviewPanel sharedPreviewPanel] refreshCurrentPreviewItem];
			}
		}
	}
}

- (IBAction)buyLicense:(id)sender
{

}

- (NSString*)getExportPath
{
	NSString *exportPath = nil;
    
    // always validate
	{
		exportPath = [[NSPreferences sharedPreferences] getPath];
		if (exportPath == nil)
		{
			exportPath = self->defaultExportFolder;
		}
	}
	
	return exportPath;
}

- (IBAction)exportAsset:(id)sender
{
	@try
	{
		NSString *exportPath = [self getExportPath];
		if ((exportPath != nil) && (self->asset != nil))
		{
			//NSLog(@"exportPath: %@", exportPath);
			//NSLog(@"self->asset: %@", self->asset);
			
			NSString *srcPath = [asset objectForKey:@"tmpPath"];
			//NSLog(@"srcPath: %@", srcPath);
			
			NSString *name = [asset objectForKey:@"name"];
			if ([name isEqual:@"iTunesArtwork"] == YES)
			{
				name = [name stringByAppendingString:@".jpg"];
			}
			NSString *dstPath = [exportPath stringByAppendingPathComponent:name];
			//NSLog(@"dstPath: %@", dstPath);
			
			NSError *error = nil;
			NSFileManager *fileManager = [NSFileManager defaultManager];
			[fileManager copyItemAtPath:srcPath toPath:dstPath error:&error];
			if (error != nil)
			{
				[NSApp presentError:error];
			}
			else if ([[dstPath pathExtension] caseInsensitiveCompare:@"png"] == NSOrderedSame)
			{
				//NSLog(@"	fixing: %@", dstPath);
				FixPngImageIfNeeded((char*)[dstPath UTF8String], (char*)[[dstPath uncrushedWithExt:@"Png.png"] UTF8String]);
			}
			else if (([[dstPath pathExtension] caseInsensitiveCompare:@"pvr"] == NSOrderedSame) ||
					 ([[dstPath pathExtension] caseInsensitiveCompare:@"pvrt"] == NSOrderedSame))
			{
				//NSLog(@"	fixing: %@", dstPath);
				FixPvrImageIfNeeded((char*)[dstPath UTF8String], (char*)[[dstPath uncrushedWithExt:@"Pvr.png"] UTF8String]);
			}
		}
	}
	@catch (NSException *e)
	{
		[NSApp reportException:e];
	}
}

- (void)exportFolderInBackground
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	@try
	{
		NSString *exportPath = [self getExportPath];
		if ((exportPath != nil) && (self->asset != nil))
		{
			//NSLog(@"exportPath: %@", exportPath);
			//NSLog(@"self->asset: %@", self->asset);
			
			NSString *srcPath = [asset objectForKey:@"ipaFile"];
			//NSLog(@"srcPath: %@", srcPath);
			
			NSString *ipaFolder = [asset objectForKey:@"ipaFolder"];
			//NSLog(@"ipaFolder: %@", ipaFolder);
			
			NSString *entry = [ipaFolder stringByAppendingString:@"/"];
			//NSLog(@"entry: %@", entry);
			
			NSString *dstPath = [exportPath stringByAppendingPathComponent:[ipaFolder lastPathComponent]];
			//NSLog(@"dstPath: %@", dstPath);
			
			NSFileManager *fileManager = [NSFileManager defaultManager];
			if ([entry isEqual:@"/"] == NO)
			{
				NSString *command = [NSString stringWithFormat:@"/usr/bin/unzip -qqo \"%@\" \"%@*\" -d \"%@\"", srcPath, entry, @"/tmp/"];
				//NSLog(@"command: %@", command);
				runCommandUsingNSTask(command);
				
				srcPath = [NSString stringWithFormat:@"/tmp/%@", entry];
				//NSLog(@"	srcPath: %@", srcPath);
				//NSLog(@"	dstPath: %@", dstPath);
				
				NSError *error = nil;
				[fileManager moveItemAtPath:srcPath toPath:dstPath error:&error];
				if (error != nil)
				{
					[NSApp presentError:error];
				}
				
				NSArray *components = [entry componentsSeparatedByString:@"/"];
				if ([components count] > 0)
				{
					[fileManager removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@", [components objectAtIndex:0]] error:&error];
				}
			}
			else
			{
				dstPath = [dstPath stringByAppendingPathComponent:[[srcPath lastPathComponent] stringByDeletingPathExtension]];
				//NSLog(@"dstPath: %@", dstPath);
				
				NSString *command = [NSString stringWithFormat:@"/usr/bin/unzip -qqo \"%@\" -d \"%@\"", srcPath, dstPath];
				//NSLog(@"command: %@", command);
				runCommandUsingNSTask(command);
			}
			
			//NSLog(@"	dstPath: %@", dstPath);
			int nrOfFiles = 0;
			NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:dstPath];
			NSString *file = nil;
			while (file = [enumerator nextObject])
			{
				nrOfFiles++;
			}
			
			[self->progressPanelIndicator setIndeterminate:NO];
			[self->progressPanelIndicator setDoubleValue:0];
			[self->progressPanelIndicator setMaxValue:nrOfFiles];
			
			enumerator = [fileManager enumeratorAtPath:dstPath];
			file = nil;
			while (file = [enumerator nextObject])
			{
				NSString *fullPath = [dstPath stringByAppendingPathComponent:file];
				//NSLog(@"fullPath: %@", fullPath);
				
				[self->progressPanelIndicator incrementBy:1];
				[self->progressPanelLabel setStringValue:[NSString stringWithFormat:@"processing %@", [file lastPathComponent]]];
				//[self->progressPanel update];

				NSDictionary *attributes = [fileManager attributesOfItemAtPath:fullPath error:nil];
				//NSLog(@"attributes:\n%@", attributes);
				if ([attributes filePosixPermissions] == 0)
				{
					NSString *command = [NSString stringWithFormat:@"/bin/chmod a+rw \"%@\"", fullPath];
					runCommandUsingNSTask(command);
				}
				
				if ([[fullPath pathExtension] caseInsensitiveCompare:@"png"] == NSOrderedSame)
				{
					//NSLog(@"	fixing: %@", fullPath);
					FixPngImageIfNeeded((char*)[fullPath UTF8String], (char*)[[fullPath uncrushedWithExt:@"Png.png"] UTF8String]);
				}
				else if (([[fullPath pathExtension] caseInsensitiveCompare:@"pvr"] == NSOrderedSame) ||
							([[fullPath pathExtension] caseInsensitiveCompare:@"pvrt"] == NSOrderedSame))
				{
					//NSLog(@"	fixing: %@", fullPath);
					FixPvrImageIfNeeded((char*)[fullPath UTF8String], (char*)[[fullPath uncrushedWithExt:@"Pvr.png"] UTF8String]);
				}
			}
		}
	}
	@catch (NSException *e)
	{
		[NSApp reportException:e];
	}
	
	[self->progressPanelIndicator stopAnimation:self];
	[NSApp endSheet:self->progressPanel];
	[self->progressPanel orderOut:self];
	
	[self->exportAssetButton setEnabled:YES];
	[self->exportFolderButton setEnabled:YES];
	
	[pool drain];
}

- (IBAction)exportFolder:(id)sender
{
	[self->exportAssetButton setEnabled:NO];
	[self->exportFolderButton setEnabled:NO];
	
	[self->progressPanelIndicator setIndeterminate:YES];
	[self->progressPanelLabel setStringValue:[NSString stringWithFormat:@"processing..."]];
	[self->progressPanelIndicator startAnimation:self];
	[NSApp beginSheet:self->progressPanel modalForWindow:[self window] modalDelegate:[self window] didEndSelector:nil contextInfo:nil];
	[self->progressPanel makeKeyAndOrderFront:self];
	
	[self performSelectorInBackground:@selector(exportFolderInBackground) withObject:nil];
}

- (void)assetChanged:(id)selection
{
	if (selection != nil)
	{
		[self->exportAssetButton setHidden:NO];
		[self->exportFolderButton setHidden:NO];
		if ([self->exportAssetButton isEnabled] == YES)
		{
			[self setAsset:selection];
		}
		else
		{
			[self setAsset:nil];
		}
	}
	else
	{
		[self->exportAssetButton setHidden:YES];
		[self->exportFolderButton setHidden:YES];
		[self setAsset:nil];
	}
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	[self->appsViewController reset];
	[self->foldersViewController reset];
	[self->assetsViewController reset];
	[self->appsViewController openFolder:filename];
	
	return YES;
}

@end
