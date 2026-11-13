#import "CatalogStore.h"
#import "CatalogRecord.h"

NSString * const ArcadiaCatalogDidChangeNotification = @"ArcadiaCatalogDidChangeNotification";
NSString * const ArcadiaCatalogURLString = @"https://www.detroitautomationacademy.com/assets/arcadia-catalog.json";
static NSString * const ArcadiaCatalogSchemaVersion = @"arcadia-catalog/1";

@interface CatalogStore ()
@property (nonatomic, copy, readwrite) NSArray<CatalogRecord *> *records;
@property (nonatomic, copy, readwrite) NSArray<NSDictionary *> *archiveNotes;
@property (nonatomic, copy, readwrite) NSString *statusLine;
@property (nonatomic, readwrite) BOOL usingBundledSnapshot;
@end

@implementation CatalogStore

- (instancetype)init {
    self = [super init];
    if (self) {
        _records = @[];
        _archiveNotes = @[];
        _statusLine = @"No catalog loaded.";
        _usingBundledSnapshot = YES;
    }
    return self;
}

// Minimal structural validation against the bundled schema version:
// the same contract arcadia_tool.py enforces at build time, checked
// here before a downloaded catalog may replace the bundled snapshot.
- (BOOL)validateCatalogDictionary:(NSDictionary *)catalog {
    if (![catalog isKindOfClass:[NSDictionary class]]) return NO;
    if (![catalog[@"schema"] isEqualToString:ArcadiaCatalogSchemaVersion]) return NO;
    NSArray *records = catalog[@"records"];
    if (![records isKindOfClass:[NSArray class]]) return NO;
    NSArray *required = @[@"id", @"title", @"kind", @"system", @"genre",
                           @"rights_class", @"rights_basis", @"evidence_pointer",
                           @"source", @"version_pin", @"sha256",
                           @"hs_compat", @"hs_evidence_class", @"distribution"];
    for (id entry in records) {
        if (![entry isKindOfClass:[NSDictionary class]]) return NO;
        for (NSString *key in required) {
            if (entry[key] == nil) return NO;
        }
        NSString *kind = entry[@"kind"];
        if (![kind isEqualToString:@"emulator"]) {
            id basis = entry[@"rights_basis"];
            id evidence = entry[@"evidence_pointer"];
            if (![basis isKindOfClass:[NSString class]] || [basis length] == 0) return NO;
            if (![evidence isKindOfClass:[NSString class]] || [evidence length] == 0) return NO;
            id genre = entry[@"genre"];
            if (![genre isKindOfClass:[NSString class]] || [genre length] == 0) return NO;
        } else {
            id source = entry[@"source"];
            if (![source isKindOfClass:[NSString class]] || [source length] == 0) return NO;
        }
    }
    return YES;
}

- (BOOL)adoptCatalogDictionary:(NSDictionary *)catalog statusLine:(NSString *)statusLine {
    if (![self validateCatalogDictionary:catalog]) return NO;
    NSMutableArray<CatalogRecord *> *parsed = [NSMutableArray array];
    for (NSDictionary *entry in catalog[@"records"]) {
        [parsed addObject:[[CatalogRecord alloc] initWithDictionary:entry]];
    }
    NSArray *notes = catalog[@"notes"];
    self.records = parsed;
    self.archiveNotes = [notes isKindOfClass:[NSArray class]] ? notes : @[];
    self.statusLine = statusLine;
    return YES;
}

- (BOOL)loadBundledSnapshot {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"arcadia-catalog" ofType:@"json"];
    if (path == nil) {
        self.statusLine = @"Bundled catalog snapshot is missing from this build.";
        return NO;
    }
    NSData *data = [NSData dataWithContentsOfFile:path];
    id parsed = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    NSUInteger recordCount = 0;
    if ([parsed isKindOfClass:[NSDictionary class]] &&
        [parsed[@"records"] isKindOfClass:[NSArray class]]) {
        recordCount = [parsed[@"records"] count];
    }
    NSString *line = [NSString stringWithFormat:@"Bundled snapshot — %lu titles, works offline.",
                      (unsigned long)recordCount];
    if ([parsed isKindOfClass:[NSDictionary class]] &&
        [self adoptCatalogDictionary:parsed statusLine:line]) {
        self.usingBundledSnapshot = YES;
        return YES;
    }
    self.statusLine = @"Bundled catalog snapshot did not validate against arcadia-catalog/1.";
    return NO;
}

- (void)refreshFromNetworkWithCompletion:(void (^)(BOOL))completion {
    NSURL *url = [NSURL URLWithString:ArcadiaCatalogURLString];
    NSURLSessionDataTask *task =
        [[NSURLSession sharedSession] dataTaskWithURL:url
                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        BOOL adopted = NO;
        if (data != nil && error == nil) {
            id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([parsed isKindOfClass:[NSDictionary class]]) {
                NSString *line = [NSString stringWithFormat:@"Served catalog — %lu titles, refreshed from detroitautomationacademy.com.",
                                  (unsigned long)[parsed[@"records"] count]];
                adopted = [self adoptCatalogDictionary:parsed statusLine:line];
                if (adopted) {
                    self.usingBundledSnapshot = NO;
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (adopted) {
                [[NSNotificationCenter defaultCenter] postNotificationName:ArcadiaCatalogDidChangeNotification object:self];
            } else if (self.usingBundledSnapshot) {
                self.statusLine = [NSString stringWithFormat:@"%@ Refresh did not adopt a new catalog — the bundled snapshot stands.",
                                   self.statusLine];
            }
            if (completion) completion(adopted);
        });
    }];
    [task resume];
}

- (NSArray<CatalogRecord *> *)recordsInShelf:(NSString *)shelfName {
    if ([shelfName isEqualToString:@"All Titles"]) return self.records;
    NSMutableArray *out = [NSMutableArray array];
    for (CatalogRecord *record in self.records) {
        if ([record.shelfName isEqualToString:shelfName]) [out addObject:record];
    }
    return out;
}

- (NSArray<NSString *> *)genreNamesInShelf:(NSString *)shelfName {
    NSMutableSet<NSString *> *seen = [NSMutableSet set];
    for (CatalogRecord *record in [self recordsInShelf:shelfName]) {
        if (record.genre != nil) [seen addObject:record.genre];
    }
    return [[seen allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (NSArray<CatalogRecord *> *)recordsInShelf:(NSString *)shelfName genre:(NSString *)genre {
    NSArray<CatalogRecord *> *shelf = [self recordsInShelf:shelfName];
    if (genre == nil) return shelf;
    NSMutableArray *out = [NSMutableArray array];
    for (CatalogRecord *record in shelf) {
        if ([record.genre isEqualToString:genre]) [out addObject:record];
    }
    return out;
}

@end
