//
//  ViewController.m
//  coreAnimationDemo
//
//  Created by 王灿辉 on 2016/12/10.
//  Copyright © 2016年 王灿辉. All rights reserved.
//

#import "ViewController.h"
#import "CircleButton.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bgViewTopToSuperView;
@property (nonatomic,assign) int vPNStatus;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    // 适配plus
    if (screenWidth > 375) {
        self.bgViewTopToSuperView.constant += 50;
    }
}

// 模拟一个耗时连接过程
- (IBAction)connect:(CircleButton *)connectBtn {
    // 未连接状态
    if (self.vPNStatus != NEVPNStatusConnected && self.vPNStatus != NEVPNStatusConnecting) {
        // 开始进入正在连接中...的状态
        [connectBtn switchStatus:NEVPNStatusConnecting];
        connectBtn.userInteractionEnabled = NO;
        // 延时4秒，进入连接成功的状态
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [connectBtn switchStatus:NEVPNStatusConnected];
            self.vPNStatus = NEVPNStatusConnected;
            connectBtn.userInteractionEnabled = YES;
           
        });
    }else{ // 已连接或者正在连接中...，断开连接
        // 进入断开连接状态
        [connectBtn switchStatus:NEVPNStatusDisconnecting];
        connectBtn.userInteractionEnabled = NO;
        // 延时0.5秒断开连接
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [connectBtn switchStatus:NEVPNStatusDisconnected];
            self.vPNStatus = NEVPNStatusDisconnected;
            connectBtn.userInteractionEnabled = YES;
        });
    }
    
    
}




@end
