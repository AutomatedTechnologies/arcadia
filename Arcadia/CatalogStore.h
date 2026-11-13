// CatalogStore — loads the bundled arcadia-catalog/1 snapshot and, on
// demand or at launch, refreshes from the Academy's served catalog.
// A refreshed catalog is adopted ONLY when it validates against the
// bundled schema version (schema field == "arcadia-catalog/1", records
// present, every record carrying the required keys). Any failure keeps
// the current catalog — offline means the bundled snapshot, stated
// plainly in the status line, never an error dialog.
#import <Foundation/Foundation.h>

@class CatalogRecord;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const ArcadiaCatalogDidChangeNotification;
extern NSString * const ArcadiaCatalogURLString;

@interface CatalogStore : NSObject

@property (nonatomic, copy, readonly) NSArray<CatalogRecord *> *records;
@property (nonatomic, copy, readonly) NSArray<NSDictionary *> *archiveNotes;
@property (nonatomic, copy, readonly) NSString *statusLine;
@property (nonatomic, readonly) BOOL usingBundledSnapshot;

// Loads Resources/arcadia-catalog.json. Returns NO (with the bundled
// snapshot still empty) only when the bundle itself is corrupt.
- (BOOL)loadBundledSnapshot;

// Fetches the served catalog; on a validated response the records are
// replaced and ArcadiaCatalogDidChangeNotification is posted on the
// main queue. On any failure the current records stand.
- (void)refreshFromNetworkWithCompletion:(nullable void (^)(BOOL adopted))completion;

- (NSArray<CatalogRecord *> *)recordsInShelf:(NSString *)shelfName;
- (NSArray<NSString *> *)genreNamesInShelf:(NSString *)shelfName;
- (NSArray<CatalogRecord *> *)recordsInShelf:(NSString *)shelfName genre:(nullable NSString *)genre;

@end

NS_ASSUME_NONNULL_END
