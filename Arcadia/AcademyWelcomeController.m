#import "AcademyWelcomeController.h"
#import "AcademyAppIconView.h"
#import "CatalogStore.h"
#import "AcademyTheme.h"

@interface AcademyWelcomeController ()
@property (nonatomic, strong, nullable) CatalogStore *catalogStore;
@property (nonatomic, strong, nullable) NSSound *startupSound;
@property (nonatomic, weak, nullable) NSWindow *sheetParent;
@end

@implementation AcademyWelcomeController

+ (NSString *)bundleVersionLine {
    // SDS-10 §10.2.2: read from the bundle's own Info.plist at runtime.
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *shortVersion = info[@"CFBundleShortVersionString"];
    NSString *buildVersion = info[@"CFBundleVersion"];
    if (shortVersion != nil && buildVersion != nil) {
        return [NSString stringWithFormat:@"Version %@ (%@)", shortVersion, buildVersion];
    }
    if (buildVersion != nil) {
        return [NSString stringWithFormat:@"Version %@", buildVersion];
    }
    return @"Version unknown";
}

- (instancetype)initWithCatalogStore:(CatalogStore *)store {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 480, 360)
                                                   styleMask:NSWindowStyleMaskTitled
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    self = [super initWithWindow:window];
    if (self) {
        _catalogStore = store;
        [self buildContent];
    }
    return self;
}

- (void)buildContent {
    NSWindow *window = [self window];
    [window setTitle:@"Welcome"];
    NSView *content = [window contentView];

    AcademyAppIconView *iconView = [[AcademyAppIconView alloc] initWithFrame:NSMakeRect(176, 224, 128, 128)];
    [content addSubview:iconView];

    NSTextField *titleField = [NSTextField labelWithString:@"Arcadia"];
    [titleField setFont:[NSFont systemFontOfSize:28 weight:NSFontWeightSemibold]];
    [titleField setAlignment:NSTextAlignmentCenter];
    [titleField setFrame:NSMakeRect(30, 186, 420, 34)];
    [content addSubview:titleField];

    NSTextField *academyField = [NSTextField labelWithString:@"Detroit Automation Academy"];
    [academyField setFont:[AcademyTheme captionFont]];
    [academyField setTextColor:[AcademyTheme mutedColor]];
    [academyField setAlignment:NSTextAlignmentCenter];
    [academyField setFrame:NSMakeRect(30, 166, 420, 16)];
    [content addSubview:academyField];

    NSTextField *versionField = [NSTextField labelWithString:[[self class] bundleVersionLine]];
    [versionField setFont:[NSFont systemFontOfSize:12]];
    [versionField setTextColor:[AcademyTheme mutedColor]];
    [versionField setAlignment:NSTextAlignmentCenter];
    [versionField setFrame:NSMakeRect(30, 144, 420, 18)];
    [content addSubview:versionField];

    NSString *catalogLine = self.catalogStore != nil ? self.catalogStore.statusLine
                                                     : @"No catalog is loaded.";
    NSTextField *catalogField = [NSTextField labelWithString:catalogLine];
    [catalogField setFont:[NSFont systemFontOfSize:12]];
    [catalogField setTextColor:[AcademyTheme mutedColor]];
    [catalogField setAlignment:NSTextAlignmentCenter];
    [catalogField setFrame:NSMakeRect(30, 122, 420, 18)];
    [content addSubview:catalogField];

    NSTextField *noteField = [NSTextField labelWithString:
        @"Arcadia includes no commercial ROMs and no BIOS or firmware files. "
         "You supply your own files for your own hardware; the library lists "
         "only emulators and works whose rights basis is traced."];
    [noteField setFont:[NSFont systemFontOfSize:12]];
    [noteField setTextColor:[AcademyTheme mutedColor]];
    [noteField setAlignment:NSTextAlignmentCenter];
    [noteField setLineBreakMode:NSLineBreakByWordWrapping];
    [noteField setFrame:NSMakeRect(40, 62, 400, 54)];
    [content addSubview:noteField];

    NSButton *beginButton = [[NSButton alloc] initWithFrame:NSMakeRect(190, 18, 100, 28)];
    [beginButton setTitle:@"Continue"];
    [beginButton setBezelStyle:NSBezelStyleRounded];
    [beginButton setKeyEquivalent:@"\r"];
    [beginButton setTarget:self];
    [beginButton setAction:@selector(dismissWelcome:)];
    [content addSubview:beginButton];
}

- (void)playStartupSoundOnce {
    // SDS-10 §10.3: byte-identical startup-sound.wav, once, system volume.
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"startup-sound" ofType:@"wav"];
    if (soundPath == nil) return;
    self.startupSound = [[NSSound alloc] initWithContentsOfFile:soundPath byReference:YES];
    [self.startupSound play];
}

- (void)presentAsSheetOnWindow:(NSWindow *)parentWindow {
    NSWindow *sheet = [self window];
    self.sheetParent = parentWindow;
    [parentWindow beginSheet:sheet completionHandler:nil];
    [self playStartupSoundOnce];
}

- (IBAction)dismissWelcome:(id)sender {
    NSWindow *sheet = [self window];
    if (self.sheetParent != nil) {
        [self.sheetParent endSheet:sheet];
    }
    [sheet orderOut:nil];
}

@end
