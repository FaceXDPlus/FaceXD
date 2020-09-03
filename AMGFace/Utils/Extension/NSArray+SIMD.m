//
//  NSArray+SIMD.m
//  AMGFace
//
//  Created by eki on 2020/7/25.
//  Copyright © 2020 AMG. All rights reserved.
//


#import "NSArray+SIMD.h"

@implementation NSArray (SIMD)
+ (instancetype)arrayWithSIMDFloat4x4:(simd_float4x4)float4x4 {
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:16];
    for (int i = 0; i < 4; ++i) {
        for (int j = 0; j < 4; ++j) {
            [array addObject:@(float4x4.columns[i][j])];
        }
    }
    return array.copy;
}

+ (instancetype)arrayWithFloat3:(simd_float3)float3 {
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:3];
    for (int i = 0; i < 3; ++i) {
        [array addObject:@(float3[i])];
    }
    return array;
}
@end
