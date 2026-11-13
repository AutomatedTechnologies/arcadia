// LibraryViewController — Arcadia's one window: shelf + genre sidebar,
// title list, and the per-title detail pane. The detail pane leads with
// the rights basis in plain language — it is a feature, not fine print.
// Media records are reference-only unless the record says hosted; no
// Play control is ever shown for a title with no hosted copy.
#import <AppKit/AppKit.h>

@class CatalogStore;

NS_ASSUME_NONNULL_BEGIN

@interface LibraryViewController : NSViewController

- (instancetype)initWithCatalogStore:(CatalogStore *)store;
- (void)reloadCatalog;
- (void)selectShelf:(NSString *)shelfName;
- (IBAction)refreshCatalog:(id)sender;

@end

NS_ASSUME_NONNULL_END
