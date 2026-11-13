#import "AcademyTheme.h"

@implementation AcademyTheme

+ (NSColor *)inkColor { return [NSColor colorWithCalibratedWhite:0.0 alpha:1.0]; }
+ (NSColor *)paperColor { return [NSColor colorWithCalibratedWhite:1.0 alpha:1.0]; }
+ (NSColor *)panelColor { return [NSColor colorWithCalibratedWhite:0.956 alpha:1.0]; }
+ (NSColor *)mutedColor { return [NSColor colorWithCalibratedWhite:0.267 alpha:1.0]; }
+ (NSColor *)faintColor { return [NSColor colorWithCalibratedWhite:0.6 alpha:1.0]; }

+ (NSFont *)titleFont { return [NSFont systemFontOfSize:20 weight:NSFontWeightSemibold]; }
+ (NSFont *)headingFont { return [NSFont systemFontOfSize:15 weight:NSFontWeightSemibold]; }
+ (NSFont *)bodyFont { return [NSFont systemFontOfSize:13]; }
+ (NSFont *)captionFont { return [NSFont systemFontOfSize:11]; }

@end
