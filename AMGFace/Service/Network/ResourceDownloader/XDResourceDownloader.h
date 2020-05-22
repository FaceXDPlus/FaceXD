//
//  XDResourceDownloader.h
//  AMGFace
//
//  Created by CmST0us on 2020/3/29.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^XDResourceDownloaderCompletionBlock)(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error);

@interface XDResourceDownloader : NSObject

+ (NSURLRequest *)facePredictorModelRequest;

+ (NSURLSessionDownloadTask *)downloadWithRequest:(NSURLRequest *)request completion:(XDResourceDownloaderCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
