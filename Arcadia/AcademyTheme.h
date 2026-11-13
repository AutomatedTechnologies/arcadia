// AcademyTheme — SDS-1 monochrome ramp + SDS-2 type scale for Arcadia.
// Presentation constants only; no logic lives here.
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AcademyTheme : NSObject

+ (NSColor *)inkColor;        // #000000 primary text / strokes
+ (NSColor *)paperColor;      // #ffffff background
+ (NSColor *)panelColor;      // #f4f4f4 panels, table headers, selection backing
+ (NSColor *)mutedColor;      // #444444 secondary text
+ (NSColor *)faintColor;      // #999999 disabled only

+ (NSFont *)titleFont;        // 20 semibold
+ (NSFont *)headingFont;      // 15 semibold
+ (NSFont *)bodyFont;         // 13
+ (NSFont *)captionFont;      // 11

@end

NS_ASSUME_NONNULL_END
