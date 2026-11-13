// CatalogRecord — one arcadia-catalog/1 record, wrapped read-only.
// Academy clean-room code; the record shape is the T1 backend contract
// (Arcadia goal hidden_files/work/backend/SCHEMA.md).
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CatalogRecord : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, copy, readonly) NSString *recordID;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *kind;       // emulator|game|film|tv|audio
@property (nonatomic, copy, readonly) NSString *system;
@property (nonatomic, copy, readonly, nullable) NSString *genre;
@property (nonatomic, copy, readonly, nullable) NSNumber *year;
@property (nonatomic, copy, readonly) NSString *rightsClass;
@property (nonatomic, copy, readonly, nullable) NSString *rightsBasis;
@property (nonatomic, copy, readonly, nullable) NSString *evidencePointer;
@property (nonatomic, copy, readonly, nullable) NSString *source;
@property (nonatomic, copy, readonly, nullable) NSString *licenseName;
@property (nonatomic, copy, readonly, nullable) NSString *versionPin;
@property (nonatomic, copy, readonly, nullable) NSString *sha256;
@property (nonatomic, copy, readonly) NSString *hsCompat;
@property (nonatomic, copy, readonly) NSString *hsEvidenceClass;
@property (nonatomic, copy, readonly) NSString *distribution;
@property (nonatomic, copy, readonly) NSString *notes;

@property (nonatomic, readonly) BOOL isEmulator;
// Shelf label for browsing: Emulators / Games / Film / TV / Sound.
@property (nonatomic, copy, readonly) NSString *shelfName;
// Plain-language rights class, shown beside the class code in the UI.
@property (nonatomic, copy, readonly) NSString *rightsClassPlainLanguage;
// Plain-language High Sierra state line.
@property (nonatomic, copy, readonly) NSString *compatibilityLine;
// Plain-language distribution line (never promises a file that is not hosted).
@property (nonatomic, copy, readonly) NSString *distributionLine;

@end

NS_ASSUME_NONNULL_END
