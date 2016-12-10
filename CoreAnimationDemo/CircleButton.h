//
//  CircleButton.h
//  coreAnimationDemo
//
//  Created by 王灿辉 on 2016/12/10.
//  Copyright © 2016年 王灿辉. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <NetworkExtension/NetworkExtension.h>

#define screenWidth [UIScreen mainScreen].bounds.size.width
#define screenHeight [UIScreen mainScreen].bounds.size.height

@interface CircleButton : UIButton
// 开始波浪动画
- (void)startWaveAnimation;
// 更具连接的结果切换动画最终停留效果
- (void)switchStatus:(NEVPNStatus)status;
@end
