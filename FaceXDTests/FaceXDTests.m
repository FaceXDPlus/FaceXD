//
//  FaceXDTests.m
//  FaceXDTests
//
//  Created by CmST0us on 2020/3/29.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XDFilePath.h"
#import "XDResourceDownloader.h"

@interface FaceXDTests : XCTestCase
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@end

@implementation FaceXDTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testDownloadModel {
    NSURLRequest *request = [XDResourceDownloader facePredictorModelRequest];
    self.downloadTask = [XDResourceDownloader downloadWithRequest:request completion:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        XCTAssertNil(error, @"error request");
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        XCTAssert(httpResponse.statusCode == 200, @"error request");
        if ([XDFilePath isFacePredictorModelExist]) {
            [[NSFileManager defaultManager] removeItemAtPath:[XDFilePath facePredictorModelPath] error:nil];
        }
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:[XDFilePath facePredictorModelPath]] error:nil];
    }];
    [self.downloadTask resume];
    while (!self.downloadTask.progress.finished) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

@end
