#import "LibraryViewController.h"
#import "CatalogStore.h"
#import "CatalogRecord.h"
#import "EmulatorLauncher.h"
#import "AcademyTheme.h"

// Flipped document view for the detail pane: labels stack top-down.
@interface ArcadiaFlippedView : NSView
@end
@implementation ArcadiaFlippedView
- (BOOL)isFlipped { return YES; }
@end

static NSString * const ArcadiaShelfAll = @"All Titles";
static NSArray<NSString *> *ArcadiaShelfOrder(void) {
    return @[@"Emulators", @"Games", @"Film", @"TV", @"Sound"];
}

@interface LibraryViewController () <NSTableViewDataSource, NSTableViewDelegate>
@property (nonatomic, strong) CatalogStore *store;
@property (nonatomic, strong) NSTableView *sidebarTable;
@property (nonatomic, strong) NSTableView *titlesTable;
@property (nonatomic, strong) NSScrollView *detailScroll;
@property (nonatomic, strong) NSView *detailContent;
@property (nonatomic, strong) NSTextField *statusField;
@property (nonatomic, copy) NSArray<NSDictionary *> *sidebarRows;
@property (nonatomic, copy) NSArray<CatalogRecord *> *visibleRecords;
@property (nonatomic, copy) NSString *selectedShelf;
@property (nonatomic, copy, nullable) NSString *selectedGenre;
@property (nonatomic, strong, nullable) CatalogRecord *selectedRecord;
@end

@implementation LibraryViewController

- (instancetype)initWithCatalogStore:(CatalogStore *)store {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _store = store;
        _selectedShelf = ArcadiaShelfAll;
        _sidebarRows = @[];
        _visibleRecords = @[];
    }
    return self;
}

- (void)loadView {
    NSView *root = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1080, 640)];
    self.view = root;

    // Sidebar (shelves + genres of the selected shelf).
    NSScrollView *sidebarScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 28, 200, 612)];
    [sidebarScroll setHasVerticalScroller:YES];
    [sidebarScroll setBorderType:NSBezelBorder];
    [sidebarScroll setAutoresizingMask:NSViewHeightSizable];
    self.sidebarTable = [[NSTableView alloc] initWithFrame:sidebarScroll.bounds];
    NSTableColumn *sidebarColumn = [[NSTableColumn alloc] initWithIdentifier:@"Sidebar"];
    [sidebarColumn setWidth:196];
    [self.sidebarTable addTableColumn:sidebarColumn];
    [self.sidebarTable setHeaderView:nil];
    [self.sidebarTable setDataSource:self];
    [self.sidebarTable setDelegate:self];
    [self.sidebarTable setTag:1];
    [sidebarScroll setDocumentView:self.sidebarTable];
    [root addSubview:sidebarScroll];

    // Title list.
    NSScrollView *titlesScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(200, 28, 400, 612)];
    [titlesScroll setHasVerticalScroller:YES];
    [titlesScroll setBorderType:NSBezelBorder];
    [titlesScroll setAutoresizingMask:NSViewHeightSizable];
    self.titlesTable = [[NSTableView alloc] initWithFrame:titlesScroll.bounds];
    NSTableColumn *titleColumn = [[NSTableColumn alloc] initWithIdentifier:@"Title"];
    [titleColumn setTitle:@"Title"];
    [titleColumn setWidth:200];
    [self.titlesTable addTableColumn:titleColumn];
    NSTableColumn *systemColumn = [[NSTableColumn alloc] initWithIdentifier:@"System"];
    [systemColumn setTitle:@"System"];
    [systemColumn setWidth:120];
    [self.titlesTable addTableColumn:systemColumn];
    NSTableColumn *yearColumn = [[NSTableColumn alloc] initWithIdentifier:@"Year"];
    [yearColumn setTitle:@"Year"];
    [yearColumn setWidth:56];
    [self.titlesTable addTableColumn:yearColumn];
    [self.titlesTable setDataSource:self];
    [self.titlesTable setDelegate:self];
    [self.titlesTable setTag:2];
    [self.titlesTable setDoubleAction:@selector(titleDoubleClicked:)];
    [self.titlesTable setTarget:self];
    [titlesScroll setDocumentView:self.titlesTable];
    [root addSubview:titlesScroll];

    // Detail pane.
    self.detailScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(600, 28, 480, 612)];
    [self.detailScroll setHasVerticalScroller:YES];
    [self.detailScroll setBorderType:NSBezelBorder];
    [self.detailScroll setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    self.detailContent = [[ArcadiaFlippedView alloc] initWithFrame:NSMakeRect(0, 0, 456, 612)];
    [self.detailContent setAutoresizingMask:NSViewWidthSizable];
    [self.detailScroll setDocumentView:self.detailContent];
    [root addSubview:self.detailScroll];

    // Status bar.
    self.statusField = [NSTextField labelWithString:@""];
    [self.statusField setFont:[AcademyTheme captionFont]];
    [self.statusField setTextColor:[AcademyTheme mutedColor]];
    [self.statusField setFrame:NSMakeRect(10, 5, 880, 18)];
    [self.statusField setAutoresizingMask:NSViewWidthSizable];
    [root addSubview:self.statusField];
    NSButton *refreshButton = [[NSButton alloc] initWithFrame:NSMakeRect(950, 2, 120, 24)];
    [refreshButton setTitle:@"Refresh Catalog"];
    [refreshButton setBezelStyle:NSBezelStyleRounded];
    [refreshButton setTarget:self];
    [refreshButton setAction:@selector(refreshCatalog:)];
    [refreshButton setAutoresizingMask:NSViewMinXMargin];
    [root addSubview:refreshButton];

    [self rebuildSidebarRows];
    [self applyFilter];
    [self showEmptyDetail];
}

#pragma mark - Filtering

- (void)rebuildSidebarRows {
    NSMutableArray<NSDictionary *> *rows = [NSMutableArray array];
    [rows addObject:@{@"type": @"header", @"title": @"SHELVES"}];
    [rows addObject:@{@"type": @"shelf", @"title": ArcadiaShelfAll, @"shelf": ArcadiaShelfAll}];
    for (NSString *shelf in ArcadiaShelfOrder()) {
        NSUInteger count = [[self.store recordsInShelf:shelf] count];
        if (count == 0 && ![shelf isEqualToString:@"TV"]) continue;
        if (count == 0) continue;  // TV appears only when records exist.
        [rows addObject:@{@"type": @"shelf",
                          @"title": [NSString stringWithFormat:@"%@ (%lu)", shelf, (unsigned long)count],
                          @"shelf": shelf}];
    }
    NSArray<NSString *> *genres = [self.store genreNamesInShelf:self.selectedShelf];
    if ([genres count] > 0) {
        [rows addObject:@{@"type": @"header", @"title": @"GENRES"}];
        [rows addObject:@{@"type": @"genre", @"title": @"All genres", @"genre": @""}];
        for (NSString *genre in genres) {
            [rows addObject:@{@"type": @"genre",
                              @"title": [NSString stringWithFormat:@"  %@", genre],
                              @"genre": genre}];
        }
    }
    self.sidebarRows = rows;
    [self.sidebarTable reloadData];
    // Keep the selection highlight on the current shelf row.
    for (NSUInteger i = 0; i < [rows count]; i++) {
        NSDictionary *row = rows[i];
        if ([row[@"type"] isEqualToString:@"shelf"] &&
            [row[@"shelf"] isEqualToString:self.selectedShelf] && self.selectedGenre == nil) {
            [self.sidebarTable selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
        }
    }
}

- (void)applyFilter {
    self.visibleRecords = [self.store recordsInShelf:self.selectedShelf genre:self.selectedGenre];
    [self.titlesTable reloadData];
    self.statusField.stringValue = [NSString stringWithFormat:@"%@ · %lu shown",
                                    self.store.statusLine, (unsigned long)[self.visibleRecords count]];
    if ([self.visibleRecords count] > 0) {
        [self.titlesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        [self showDetailForRecord:self.visibleRecords[0]];
    } else {
        self.selectedRecord = nil;
        [self showEmptyDetail];
    }
}

- (void)reloadCatalog {
    [self rebuildSidebarRows];
    [self applyFilter];
}

- (void)selectShelf:(NSString *)shelfName {
    self.selectedShelf = shelfName;
    self.selectedGenre = nil;
    [self rebuildSidebarRows];
    [self applyFilter];
}

- (IBAction)refreshCatalog:(id)sender {
    self.statusField.stringValue = @"Refreshing from detroitautomationacademy.com…";
    __weak typeof(self) weakSelf = self;
    [self.store refreshFromNetworkWithCompletion:^(BOOL adopted) {
        typeof(self) strongSelf = weakSelf;
        if (strongSelf == nil) return;
        if (adopted) {
            [strongSelf reloadCatalog];
        } else {
            strongSelf.statusField.stringValue = strongSelf.store.statusLine;
        }
    }];
}

#pragma mark - Detail pane

- (void)clearDetail {
    for (NSView *subview in [[self.detailContent subviews] copy]) {
        [subview removeFromSuperview];
    }
}

- (CGFloat)addLabelWithText:(NSString *)text font:(NSFont *)font color:(NSColor *)color y:(CGFloat)y {
    NSTextField *label = [NSTextField labelWithString:text ?: @""];
    [label setFont:font];
    [label setTextColor:color];
    [label setLineBreakMode:NSLineBreakByWordWrapping];
    NSRect bounds = [text boundingRectWithSize:NSMakeSize(424, CGFLOAT_MAX)
                                       options:NSStringDrawingUsesLineFragmentOrigin
                                    attributes:@{NSFontAttributeName: font}];
    CGFloat height = MAX(16.0, ceil(bounds.size.height) + 4.0);
    [label setFrame:NSMakeRect(16, y, 424, height)];
    [self.detailContent addSubview:label];
    return y + height + 6;
}

- (CGFloat)addButtonWithTitle:(NSString *)title action:(SEL)action y:(CGFloat)y {
    NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(16, y, 200, 28)];
    [button setTitle:title];
    [button setBezelStyle:NSBezelStyleRounded];
    [button setTarget:self];
    [button setAction:action];
    [self.detailContent addSubview:button];
    return y + 36;
}

- (void)showEmptyDetail {
    [self clearDetail];
    [self.detailContent setFrame:NSMakeRect(0, 0, 456, 612)];
    [self addLabelWithText:@"Arcadia — the Academy's High Sierra library."
                      font:[AcademyTheme headingFont] color:[AcademyTheme inkColor] y:16];
    [self addLabelWithText:@"Pick a title to see its system, its High Sierra state, and — in full — why the library is allowed to list it. Arcadia ships no commercial ROMs and no BIOS or firmware files; you supply your own files for your own hardware."
                      font:[AcademyTheme bodyFont] color:[AcademyTheme mutedColor] y:52];
}

- (void)showDetailForRecord:(CatalogRecord *)record {
    self.selectedRecord = record;
    [self clearDetail];
    CGFloat y = 16;
    y = [self addLabelWithText:record.title font:[AcademyTheme titleFont] color:[AcademyTheme inkColor] y:y];
    NSMutableArray<NSString *> *meta = [NSMutableArray arrayWithObjects:record.shelfName, record.system, nil];
    if (record.year != nil) [meta addObject:[record.year stringValue]];
    if (record.genre != nil) [meta addObject:record.genre];
    y = [self addLabelWithText:[meta componentsJoinedByString:@" · "]
                          font:[AcademyTheme bodyFont] color:[AcademyTheme mutedColor] y:y];
    y += 6;
    y = [self addLabelWithText:@"Why this title is listed" font:[AcademyTheme headingFont] color:[AcademyTheme inkColor] y:y];
    y = [self addLabelWithText:[NSString stringWithFormat:@"Rights class %@: %@", record.rightsClass, record.rightsClassPlainLanguage]
                          font:[AcademyTheme bodyFont] color:[AcademyTheme inkColor] y:y];
    if (record.rightsBasis != nil) {
        y = [self addLabelWithText:record.rightsBasis font:[AcademyTheme bodyFont] color:[AcademyTheme inkColor] y:y];
    }
    if (record.evidencePointer != nil) {
        y = [self addLabelWithText:[NSString stringWithFormat:@"Evidence: %@", record.evidencePointer]
                              font:[AcademyTheme captionFont] color:[AcademyTheme mutedColor] y:y];
    }
    y += 6;
    y = [self addLabelWithText:@"Details" font:[AcademyTheme headingFont] color:[AcademyTheme inkColor] y:y];
    NSString *pin = record.versionPin != nil ? record.versionPin : @"Pin owed — see notes";
    y = [self addLabelWithText:[NSString stringWithFormat:@"Version pin: %@", pin]
                          font:[AcademyTheme bodyFont] color:[AcademyTheme inkColor] y:y];
    y = [self addLabelWithText:record.compatibilityLine font:[AcademyTheme bodyFont] color:[AcademyTheme inkColor] y:y];
    if (record.licenseName != nil) {
        y = [self addLabelWithText:[NSString stringWithFormat:@"License: %@", record.licenseName]
                              font:[AcademyTheme bodyFont] color:[AcademyTheme inkColor] y:y];
    }
    y = [self addLabelWithText:record.distributionLine font:[AcademyTheme bodyFont] color:[AcademyTheme inkColor] y:y];
    if (record.source != nil) {
        y = [self addLabelWithText:[NSString stringWithFormat:@"Source: %@", record.source]
                              font:[AcademyTheme bodyFont] color:[AcademyTheme mutedColor] y:y];
    }
    if ([record.notes length] > 0) {
        y = [self addLabelWithText:record.notes font:[AcademyTheme captionFont] color:[AcademyTheme mutedColor] y:y];
    }
    y += 6;
    if (record.isEmulator) {
        NSString *path = [EmulatorLauncher installedAppPathForRecord:record];
        if (path != nil) {
            y = [self addLabelWithText:[NSString stringWithFormat:@"Installed: %@", path]
                                  font:[AcademyTheme bodyFont] color:[AcademyTheme inkColor] y:y];
            y = [self addButtonWithTitle:@"Open Emulator" action:@selector(openEmulator:) y:y];
        } else {
            y = [self addLabelWithText:@"Not installed on this Mac. Arcadia does not download emulators — install one yourself, then point Arcadia at it."
                                  font:[AcademyTheme bodyFont] color:[AcademyTheme mutedColor] y:y];
        }
        y = [self addButtonWithTitle:@"Choose App…" action:@selector(chooseEmulatorApp:) y:y];
    } else if ([record.distribution isEqualToString:@"hosted"]) {
        // Only a hosted record earns an open control — and only when its
        // source is a real URL. Reference-only titles get no fake Play.
        if (record.source != nil && [record.source hasPrefix:@"http"]) {
            y = [self addButtonWithTitle:@"Open Hosted Copy" action:@selector(openHostedCopy:) y:y];
        }
    }
    CGFloat needed = MAX(612.0, y + 16);
    [self.detailContent setFrame:NSMakeRect(0, 0, 456, needed)];
}

#pragma mark - Detail actions

- (IBAction)openEmulator:(id)sender {
    CatalogRecord *record = self.selectedRecord;
    if (record == nil) return;
    NSString *path = [EmulatorLauncher installedAppPathForRecord:record];
    if (path != nil) [EmulatorLauncher launchAppAtPath:path];
}

- (IBAction)chooseEmulatorApp:(id)sender {
    CatalogRecord *record = self.selectedRecord;
    if (record == nil) return;
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel setAllowedFileTypes:@[@"app"]];
    [panel setDirectoryURL:[NSURL fileURLWithPath:@"/Applications"]];
    [panel setPrompt:@"Choose"];
    [panel setMessage:[NSString stringWithFormat:@"Choose the %@ app Arcadia should open.", record.title]];
    if ([panel runModal] == NSModalResponseOK && panel.URL != nil) {
        [EmulatorLauncher setUserChosenAppPath:panel.URL.path forRecord:record];
        [self showDetailForRecord:record];
    }
}

- (IBAction)openHostedCopy:(id)sender {
    CatalogRecord *record = self.selectedRecord;
    if (record == nil || record.source == nil) return;
    NSURL *url = [NSURL URLWithString:record.source];
    if (url != nil) [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)titleDoubleClicked:(id)sender {
    NSInteger row = [self.titlesTable clickedRow];
    if (row >= 0 && row < (NSInteger)[self.visibleRecords count]) {
        CatalogRecord *record = self.visibleRecords[row];
        if (record.isEmulator) [self openEmulator:nil];
    }
}

#pragma mark - NSTableView data source / delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView.tag == 1) return (NSInteger)[self.sidebarRows count];
    return (NSInteger)[self.visibleRecords count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView.tag == 1) {
        return self.sidebarRows[row][@"title"];
    }
    CatalogRecord *record = self.visibleRecords[row];
    NSString *identifier = [tableColumn identifier];
    if ([identifier isEqualToString:@"Title"]) return record.title;
    if ([identifier isEqualToString:@"System"]) return record.system;
    if ([identifier isEqualToString:@"Year"]) return record.year != nil ? [record.year stringValue] : @"—";
    return @"";
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    if (tableView.tag == 1) {
        return ![self.sidebarRows[row][@"type"] isEqualToString:@"header"];
    }
    return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView *tableView = [notification object];
    NSInteger row = [tableView selectedRow];
    if (row < 0) return;
    if (tableView.tag == 1) {
        NSDictionary *entry = self.sidebarRows[row];
        if ([entry[@"type"] isEqualToString:@"shelf"]) {
            self.selectedShelf = entry[@"shelf"];
            self.selectedGenre = nil;
            [self rebuildSidebarRowsPreservingSelection];
            [self applyFilter];
        } else if ([entry[@"type"] isEqualToString:@"genre"]) {
            NSString *genre = entry[@"genre"];
            self.selectedGenre = [genre length] > 0 ? genre : nil;
            [self applyFilter];
        }
    } else if (tableView.tag == 2 && row < (NSInteger)[self.visibleRecords count]) {
        [self showDetailForRecord:self.visibleRecords[row]];
    }
}

// Rebuilds the sidebar (genre rows follow the shelf) without retriggering
// a shelf selection: applyFilter runs once, from the caller.
- (void)rebuildSidebarRowsPreservingSelection {
    NSMutableArray<NSDictionary *> *rows = [NSMutableArray array];
    [rows addObject:@{@"type": @"header", @"title": @"SHELVES"}];
    [rows addObject:@{@"type": @"shelf", @"title": ArcadiaShelfAll, @"shelf": ArcadiaShelfAll}];
    for (NSString *shelf in ArcadiaShelfOrder()) {
        NSUInteger count = [[self.store recordsInShelf:shelf] count];
        if (count == 0) continue;
        [rows addObject:@{@"type": @"shelf",
                          @"title": [NSString stringWithFormat:@"%@ (%lu)", shelf, (unsigned long)count],
                          @"shelf": shelf}];
    }
    NSArray<NSString *> *genres = [self.store genreNamesInShelf:self.selectedShelf];
    if ([genres count] > 0) {
        [rows addObject:@{@"type": @"header", @"title": @"GENRES"}];
        [rows addObject:@{@"type": @"genre", @"title": @"All genres", @"genre": @""}];
        for (NSString *genre in genres) {
            [rows addObject:@{@"type": @"genre",
                              @"title": [NSString stringWithFormat:@"  %@", genre],
                              @"genre": genre}];
        }
    }
    self.sidebarRows = rows;
    [self.sidebarTable reloadData];
}

@end
