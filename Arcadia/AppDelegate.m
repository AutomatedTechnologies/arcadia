#import "AppDelegate.h"
#import "AcademyWelcomeController.h"
#import "LibraryViewController.h"
#import "CatalogStore.h"
#import "AcademyTheme.h"

static NSString * const ArcadiaRefreshOnLaunchKey = @"ArcadiaRefreshOnLaunch";

@interface AppDelegate ()
@property (nonatomic, strong) NSWindow *mainWindow;
@property (nonatomic, strong) NSWindow *preferencesWindow;
@property (nonatomic, strong) NSWindow *helpWindow;
@property (nonatomic, strong) CatalogStore *catalogStore;
@property (nonatomic, strong) LibraryViewController *libraryController;
@property (nonatomic, strong) AcademyWelcomeController *welcomeController;
@property (nonatomic, strong) NSButton *refreshOnLaunchCheckbox;
@end

@implementation AppDelegate

+ (void)initialize {
    if (self == [AppDelegate class]) {
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{ArcadiaRefreshOnLaunchKey: @YES}];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setMainMenu:[self buildMainMenu]];

    self.catalogStore = [[CatalogStore alloc] init];
    [self.catalogStore loadBundledSnapshot];

    self.libraryController = [[LibraryViewController alloc] initWithCatalogStore:self.catalogStore];
    NSRect frame = NSMakeRect(0, 0, 1080, 640);
    self.mainWindow = [[NSWindow alloc] initWithContentRect:frame
                                                  styleMask:(NSWindowStyleMaskTitled |
                                                             NSWindowStyleMaskClosable |
                                                             NSWindowStyleMaskMiniaturizable |
                                                             NSWindowStyleMaskResizable)
                                                    backing:NSBackingStoreBuffered
                                                      defer:NO];
    [self.mainWindow setTitle:@"Arcadia"];
    [self.mainWindow setContentViewController:self.libraryController];
    [self.mainWindow setMinSize:NSMakeSize(820, 480)];
    [self.mainWindow center];
    [self.mainWindow makeKeyAndOrderFront:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(catalogDidChange:)
                                                 name:ArcadiaCatalogDidChangeNotification
                                               object:nil];

    // SDS-8 welcome + SDS-10 startup surfaces.
    self.welcomeController = [[AcademyWelcomeController alloc] initWithCatalogStore:self.catalogStore];
    NSWindow *window = self.mainWindow;
    AcademyWelcomeController *welcome = self.welcomeController;
    dispatch_async(dispatch_get_main_queue(), ^{
        [welcome presentAsSheetOnWindow:window];
    });

    // Refresh at launch when reachable; failure keeps the bundled
    // snapshot and only changes the status line.
    if ([[NSUserDefaults standardUserDefaults] boolForKey:ArcadiaRefreshOnLaunchKey]) {
        [self.catalogStore refreshFromNetworkWithCompletion:nil];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (void)catalogDidChange:(NSNotification *)notification {
    [self.libraryController reloadCatalog];
}

#pragma mark - Menu construction (SDS-10 §10.4: real bar, every item wired)

- (NSMenuItem *)itemWithTitle:(NSString *)title
                       action:(SEL)action
                keyEquivalent:(NSString *)key
                       target:(id)target {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:key];
    [item setTarget:target];
    return item;
}

- (NSMenu *)buildMainMenu {
    NSMenu *mainMenu = [[NSMenu alloc] init];

    // — App menu —
    NSMenu *appMenu = [[NSMenu alloc] init];
    [appMenu addItem:[self itemWithTitle:@"About Arcadia"
                                  action:@selector(showAbout:)
                           keyEquivalent:@""
                                  target:self]];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItem:[self itemWithTitle:@"Preferences…"
                                  action:@selector(showPreferences:)
                           keyEquivalent:@","
                                  target:self]];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItem:[self itemWithTitle:@"Quit Arcadia"
                                  action:@selector(terminate:)
                           keyEquivalent:@"q"
                                  target:NSApp]];
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    [appMenuItem setSubmenu:appMenu];
    [mainMenu addItem:appMenuItem];

    // — File menu —
    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
    [fileMenu addItem:[self itemWithTitle:@"Refresh Catalog"
                                   action:@selector(refreshCatalog:)
                            keyEquivalent:@"r"
                                   target:self]];
    [fileMenu addItem:[NSMenuItem separatorItem]];
    [fileMenu addItem:[self itemWithTitle:@"Close Window"
                                   action:@selector(closeWindow:)
                            keyEquivalent:@"w"
                                   target:self]];
    NSMenuItem *fileMenuItem = [[NSMenuItem alloc] init];
    [fileMenuItem setTitle:@"File"];
    [fileMenuItem setSubmenu:fileMenu];
    [mainMenu addItem:fileMenuItem];

    // — Edit menu (first-responder chain) —
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [editMenu addItem:[self itemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x" target:nil]];
    [editMenu addItem:[self itemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c" target:nil]];
    [editMenu addItem:[self itemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v" target:nil]];
    [editMenu addItem:[self itemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a" target:nil]];
    NSMenuItem *editMenuItem = [[NSMenuItem alloc] init];
    [editMenuItem setTitle:@"Edit"];
    [editMenuItem setSubmenu:editMenu];
    [mainMenu addItem:editMenuItem];

    // — View menu (shelves) —
    NSMenu *viewMenu = [[NSMenu alloc] initWithTitle:@"View"];
    NSArray *shelves = @[@"All Titles", @"Emulators", @"Games", @"Film", @"TV", @"Sound"];
    NSArray *keys = @[@"0", @"1", @"2", @"3", @"4", @"5"];
    for (NSUInteger i = 0; i < [shelves count]; i++) {
        NSMenuItem *item = [self itemWithTitle:shelves[i]
                                        action:@selector(showShelf:)
                                 keyEquivalent:keys[i]
                                        target:self];
        [item setRepresentedObject:shelves[i]];
        [viewMenu addItem:item];
    }
    NSMenuItem *viewMenuItem = [[NSMenuItem alloc] init];
    [viewMenuItem setTitle:@"View"];
    [viewMenuItem setSubmenu:viewMenu];
    [mainMenu addItem:viewMenuItem];

    // — Window menu —
    NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
    [windowMenu addItem:[self itemWithTitle:@"Minimize"
                                     action:@selector(performMiniaturize:)
                              keyEquivalent:@"m"
                                     target:nil]];
    [windowMenu addItem:[self itemWithTitle:@"Zoom"
                                     action:@selector(performZoom:)
                              keyEquivalent:@""
                                     target:nil]];
    [windowMenu addItem:[NSMenuItem separatorItem]];
    [windowMenu addItem:[self itemWithTitle:@"Bring All to Front"
                                     action:@selector(arrangeInFront:)
                              keyEquivalent:@""
                                     target:nil]];
    NSMenuItem *windowMenuItem = [[NSMenuItem alloc] init];
    [windowMenuItem setTitle:@"Window"];
    [windowMenuItem setSubmenu:windowMenu];
    [mainMenu addItem:windowMenuItem];
    [NSApp setWindowsMenu:windowMenu];

    // — Help menu —
    NSMenu *helpMenu = [[NSMenu alloc] initWithTitle:@"Help"];
    [helpMenu addItem:[self itemWithTitle:@"Arcadia Help"
                                   action:@selector(showHelp:)
                            keyEquivalent:@"?"
                                   target:self]];
    NSMenuItem *helpMenuItem = [[NSMenuItem alloc] init];
    [helpMenuItem setTitle:@"Help"];
    [helpMenuItem setSubmenu:helpMenu];
    [mainMenu addItem:helpMenuItem];
    [NSApp setHelpMenu:helpMenu];

    return mainMenu;
}

#pragma mark - Actions

- (IBAction)showAbout:(id)sender {
    NSString *credits = @"Arcadia is the Detroit Automation Academy's library of High Sierra-era "
        @"emulators and public-domain media. Every title carries its rights basis, traced to "
        @"evidence. Arcadia ships no commercial ROMs and no BIOS or firmware files — you supply "
        @"your own files for your own hardware.\n\nDetroit Automation Academy";
    NSDictionary *options = @{
        NSAboutPanelOptionApplicationName: @"Arcadia",
        NSAboutPanelOptionApplicationVersion: [AcademyWelcomeController bundleVersionLine],
        NSAboutPanelOptionCredits: [[NSAttributedString alloc] initWithString:credits],
    };
    [NSApp orderFrontStandardAboutPanelWithOptions:options];
}

- (IBAction)showPreferences:(id)sender {
    if (self.preferencesWindow == nil) {
        NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 440, 190)
                                                       styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable)
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
        [window setTitle:@"Arcadia Preferences"];
        NSView *content = [window contentView];
        NSTextField *urlLabel = [NSTextField labelWithString:
            [NSString stringWithFormat:@"Catalog source:\n%@", ArcadiaCatalogURLString]];
        [urlLabel setFont:[AcademyTheme bodyFont]];
        [urlLabel setFrame:NSMakeRect(20, 120, 400, 44)];
        [content addSubview:urlLabel];
        NSTextField *note = [NSTextField labelWithString:
            @"A refreshed catalog is adopted only when it validates as arcadia-catalog/1. "
             "Offline, Arcadia uses its bundled snapshot."];
        [note setFont:[AcademyTheme captionFont]];
        [note setTextColor:[AcademyTheme mutedColor]];
        [note setLineBreakMode:NSLineBreakByWordWrapping];
        [note setFrame:NSMakeRect(20, 66, 400, 44)];
        [content addSubview:note];
        self.refreshOnLaunchCheckbox = [[NSButton alloc] initWithFrame:NSMakeRect(20, 30, 300, 22)];
        [self.refreshOnLaunchCheckbox setButtonType:NSButtonTypeSwitch];
        [self.refreshOnLaunchCheckbox setTitle:@"Refresh catalog at launch"];
        [self.refreshOnLaunchCheckbox setTarget:self];
        [self.refreshOnLaunchCheckbox setAction:@selector(toggleRefreshOnLaunch:)];
        [content addSubview:self.refreshOnLaunchCheckbox];
        self.preferencesWindow = window;
    }
    [self.refreshOnLaunchCheckbox setState:
        [[NSUserDefaults standardUserDefaults] boolForKey:ArcadiaRefreshOnLaunchKey]
            ? NSControlStateValueOn : NSControlStateValueOff];
    [self.preferencesWindow center];
    [self.preferencesWindow makeKeyAndOrderFront:nil];
}

- (IBAction)toggleRefreshOnLaunch:(id)sender {
    BOOL on = ([sender state] == NSControlStateValueOn);
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:ArcadiaRefreshOnLaunchKey];
}

- (IBAction)refreshCatalog:(id)sender {
    // No error theatrics: the library's status line states the outcome.
    [self.libraryController refreshCatalog:sender];
}

- (IBAction)closeWindow:(id)sender {
    [[NSApp keyWindow] close];
}

- (IBAction)showShelf:(id)sender {
    NSString *shelf = [sender representedObject];
    if (shelf != nil) [self.libraryController selectShelf:shelf];
    [self.mainWindow makeKeyAndOrderFront:nil];
}

- (IBAction)showHelp:(id)sender {
    if (self.helpWindow == nil) {
        NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 520, 340)
                                                       styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
        [window setTitle:@"Arcadia Help"];
        NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:[[window contentView] bounds]];
        [scroll setHasVerticalScroller:YES];
        [scroll setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        NSTextView *text = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 500, 320)];
        [text setEditable:NO];
        [text setFont:[AcademyTheme bodyFont]];
        [text setString:
            @"Browsing\n"
             "Shelves (Emulators, Games, Film, TV, Sound) sit in the sidebar, with genre groups "
             "under each shelf. Pick a title to see its detail.\n\n"
             "Rights\n"
             "Every title shows its rights class and the traced basis for listing it. Class A is "
             "public domain by age, Class B by non-renewal or defective notice (with a per-title "
             "evidence file), Class C is a US government work, and open-license titles carry the "
             "author's own grant.\n\n"
             "Emulators\n"
             "If an emulator is installed in /Applications or ~/Applications, Arcadia offers to "
             "open it. Use Choose App… in the detail pane to point Arcadia at a copy installed "
             "elsewhere. Arcadia downloads nothing.\n\n"
             "Your files\n"
             "Arcadia ships no commercial ROMs and no BIOS or firmware files, and hosts no media "
             "in this build — media entries are catalogue references to their sources. You supply "
             "your own files for your own hardware.\n\n"
             "Catalog\n"
             "File ▸ Refresh Catalog fetches the Academy's served catalog. A new catalog is "
             "adopted only when it validates as arcadia-catalog/1; otherwise the bundled "
             "snapshot stands and Arcadia keeps working offline."];
        [scroll setDocumentView:text];
        [[window contentView] addSubview:scroll];
        self.helpWindow = window;
    }
    [self.helpWindow center];
    [self.helpWindow makeKeyAndOrderFront:nil];
}

@end
