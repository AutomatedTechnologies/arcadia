#import "CatalogRecord.h"

static NSString *StringOrEmpty(id value) {
    return [value isKindOfClass:[NSString class]] ? value : @"";
}
static NSString *StringOrNil(id value) {
    return [value isKindOfClass:[NSString class]] && [value length] > 0 ? value : nil;
}

@implementation CatalogRecord {
    NSDictionary *_dictionary;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _dictionary = [dictionary copy];
    }
    return self;
}

- (NSString *)recordID { return StringOrEmpty(_dictionary[@"id"]); }
- (NSString *)title { return StringOrEmpty(_dictionary[@"title"]); }
- (NSString *)kind { return StringOrEmpty(_dictionary[@"kind"]); }
- (NSString *)system { return StringOrEmpty(_dictionary[@"system"]); }
- (NSString *)genre { return StringOrNil(_dictionary[@"genre"]); }
- (NSNumber *)year {
    id value = _dictionary[@"year"];
    return [value isKindOfClass:[NSNumber class]] ? value : nil;
}
- (NSString *)rightsClass { return StringOrEmpty(_dictionary[@"rights_class"]); }
- (NSString *)rightsBasis { return StringOrNil(_dictionary[@"rights_basis"]); }
- (NSString *)evidencePointer { return StringOrNil(_dictionary[@"evidence_pointer"]); }
- (NSString *)source { return StringOrNil(_dictionary[@"source"]); }
- (NSString *)licenseName { return StringOrNil(_dictionary[@"license"]); }
- (NSString *)versionPin { return StringOrNil(_dictionary[@"version_pin"]); }
- (NSString *)sha256 { return StringOrNil(_dictionary[@"sha256"]); }
- (NSString *)hsCompat { return StringOrEmpty(_dictionary[@"hs_compat"]); }
- (NSString *)hsEvidenceClass { return StringOrEmpty(_dictionary[@"hs_evidence_class"]); }
- (NSString *)distribution { return StringOrEmpty(_dictionary[@"distribution"]); }
- (NSString *)notes { return StringOrEmpty(_dictionary[@"notes"]); }

- (BOOL)isEmulator { return [self.kind isEqualToString:@"emulator"]; }

- (NSString *)shelfName {
    NSString *kind = self.kind;
    if ([kind isEqualToString:@"emulator"]) return @"Emulators";
    if ([kind isEqualToString:@"game"]) return @"Games";
    if ([kind isEqualToString:@"film"]) return @"Film";
    if ([kind isEqualToString:@"tv"]) return @"TV";
    if ([kind isEqualToString:@"audio"]) return @"Sound";
    return @"Titles";
}

- (NSString *)rightsClassPlainLanguage {
    NSString *cls = self.rightsClass;
    if ([cls isEqualToString:@"A"]) {
        return @"Public domain by age — published in 1930 or earlier; the US copyright term has expired.";
    }
    if ([cls isEqualToString:@"B"]) {
        return @"Public domain by non-renewal or defective notice — admitted only with a per-title evidence file.";
    }
    if ([cls isEqualToString:@"C"]) {
        return @"US government work — public domain by law, except embedded third-party material.";
    }
    if ([cls isEqualToString:@"open-license"]) {
        return @"Openly licensed — the author's own grant permits this listing; the grant is traced in the basis below.";
    }
    if ([cls isEqualToString:@"emulator-n/a"]) {
        return @"Emulator software — lawful to list and use. No copyrighted ROM, BIOS, or firmware content is included.";
    }
    return cls;
}

- (NSString *)compatibilityLine {
    NSString *state = self.hsCompat;
    NSString *evidence = self.hsEvidenceClass;
    if ([state isEqualToString:@"compatible"]) {
        return [NSString stringWithFormat:@"High Sierra: compatible (%@)", evidence];
    }
    if ([state isEqualToString:@"candidate"]) {
        return [NSString stringWithFormat:@"High Sierra: candidate — a High Sierra-era build is known; the exact pin is still owed (%@)", evidence];
    }
    if ([state isEqualToString:@"excluded"]) {
        return [NSString stringWithFormat:@"High Sierra: excluded — the macOS floor is above 10.13 (%@)", evidence];
    }
    return @"High Sierra: not applicable (media work)";
}

- (NSString *)distributionLine {
    NSString *dist = self.distribution;
    if ([dist isEqualToString:@"hosted"]) {
        return @"Distribution: an Academy-hosted copy is available for this title.";
    }
    if ([dist isEqualToString:@"reference-only"]) {
        return @"Distribution: reference only — the Academy catalogues this title and points to its source; no file is distributed here.";
    }
    return @"Distribution: catalogued only — no file is distributed for this title yet.";
}

@end
