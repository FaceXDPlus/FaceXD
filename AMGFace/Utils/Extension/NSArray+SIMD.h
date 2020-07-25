//
//  NSArray+SIMD.h
//  AMGFace
//
//  Created by eki on 2020/7/25.
//  Copyright © 2020 AMG. All rights reserved.
//

#import <simd/simd.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (SIMD)
/*
 例如一个矩阵
 | 4 1 3 3 |
 | 3 2 5 2 |
 | 6 4 3 8 |
 | 2 4 3 6 |
 输出后
 [4, 3, 6, 2, 1, 2, 4, 4, 3, 5, 3, 3, 3, 2, 8, 6]
 */
+ (instancetype)arrayWithSIMDFloat4x4:(simd_float4x4)float4x4;

/*
 | 1 2 3 |
 输出
 [1, 2, 3]
 */
+ (instancetype)arrayWithFloat3:(simd_float3)float3;
@end

NS_ASSUME_NONNULL_END
