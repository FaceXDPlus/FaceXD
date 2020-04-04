//
//  XDLive2DControlViewModel.h
//  FaceXD
//
//  Created by CmST0us on 2020/4/5.
//  Copyright © 2020 hakura. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XDLive2DControlViewModel : NSObject
@property (nonatomic, copy) NSString *host;
@property (nonatomic, copy) NSString *port;
- (NSError *)connect;
- (void)disconnect;
@end

NS_ASSUME_NONNULL_END
