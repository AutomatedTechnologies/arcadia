#import "EmulatorLauncher.h"
#import "CatalogRecord.h"
#import <AppKit/AppKit.h>

@implementation EmulatorLauncher

+ (NSString *)defaultsKeyForRecord:(CatalogRecord *)record {
    return [NSString stringWithFormat:@"ArcadiaEmulatorPath.%@", record.recordID];
}

+ (NSString *)userChosenAppPathForRecord:(CatalogRecord *)record {
    NSString *path = [[NSUserDefaults standardUserDefaults] stringForKey:[self defaultsKeyForRecord:record]];
    if (path != nil && [[NSFileManager defaultManager] fileExistsAtPath:path]) return path;
    return nil;
}

+ (void)setUserChosenAppPath:(NSString *)path forRecord:(CatalogRecord *)record {
    [[NSUserDefaults standardUserDefaults] setObject:path forKey:[self defaultsKeyForRecord:record]];
}

// Candidate .app names for a record: the title itself, plus aliases for
// builds whose app name differs from the catalog title.
+ (NSArray<NSString *> *)candidateAppNamesForRecord:(CatalogRecord *)record {
    NSMutableArray<NSString *> *names = [NSMutableArray arrayWithObject:record.title];
    NSDictionary *aliases = @{
        @"DOSBox": @[@"DOSBox", @"DOSBox-X"],
        @"DOSBox-X": @[@"DOSBox-X", @"DOSBox"],
        @"Atari800MacX": @[@"Atari800MacX", @"Atari800MacX 5"],
        @"Nestopia UE": @[@"Nestopia", @"Nestopia UE"],
        @"Basilisk II": @[@"BasiliskII", @"Basilisk II"],
        @"Mini vMac": @[@"Mini vMac", @"MiniVMac"],
        @"VirtualBox 6.1": @[@"VirtualBox"],
    };
    NSArray *extra = aliases[record.title];
    if (extra != nil) {
        for (NSString *name in extra) {
            if (![names containsObject:name]) [names addObject:name];
        }
    }
    return names;
}

+ (NSString *)installedAppPathForRecord:(CatalogRecord *)record {
    NSString *chosen = [self userChosenAppPathForRecord:record];
    if (chosen != nil) return chosen;
    NSFileManager *files = [NSFileManager defaultManager];
    NSArray<NSString *> *roots = @[@"/Applications",
                                   [NSHomeDirectory() stringByAppendingPathComponent:@"Applications"]];
    for (NSString *name in [self candidateAppNamesForRecord:record]) {
        for (NSString *root in roots) {
            NSString *candidate = [[root stringByAppendingPathComponent:name]
                                   stringByAppendingPathExtension:@"app"];
            if ([files fileExistsAtPath:candidate]) return candidate;
        }
    }
    return nil;
}

+ (BOOL)launchAppAtPath:(NSString *)path {
    return [[NSWorkspace sharedWorkspace] launchApplication:path];
}

@end
