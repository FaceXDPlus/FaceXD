//
//  XDResourceDownloader.m
//  AMGFace
//
//  Created by CmST0us on 2020/3/29.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDResourceDownloader.h"
#import "request_key.h"
#define kXDResourceURLFacePredictorModel @"https://AMGFace-dlib-1253814426.cos.ap-chengdu.myqcloud.com/shape_predictor_68_face_landmarks.dat"

@implementation XDResourceDownloader

+ (NSURLRequest *)facePredictorModelRequest {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:kXDResourceURLFacePredictorModel]];
    [request setValue:kAMGFace_DLIB_BUCKET_REFERER forHTTPHeaderField:@"Referer"];
    [request setHTTPMethod:@"GET"];
    return request;
}

+ (NSURLSessionDownloadTask *)downloadWithRequest:(NSURLRequest *)request completion:(nonnull XDResourceDownloaderCompletionBlock)completion {
    NSURLSessionDownloadTask *downloadTask = [[NSURLSession sharedSession] downloadTaskWithRequest:request
                                                                                 completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (completion) {
            completion(location, response, error);
        }
    }];
    return downloadTask;
}

@end
