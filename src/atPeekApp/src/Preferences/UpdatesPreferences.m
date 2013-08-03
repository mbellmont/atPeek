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

#import "UpdatesPreferences.h"

#import <Quartz/Quartz.h>

@implementation UpdatesPreferences

- (NSImage *)imageForPreferenceNamed:(NSString *)prefName
{
    return [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/General.icns"];
    //return [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Sync.icns"];
}

- (BOOL)isResizable
{
	return NO;
}

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel;
{
    return NO;
}

- (void)initializeFromDefaults
{
	if ([self->pathControl URL] == nil)
	{
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
		if ([paths count] > 0)
		{
			[self->pathControl setURL:[NSURL fileURLWithPath:[paths objectAtIndex:0]]];
		}
		else
		{
			[self->pathControl setURL:[NSURL fileURLWithPath:[@"~/Desktop" stringByExpandingTildeInPath]]];
		}
	}
}

- (NSString*)getPath
{
	return [[self->pathControl URL] path];
}

- (IBAction)setPath:(id)sender
{
//	NSLog(@"setPath");
//    if (([QLPreviewPanel sharedPreviewPanelExists] == YES) && ([[QLPreviewPanel sharedPreviewPanel] isVisible] == YES))
//	{
//        [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
//    }
}

@end
