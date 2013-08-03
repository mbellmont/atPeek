#import <Cocoa/Cocoa.h>

// Default implementation is supplied for all protocol methods

@protocol NSPreferencesModule
- (NSBox *) viewForPreferenceNamed: (NSString *) prefName;
- (NSImage *) imageForPreferenceNamed: (NSString *) prefName;				
- (BOOL) hasChangesPending;																				
- (void) saveChanges;
- (void) willBeDisplayed;
- (void) initializeFromDefaults;
- (void) didChange;
- (void) moduleWillBeRemoved;
- (void) moduleWasInstalled;
- (BOOL) moduleCanBeRemoved;
- (BOOL) preferencesWindowShouldClose;
@end

@interface NSPreferencesModule : NSObject <NSPreferencesModule>
{
	IBOutlet NSBox *_preferencesView;	// 4 = 0x4
	NSSize _minSize;	// 8 = 0x8
	BOOL _hasChanges;	// 16 = 0x10
	void *_reserved;	// 20 = 0x14
}

+ (id)sharedInstance;	// IMP=0x0017614d
- (void)dealloc;	// IMP=0x005594be
- (void)finalize;	// IMP=0x00559511
- (id)init;	// IMP=0x00176263
- (id)preferencesNibName;	// IMP=0x001e1189
- (void)setPreferencesView:(id)fp8;	// IMP=0x001e186a
- (id)viewForPreferenceNamed:(id)fp8;	// IMP=0x001e108a
- (id)imageForPreferenceNamed:(id)fp8;	// IMP=0x001d39cf
- (id)titleForIdentifier:(id)fp8;	// IMP=0x00559548
- (BOOL)hasChangesPending;	// IMP=0x001ec3a0
- (void)saveChanges;	// IMP=0x001ec3ac
- (void)willBeDisplayed;	// IMP=0x005595b9
- (void)initializeFromDefaults;	// IMP=0x005595be
- (void)didChange;	// IMP=0x005595c3
- (NSSize)minSize;	// IMP=0x001e2568
- (void)setMinSize:(NSSize)fp8;	// IMP=0x00559613
- (void)moduleWillBeRemoved;	// IMP=0x00559627
- (void)moduleWasInstalled;	// IMP=0x001e33d9
- (BOOL)moduleCanBeRemoved;	// IMP=0x0055962c
- (BOOL)preferencesWindowShouldClose;	// IMP=0x00559636
- (BOOL)isResizable;	// IMP=0x00559640

@end