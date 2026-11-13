// EmulatorLauncher — finds a locally installed copy of an emulator and
// launches it. Detection order: the user's chosen path for the record
// (NSUserDefaults, set from the Choose App… panel), then the standard
// locations /Applications and ~/Applications, matched by app name
// (the record title plus a small alias table for renamed builds).
// Arcadia ships no emulator binaries; this only opens what the user
// already has.
#import <Foundation/Foundation.h>

@class CatalogRecord;

NS_ASSUME_NONNULL_BEGIN

@interface EmulatorLauncher : NSObject

// The installed app's path, or nil when no copy is found.
+ (nullable NSString *)installedAppPathForRecord:(CatalogRecord *)record;
+ (void)setUserChosenAppPath:(NSString *)path forRecord:(CatalogRecord *)record;
+ (nullable NSString *)userChosenAppPathForRecord:(CatalogRecord *)record;
// Opens the app at the path. Returns NO when the launch is refused.
+ (BOOL)launchAppAtPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
