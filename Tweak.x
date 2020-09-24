// WallpaperLoader - Custom wallpaper bundles
// By Skitty
#include "Tweak.h"

static NSMutableArray *stillList;
static NSMutableArray *liveList;

// Determine logical size class based on screen size
// Apple likely has a much better way of doing this.
static CGSize logicalSizeForScreenSize(CGSize screenSize) {
	NSInteger logicalHeight = 0;
	NSInteger logicalWidth = 0;
	NSInteger screenHeight = screenSize.height / 2;
	if (screenHeight <= 667) {
		logicalHeight = 667; logicalWidth = 375; // 1634x1634 8
	} else if (screenHeight <= 896) {
		logicalHeight = 896; logicalWidth = 414; // 2290x2290 XR / 11
	} else if (screenHeight <= 960) {
		logicalHeight = 736; logicalWidth = 414; // 2706x2706 8+
	} else if (screenHeight <= 1218) {
		logicalHeight = 812; logicalWidth = 375; // 2934x2934 X / 11 Pro
	} else if (screenHeight <= 1344) {
		logicalHeight = 812; logicalWidth = 375; // 2934x2934 Xs Max / 11 Pro Max
	}

	return CGSizeMake(logicalWidth, logicalHeight);
}

// Wallpaper image size for the device screen size
static CGFloat wallpaperSizeForScreenSize(CGSize screenSize) {
	NSInteger screenHeight = screenSize.height / 2;
	if (screenHeight <= 667) {
		return 1634; // 8
	} else if (screenHeight <= 896) {
		return 2290; // XR / 11
	} else if (screenHeight <= 960) {
		return 2706; // 8+
	} else if (screenHeight <= 1218) {
		return 2934; // X / 11 Pro
	} else if (screenHeight <= 1344) {
		return 2934; // Xs Max / 11 Pro Max
	}
	return 0; // Use original image
}

// Returns a WKStillWallpaper/WKLiveWallpaper
static id wallpaperForTypeStyleAndIndex(enum WKWallpaperType type, enum WKWallpaperStyle style, NSInteger idx) {
	NSDictionary *data = (type == Still) ? stillList[idx] : liveList[idx];

	NSString *name = data[@"name"];
	NSString *path = [NSString stringWithFormat:@"/Library/WallpaperLoader/%@", name];
	NSString *thumbPath = [NSString stringWithFormat:@"/Library/WallpaperLoader/%@", name];
	NSString *image = data[@"defaultImage"];
	if (style == Dark) {
		image = data[@"darkImage"];
	}
	CGSize logicalSize = logicalSizeForScreenSize([UIScreen mainScreen].bounds.size);

	NSString *newFile = [NSString stringWithFormat:@"%@-%iw-%ih.%@", [image stringByDeletingPathExtension], (int)logicalSize.width, (int)logicalSize.height, image.pathExtension];
	// If bundle includes correctly sized image, use it.
	if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@", path, newFile]]) {
		image = newFile;
	} else if (![data[@"autoResize"] isEqual:@(NO)]) { // If it doesn't, attempt to create one at a temporary path
		if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/tmp/WallpaperLoader/%@/%@", name, newFile]]) {
			path = [NSString stringWithFormat:@"/tmp/WallpaperLoader/%@", name];
			image = newFile;
		} else {
			CGFloat size = wallpaperSizeForScreenSize([UIScreen mainScreen].bounds.size);
			if (size) {
				UIImage *currentImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", path, image]];
				path = [NSString stringWithFormat:@"/tmp/WallpaperLoader/%@", name];

				CGSize newSize = CGSizeMake(currentImage.size.width * (size / currentImage.size.height), size);

				UIGraphicsBeginImageContext(newSize);
				[currentImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
				UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
				UIGraphicsEndImageContext();

				[[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
				[UIImagePNGRepresentation(newImage) writeToFile:[NSString stringWithFormat:@"%@/%@", path, newFile] atomically:YES];

				image = newFile;
			}
		}
	}

	NSURL *thumbnailURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", thumbPath, data[@"thumbnailImage"]]];
	NSURL *fullsizeURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", path, image]];
	if (type == Still) {
		if ([NSClassFromString(@"WKStillWallpaper") respondsToSelector:@selector(initWithIdentifier:name:thumbnailImageURL:fullsizeImageURL:)]) {
			return [[NSClassFromString(@"WKStillWallpaper") alloc] initWithIdentifier:1234 name:name thumbnailImageURL:thumbnailURL fullsizeImageURL:fullsizeURL];
		}
		return [[NSClassFromString(@"WKStillWallpaper") alloc] initWithIdentifier:1234 name:name thumbnailImageURL:thumbnailURL fullsizeImageURL:fullsizeURL renderedImageURL:nil];
	} else if (type == Live) {
		// Live videos currently are not resized
		NSURL *videoURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", thumbPath, (style == Dark) ? data[@"darkVideo"] : data[@"defaultVideo"]]];
		return [[NSClassFromString(@"WKLiveWallpaper") alloc] initWithIdentifier:1234 name:name thumbnailImageURL:thumbnailURL fullsizeImageURL:fullsizeURL videoAssetURL:videoURL stillTimeInVideo:0];
	}

	return nil;
}

// Load custom bundles
%hook WKWallpaperBundleCollection

- (long long)numberOfItems {
	if (self.wallpaperType == 0) {
		return %orig + [stillList count];
	} else if (self.wallpaperType == 1) {
		return %orig + [liveList count];
	}
	return %orig;
}

- (NSMutableArray *)_wallpaperBundles {
	return %orig;
}

- (id)wallpaperBundleAtIndex:(unsigned long long)index {
	if (self.wallpaperType == 0) {
		for (int i = 1; i <= [stillList count]; i++) {
			if (index == [self numberOfItems] - [stillList count] + i - 1) {
				WKWallpaperBundle *bundle = [[%c(WKWallpaperBundle) alloc] init];
				bundle.wallpaperType = @(self.wallpaperType);
				bundle.loadTag = @(i);
				return bundle;
			}
		}
	} else if (self.wallpaperType == 1) {
		for (int i = 1; i <= [liveList count]; i++) {
			if (index == [self numberOfItems] - [liveList count] + i - 1) {
				WKWallpaperBundle *bundle = [[%c(WKWallpaperBundle) alloc] init];
				bundle.wallpaperType = @(self.wallpaperType);
				bundle.loadTag = @(i);
				return bundle;
			}
		}
	}
	return %orig;
}

%end

// Make sure bundles return the correct values
%hook WKWallpaperBundle
%property (nonatomic, retain) NSNumber *wallpaperType;
%property (nonatomic, retain) NSNumber *loadTag;

- (NSString *)name {
	NSInteger idx = [self.loadTag intValue] - 1;
	if ([self.loadTag intValue] > 0 && [self.wallpaperType isEqual:@0]) {
		return stillList[idx][@"name"];
	} else if ([self.loadTag intValue] > 0 && [self.wallpaperType isEqual:@1]) {
		return liveList[idx][@"name"];
	}
	return %orig;
}

- (NSString *)family {
	if ([self.loadTag intValue] > 0) {
		return @"WallpaperLoader";
	}
	return %orig;
}

- (unsigned long long)version {
	if ([self.loadTag intValue] > 0) {
		return 1;
	}
	return %orig;
}

- (unsigned long long)identifier {
	if ([self.loadTag intValue] > 0) {
		return 1;
	}
	return %orig;
}

- (BOOL)hasDistintWallpapersForLocations {
	if ([self.loadTag intValue] > 0) {
		return NO;
	}
	return %orig;
}

- (BOOL)isDynamicWallpaperBundle {
	if ([self.loadTag intValue] > 0) {
		return NO;
	}
	return %orig;
}

- (BOOL)isAppearanceAware {
	NSInteger idx = [self.loadTag intValue] - 1;
	if ([self.loadTag intValue] > 0 && [self.wallpaperType isEqual:@0]) {
		return stillList[idx][@"appearanceAware"];
	} else if ([self.loadTag intValue] > 0 && [self.wallpaperType isEqual:@1]) {
		return liveList[idx][@"appearanceAware"];
	}
	return %orig;
}

- (NSURL *)thumbnailImageURL {
	NSInteger idx = [self.loadTag intValue] - 1;
	if ([self.loadTag intValue] > 0 && [self.wallpaperType isEqual:@0]) {
		return [NSURL fileURLWithPath:[NSString stringWithFormat:@"/Library/WallpaperLoader/%@/%@", stillList[idx][@"name"], stillList[idx][@"thumbnailImage"]]];
	} else if ([self.loadTag intValue] > 0 && [self.wallpaperType isEqual:@1]) {
		return [NSURL fileURLWithPath:[NSString stringWithFormat:@"/Library/WallpaperLoader/%@/%@", liveList[idx][@"name"], liveList[idx][@"thumbnailImage"]]];
	}
	return %orig;
}

- (NSMutableDictionary *)_defaultAppearanceWallpapers {
	NSInteger idx = [self.loadTag intValue] - 1;
	if ([self.loadTag intValue] > 0 && [self.wallpaperType isEqual:@0]) {
		return [@{@"WKWallpaperLocationCoverSheet": wallpaperForTypeStyleAndIndex(Still, Default, idx)} mutableCopy];
	} else if ([self.loadTag intValue] > 0 && [self.wallpaperType isEqual:@1]) {
		return [@{@"WKWallpaperLocationCoverSheet": wallpaperForTypeStyleAndIndex(Live, Default, idx)} mutableCopy];
	}
	return %orig;
}

- (NSMutableDictionary *)_darkAppearanceWallpapers {
	NSInteger idx = [self.loadTag intValue] - 1;
	if ([self.loadTag intValue] > 0 && [self.wallpaperType isEqual:@0]) {
		return [@{@"WKWallpaperLocationCoverSheet": wallpaperForTypeStyleAndIndex(Still, Dark, idx)} mutableCopy];
	} else if ([self.loadTag intValue] > 0 && [self.wallpaperType isEqual:@1]) {
		return [@{@"WKWallpaperLocationCoverSheet": wallpaperForTypeStyleAndIndex(Live, Dark, idx)} mutableCopy];
	}
	return %orig;
}

- (id)fileBasedWallpaperForLocation:(id)location andAppearance:(id)appearance {
	NSInteger idx = [self.loadTag intValue] - 1;
	if ([self.loadTag intValue] > 0 && [self.wallpaperType isEqual:@0]) {
		return wallpaperForTypeStyleAndIndex(Still, [appearance isEqualToString:@"dark"] ? Dark : Default, idx);
	} else if ([self.loadTag intValue] > 0 && [self.wallpaperType isEqual:@1]) {
		return wallpaperForTypeStyleAndIndex(Live, [appearance isEqualToString:@"dark"] ? Dark : Default, idx);
	}
	return %orig;
}

- (id)valueBasedWallpaperForLocation:(id)location {
	if ([self.loadTag intValue] > 0) {
		return [self valueBasedWallpaperForLocation:location andAppearance:@"default"];
	}
	return %orig;
}

- (id)fileBasedWallpaperForLocation:(id)location {
	if ([self.loadTag intValue] > 0) {
		return [self fileBasedWallpaperForLocation:location andAppearance:@"default"];
	}
	return %orig;
}

- (id)valueBasedWallpaperForLocation:(id)location andAppearance:(id)appearance {
	if ([self.loadTag intValue] > 0)
		return [self fileBasedWallpaperForLocation:location andAppearance:appearance];
	return %orig;
}

%end

// Fixes stupid crashes
%hook WKStillWallpaper

%new
- (id)thumbnailImage {
	return [[UIImage alloc] init];
}

%new
- (id)wallpaperValue {
	return nil;
}

%end

%hook WKLiveWallpaper

%new
- (id)thumbnailImage {
	return [[UIImage alloc] init];
}

%new
- (id)wallpaperValue {
	return nil;
}

%end

%ctor {
	NSArray *subpaths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:@"/Library/WallpaperLoader" error:NULL];
	for (NSString *item in subpaths) {
		if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Library/WallpaperLoader/%@/Wallpaper.plist", item]]) {
			NSMutableDictionary *plist = [[NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/Library/WallpaperLoader/%@/Wallpaper.plist", item]] mutableCopy];

			// Check if proper format
			if (!plist[@"defaultImage"] || (plist[@"appearanceAware"] && !plist[@"darkImage"])) {
				NSLog(@"[WallpaperLoader] Misconfigured bundle %@", plist[@"wallpaperType"]);
			} else {
				plist[@"name"] = item;
				if (!plist[@"thumbnailImage"]) plist[@"thumbnailImage"] = plist[@"defaultImage"];
				if ([plist[@"wallpaperType"] isEqual:@0]) {
					if (!stillList) stillList = [[NSMutableArray alloc] init];
					[stillList addObject:[plist copy]];
				} else if ([plist[@"wallpaperType"] isEqual:@1]) {
					if (!liveList) liveList = [[NSMutableArray alloc] init];
					[liveList addObject:[plist copy]];
				}
			}
		}
	}
}
