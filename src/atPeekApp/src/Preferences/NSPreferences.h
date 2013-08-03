
#import <Cocoa/Cocoa.h>
#import "NSPreferencesModule.h"

#ifdef __cplusplus
extern "C" {
#endif
	extern void _nsBeginNSPSupport();				// magic call to get NSPreferences working properly....
#ifdef __cplusplus
}
#endif

@interface NSPreferences : NSObject
{
	NSWindow *_preferencesPanel;	// 4 = 0x4
	NSBox *_preferenceBox;	// 8 = 0x8
	NSMatrix *_moduleMatrix;	// 12 = 0xc
	NSButtonCell *_okButton;	// 16 = 0x10
	NSButtonCell *_cancelButton;	// 20 = 0x14
	NSButtonCell *_applyButton;	// 24 = 0x18
	NSMutableArray *_preferenceTitles;	// 28 = 0x1c
	NSMutableArray *_preferenceModules;	// 32 = 0x20
	NSMutableDictionary *_masterPreferenceViews;	// 36 = 0x24
	NSMutableDictionary *_currentSessionPreferenceViews;	// 40 = 0x28
	NSBox *_originalContentView;	// 44 = 0x2c
	BOOL _isModal;	// 48 = 0x30
	float _constrainedWidth;	// 52 = 0x34
	id _currentModule;	// 56 = 0x38
	void *_reserved;	// 60 = 0x3c
}

+ (id) sharedPreferences;
+ (void) setDefaultPreferencesClass: (Class) defPreferencesClass;
+ (Class) defaultPreferencesClass;
- (id) init;
- (void) dealloc;	
- (void) addPreferenceNamed: (NSString *) title owner: (NSPreferencesModule *) module;
- (void) _setupToolbar;	
- (void)_setupUI;	// IMP=0x001ce4f5
- (NSSize) preferencesContentSize;
- (void) showPreferencesPanel;
- (void) showPreferencesPanelForOwner:(id)fp8;	// IMP=0x001cd410
- (int) showModalPreferencesPanelForOwner:(id)fp8;	// IMP=0x005590e6
- (int) showModalPreferencesPanel;
- (void) ok: (id) sender;
- (void) cancel: (id) sender;
- (void) apply: (id) sender;
- (void) _selectModuleOwner: (NSPreferencesModule *) module;
- (NSString *) windowTitle;
- (void) confirmCloseSheetIsDone:(id)fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;	// IMP=0x00559299
- (BOOL) windowShouldClose:(id)fp8;	// IMP=0x001ec0d4
- (void) windowDidResize:(id)fp8;	// IMP=0x001df602
- (struct _NSSize)windowWillResize:(id)fp8 toSize:(struct _NSSize)fp12;	// IMP=0x005592fd
- (BOOL) usesButtons;
- (id)_itemIdentifierForModule:(id)fp8;	// IMP=0x001e2fc9
- (void) toolbarItemClicked: (NSToolbarItem *) item ;
- (NSToolbarItem *) toolbar: (NSToolbar *) toolbar itemForItemIdentifier: (NSString *) itemIdentifier willBeInsertedIntoToolbar: (BOOL) flag;
- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar;
- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar;
- (NSArray *) toolbarSelectableItemIdentifiers: (NSToolbar *) toolbar;

@end