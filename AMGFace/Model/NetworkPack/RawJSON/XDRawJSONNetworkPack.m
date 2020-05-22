//
//  XDRawJSONNetworkPack.m
//  AMGFace
//
//  Created by CmST0us on 2020/4/4.
//  Copyright © 2020 hakura. All rights reserved.
//

#import "XDRawJSONNetworkPack.h"

@implementation XDRawJSONNetworkPack
- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _jsonDictionary = dictionary;
    }
    return self;
}

- (NSData *)serialize {
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.jsonDictionary options:0 error:&parseError];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if (!jsonData) {
        NSLog(@"%@",parseError);
        return [NSData data];
    }
    return [jsonString dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)deserialize {
    self.jsonDictionary = [NSJSONSerialization JSONObjectWithData:self.packData options:0 error:nil];
}

@end
