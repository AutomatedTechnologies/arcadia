// AcademyAppIconView — the single icon surface (SDS-10 §10.1.2, the
// DistroLogoView pattern): draws the bundle's own AppIcon composition,
// so bundle icon, Dock, welcome screen, and About can never diverge.
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AcademyAppIconView : NSView
@property (nonatomic, strong, readonly) NSImage *iconImage;
@end

NS_ASSUME_NONNULL_END
