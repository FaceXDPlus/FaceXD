#import "LAppBundle.h"

@implementation NSBundle (LAppBundle)
+ (NSBundle *)live2DResourceBundle {
    static NSBundle *bundle = nil;
    if (bundle == nil) {
        NSString *mainPath = [[NSBundle mainBundle] bundlePath];
        NSString *resourcePath = [mainPath stringByAppendingPathComponent:@"Live2DResource"];
        bundle = [NSBundle bundleWithPath:resourcePath];
    }
    return bundle;
}

+ (NSBundle *)modelResourceBundleWithName:(NSString *)name {
    NSBundle *resourceBundle = [NSBundle live2DResourceBundle];
    NSString *dir = [[resourceBundle bundlePath] stringByAppendingPathComponent:name];
    return [NSBundle bundleWithPath:dir];
}

- (NSString *)moc3FilePath {
    NSString *assetName = [self.bundlePath lastPathComponent];
    NSString *filePath = [self pathForResource:assetName ofType:@"moc3"];
    return filePath;
}

- (NSString *)model3FilePath {
    NSString *assetName = [self.bundlePath lastPathComponent];
    NSString *filePath = [self pathForResource:assetName ofType:@"model3.json"];
    return filePath;
}


@end
