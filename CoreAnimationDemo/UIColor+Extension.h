//
//  UIColor+Extension.h
//  coreAnimationDemo
//
//  Created by 王灿辉 on 2016/12/10.
//  Copyright © 2016年 王灿辉. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Extension)
+(UIColor *)colorWithHex:(NSString *)hex;
+(UIColor *)colorWithHex:(NSString *)hex alpha:(float)alpha;
@end
