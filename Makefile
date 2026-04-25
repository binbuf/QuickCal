XCODE_DIR := /Applications/Xcode.app/Contents/Developer
XCODEBUILD := DEVELOPER_DIR=$(XCODE_DIR) $(XCODE_DIR)/usr/bin/xcodebuild
PROJECT := QuickCal.xcodeproj
SCHEME := QuickCal
BUILD_DIR := build

.PHONY: generate build run clean release

# Generate .xcodeproj from project.yml
generate:
	xcodegen generate

# Debug build
build: generate
	$(XCODEBUILD) -project $(PROJECT) -scheme $(SCHEME) -configuration Debug build

# Release build into ./build
release: generate
	$(XCODEBUILD) -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
		-derivedDataPath $(BUILD_DIR) build
	@echo ""
	@echo "Built: $(BUILD_DIR)/Build/Products/Release/QuickCal.app"

# Build and launch
run: build
	@APP=$$($(XCODEBUILD) -project $(PROJECT) -scheme $(SCHEME) -configuration Debug \
		-showBuildSettings 2>/dev/null | grep -m1 'BUILT_PRODUCTS_DIR' | awk '{print $$3}'); \
	open "$$APP/QuickCal.app"

# Remove derived data and build artifacts
clean:
	$(XCODEBUILD) -project $(PROJECT) -scheme $(SCHEME) clean 2>/dev/null || true
	rm -rf $(BUILD_DIR)
	rm -rf ~/Library/Developer/Xcode/DerivedData/QuickCal-*
