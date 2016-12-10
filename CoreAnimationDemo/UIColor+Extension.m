
//
//  UIColor+Extension.m
//  coreAnimationDemo
//
//  Created by 王灿辉 on 2016/12/10.
//  Copyright © 2016年 王灿辉. All rights reserved.
//

#import "UIColor+Extension.h"

@implementation UIColor (Extension)

+(UIColor *)colorWithHex:(NSString *)hex alpha:(float)alpha;
{
    if ([hex characterAtIndex:0]=='#') {
        hex = [hex substringFromIndex:1];
    }
    NSString *rs = [hex substringWithRange:NSMakeRange(0, 2)];
    long r = strtol([rs UTF8String],NULL, 16);
    NSString *gs = [hex substringWithRange:NSMakeRange(2, 2)];
    long g = strtol([gs UTF8String],NULL, 16);
    NSString *bs = [hex substringWithRange:NSMakeRange(4, 2)];
    long b = strtol([bs UTF8String],NULL, 16);
    return [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0 alpha:alpha];
}

+(UIColor *)colorWithHex:(NSString *)hex;
{
   return [self colorWithHex:hex alpha:1.0];
}

@end
