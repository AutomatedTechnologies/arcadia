# Arcadia — file manifest + build rules.
#
#   make check   syntax-check every .m against the MacOSX10.13 SDK
#                (Linux VM recipe per estate TOOLS.md; no link, no run)
#   make app     assemble Arcadia.app (macOS only — system clang + AppKit)

SOURCES = \
	Arcadia/main.m \
	Arcadia/AppDelegate.m \
	Arcadia/AcademyWelcomeController.m \
	Arcadia/AcademyAppIconView.m \
	Arcadia/AcademyTheme.m \
	Arcadia/CatalogRecord.m \
	Arcadia/CatalogStore.m \
	Arcadia/EmulatorLauncher.m \
	Arcadia/LibraryViewController.m

HEADERS = \
	Arcadia/AppDelegate.h \
	Arcadia/AcademyWelcomeController.h \
	Arcadia/AcademyAppIconView.h \
	Arcadia/AcademyTheme.h \
	Arcadia/CatalogRecord.h \
	Arcadia/CatalogStore.h \
	Arcadia/EmulatorLauncher.h \
	Arcadia/LibraryViewController.h

# startup-sound.wav: byte-identical to the SDS-10 library master,
# SHA-256 07a113244c6b432b22954a089ce519bd239311b14a48f26ae85214ed8c25b09a.
# arcadia-catalog.json: bundled offline snapshot, byte-identical to the
# served catalog at build time (assets/arcadia-catalog.json),
# SHA-256 b3c052f8d1dfde0dbdc56620e87fcd024bb3ffbcdff06a4f30427d9b2bb4d7d7.
RESOURCES = \
	Arcadia/Resources/startup-sound.wav \
	Arcadia/Resources/arcadia-catalog.json \
	Arcadia/Resources/catalog.schema.json \
	Arcadia/Resources/LICENSE-ACADEMY.txt \
	Arcadia/Resources/NOTICE.txt

SDK ?= $(HOME)/workspace/tools/sdks/MacOSX10.13.sdk
CLANG ?= clang
CHECKFLAGS = -target x86_64-apple-darwin17 -isysroot $(SDK) \
	-fobjc-runtime=macosx-10.13 -fobjc-arc -fsyntax-only -IArcadia

.PHONY: check app
check:
	@for src in $(SOURCES); do \
		echo "== $$src"; \
		$(CLANG) $(CHECKFLAGS) $$src || exit 1; \
	done
	@echo "ALL SYNTAX OK"

app:
	if [ "$$(uname)" != "Darwin" ]; then \
		echo "make app requires macOS (system clang + AppKit)" >&2; exit 1; \
	fi
	rm -rf Arcadia.app
	mkdir -p Arcadia.app/Contents/MacOS Arcadia.app/Contents/Resources
	$(CLANG) -target x86_64-apple-macos10.13 -fobjc-arc -IArcadia \
		-framework AppKit -framework Foundation \
		-o Arcadia.app/Contents/MacOS/Arcadia $(SOURCES)
	cp Arcadia/Info.plist Arcadia.app/Contents/Info.plist
	cp $(RESOURCES) Arcadia.app/Contents/Resources/
	@echo "Arcadia.app assembled — launch with: open Arcadia.app"
