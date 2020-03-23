#define STBI_NO_STDIO
#define STBI_ONLY_PNG
#define STB_IMAGE_IMPLEMENTATION
#import "stb_image.h"
#import "LAppOpenGLManager.h"

@interface LAppOpenGLTextureInfo : NSObject
@property (nonatomic, assign) GLuint name;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@end
@implementation LAppOpenGLTextureInfo
@end

@interface LAppOpenGLManager () {
    
}
@property (nonatomic, assign) CFTimeInterval currentFrameTime;
@property (nonatomic, assign) CFTimeInterval lastFrameTime;
@property (nonatomic, assign) CFTimeInterval deltaTime;

@property (nonatomic, strong) EAGLContext *glContext;

/// GLuint: GLKTextureInfo
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, LAppOpenGLTextureInfo *> *textureMap;
@end

@implementation LAppOpenGLManager

+ (instancetype)sharedInstance {
    static LAppOpenGLManager *manager;
    @synchronized (self) {
        if (manager == nil) {
            manager = [[LAppOpenGLManager alloc] init];
        }
        return manager;
    }
}

- (void)setup {
    [self updateTime];
    
    _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    _textureMap = [[NSMutableDictionary alloc] init];
}

- (void)clean {
    [self.textureMap removeAllObjects];
}

- (BOOL)createTexture:(GLuint *)textureID withFilePath:(NSString *)filePath {
    if (textureID == nil ||
        filePath == nil) {
        return NO;
    }
    GLuint textureId;
    int width, height, channels;
    unsigned int size;
    unsigned char* png;
    unsigned char* address;

    NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
    address = (unsigned char *)data.bytes;
    size = (unsigned int)data.length;

    // png情報を取得する
    png = stbi_load_from_memory(
                                address,
                                (int)size,
                                &width,
                                &height,
                                &channels,
                                STBI_rgb_alpha);
    
    // OpenGL用のテクスチャを生成する
    glGenTextures(1, &textureId);
    glBindTexture(GL_TEXTURE_2D, textureId);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, png);
    glGenerateMipmap(GL_TEXTURE_2D);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    stbi_image_free(png);
    
    LAppOpenGLTextureInfo *textureInfo = [[LAppOpenGLTextureInfo alloc] init];
    textureInfo.name = textureId;
    textureInfo.width = width;
    textureInfo.height = height;
    *textureID = textureId;
    self.textureMap[@(textureId)] = textureInfo;
    return YES;
}

- (void)releaseTexture:(GLuint)texture {
    LAppOpenGLTextureInfo *textureInfo = self.textureMap[@(texture)];
    if (textureInfo) {
        GLuint textureName = textureInfo.name;
        glDeleteTextures(1, &textureName);
    }
    [self.textureMap removeObjectForKey:@(texture)];
}

- (void)inContext:(dispatch_block_t)block {
    EAGLContext *currentContext = [EAGLContext currentContext];
    EAGLContext *workingContext = nil;
    if (currentContext == self.glContext) {
        workingContext = currentContext;
    } else {
        workingContext = self.glContext;
    }
    
    [EAGLContext setCurrentContext:workingContext];
    if (block) {
        block();
    }
    [EAGLContext setCurrentContext:currentContext];
}

#pragma mark - Time
- (void)updateTime {
    self.currentFrameTime = CACurrentMediaTime();
    self.deltaTime = self.currentFrameTime - self.lastFrameTime;
    self.lastFrameTime = self.currentFrameTime;
}
@end
