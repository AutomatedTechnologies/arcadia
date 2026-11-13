// AppDelegate — Arcadia's shell: code-constructed menu bar (SDS-10
// §10.4, every item wired), the library window, Preferences, About, and
// the startup sequence (bundled snapshot load → library window → SDS-8
// welcome sheet → opportunistic catalog refresh, adopted only when the
// served catalog validates; offline keeps the snapshot, no theatrics).
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

NS_ASSUME_NONNULL_END
