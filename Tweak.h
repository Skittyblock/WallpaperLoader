// WallpaperLoader Headers

enum WKWallpaperType {
	Still,
	Live
};

enum WKWallpaperStyle {
	Default,
	Dark
};

@interface WKWallpaperBundle : NSObject
@property (nonatomic, retain) NSNumber *wallpaperType;
@property (nonatomic, retain) NSNumber *loadTag;
- (id)initWithDynamicDictionary:(id)arg1 identifier:(unsigned long long)arg2;
- (id)fileBasedWallpaperForLocation:(id)arg1 andAppearance:(id)appearance;
- (id)valueBasedWallpaperForLocation:(id)arg1 andAppearance:(id)appearance;
- (void)set_defaultAppearanceWallpapers:(NSMutableDictionary *)dict;
- (void)test;
@end

@interface WKWallpaperBundleCollection : NSObject
@property (nonatomic, assign) unsigned long long wallpaperType;
- (NSString *)displayName;
- (long long)numberOfItems;
- (void)setPreviewBundle:(WKWallpaperBundle *)bundle;
- (id)wallpaperBundleAtIndex:(unsigned long long)index;
- (id)initWithWallpaperType:(unsigned long long)type previewBundle:(id)bundle;
@end

@interface WKAbstractWallpaper : NSObject
@end

@interface WKStillWallpaper : WKAbstractWallpaper
- (id)initWithIdentifier:(unsigned long long)arg1 name:(id)arg2 thumbnailImageURL:(id)arg3 fullsizeImageURL:(id)arg4;
- (id)initWithIdentifier:(unsigned long long)arg1 name:(id)arg2 thumbnailImageURL:(id)arg3 fullsizeImageURL:(id)arg4 renderedImageURL:(id)arg5;
@end

@interface WKLiveWallpaper : WKAbstractWallpaper
- (id)initWithIdentifier:(unsigned long long)arg1 name:(id)arg2 thumbnailImageURL:(id)arg3 fullsizeImageURL:(id)arg4 videoAssetURL:(id)arg5 stillTimeInVideo:(double)arg6;
@end
