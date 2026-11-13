// AcademyWelcomeController — the SDS-8 welcome sheet (SDS-10 surfaces):
//  §10.1.2 logo via AcademyAppIconView (the bundle AppIcon composition);
//  §10.2 version read from Info.plist at runtime, never hardcoded;
//  §10.3 startup-sound.wav from Resources, byte-identical to the master,
//  played once when the welcome presents.
// Arcadia's first-run note rides the same sheet: no commercial ROMs and
// no BIOS/firmware are included; users supply their own files.
#import <AppKit/AppKit.h>

@class CatalogStore;

NS_ASSUME_NONNULL_BEGIN

@interface AcademyWelcomeController : NSWindowController

+ (NSString *)bundleVersionLine;
- (instancetype)initWithCatalogStore:(nullable CatalogStore *)store;
- (void)presentAsSheetOnWindow:(NSWindow *)parentWindow;

@end

NS_ASSUME_NONNULL_END
