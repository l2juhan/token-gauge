VERSION ?= 1.0.0

.PHONY: build release release-unsigned clean

build:
	xcodebuild -project TokenGauge.xcodeproj -scheme TokenGauge -configuration Debug build

release:
	./scripts/release.sh $(VERSION)

release-unsigned:
	./scripts/release.sh $(VERSION) --skip-notarize

clean:
	rm -rf dist/ build/ DerivedData/
