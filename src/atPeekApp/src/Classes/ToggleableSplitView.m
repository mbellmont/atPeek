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

#import "ToggleableSplitView.h"

@implementation ToggleableSplitView

@synthesize toggleMode;

- (void)awakeFromNib
{
	[self setDelegate:self];
	[self setToggleMode:0];
}

- (void)setToggleMode:(NSUInteger)newMode
{
    self->toggleMode = newMode;
	if (self->toggleMode == 1)
	{
		[self setPosition:([[self->topView superview] frame].size.height/2.0f) ofDividerAtIndex:0];
	}
	else if (([self isSubviewCollapsed:self->bottomView] == NO) && ([self->bottomView frame].size.height > 0.0))
	{
		[self setPosition:([[self->topView superview] frame].size.height) ofDividerAtIndex:0];
	}
	
	NSArray *subviews = [self->topView subviews];
	if ([subviews count] > 0)
	{
		NSScrollView *scrollView = [subviews objectAtIndex:0];
		NSCollectionView *collectionView = [scrollView documentView];
		NSIndexSet *selectionIndexes = [collectionView selectionIndexes];
		if ([selectionIndexes count] > 0)
		{
			NSArray *collectionSubviews = [collectionView subviews];
			if ([selectionIndexes count] > 0)
			{
				NSView *selectedView = [collectionSubviews objectAtIndex:[selectionIndexes firstIndex]];
				NSRect selectedRect = [selectedView frame];
				selectedRect.origin.x -= selectedRect.size.width/2.0f;
				selectedRect.origin.y -= selectedRect.size.height/2.0f;
				selectedRect.size.width *= 2.0f;
				selectedRect.size.height *= 2.0f;
				[collectionView scrollRectToVisible:selectedRect];
			}
			else
			{
				[collectionView scrollPoint:NSMakePoint(0, 0)];
			}
		}
		else
		{
			[collectionView scrollPoint:NSMakePoint(0, 0)];
		}
	}
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
	return (subview == self->topView);
}

- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
{
	return (subview == self->topView);
}

@end
