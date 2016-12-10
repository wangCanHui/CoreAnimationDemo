//
//  CircleButton.m
//  coreAnimationDemo
//
//  Created by 王灿辉 on 2016/12/10.
//  Copyright © 2016年 王灿辉. All rights reserved.
//

#import "CircleButton.h"
#import "UIColor+Extension.h"

@interface CircleButton () <CAAnimationDelegate>
/// 复制layer
@property (strong) CAReplicatorLayer *replicator;
/// 内圆渐变layer
@property (nonatomic,strong) CALayer *innerGradientLayer;
/// 外圆渐变layer
@property (nonatomic,strong) CALayer *outerGradientLayer;
/// 波纹动画layer
@property (strong) CAShapeLayer *waveLayer;
/// 波纹动画
@property (strong) CABasicAnimation *waveAnimation;

@property (strong) CADisplayLink *displayLink;
/// 波纹动画是否进行中
@property (readonly) BOOL isWaveAnimation;
/// 圆环
@property (strong) CAShapeLayer *runingLine;

@end


@implementation CircleButton

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
    
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self initSubLayer];

    _isWaveAnimation = NO;

}

- (void)initSubLayer
{
    CGFloat outerSize;
    CGFloat innerSize;
    NSString *shadowsImageName;
    
    // 4.7 5.5
    if(screenWidth > 320) {
        outerSize = 168;
        innerSize = 140;
        shadowsImageName = @"bg_yinying";
    }
    else {
        outerSize = 144;
        innerSize = 120;
        shadowsImageName = @"bg_yinying_for4s";
    }

    
    CGFloat width = 0;
    NSLayoutConstraint *widthConstraint = nil;
    
    for (NSLayoutConstraint *constraint in self.constraints) {
        if ([constraint.identifier isEqualToString:@"ConnectButtonWidth"]) {
            widthConstraint = constraint;
            break;
        }
    }
    
    if (widthConstraint) {
        width = widthConstraint.constant;
    }
    
    // 1.外圆渐变layer
    CGFloat outerLayerX = (width - outerSize) * 0.5;
    self.outerGradientLayer = [self gradientLayerWithColors:@[(id)[UIColor colorWithHex:@"2f3e6f"].CGColor,(id)[UIColor colorWithHex:@"1b264b"].CGColor] withFrame:CGRectMake(outerLayerX, 0, outerSize, outerSize)];
    [self.layer addSublayer:self.outerGradientLayer];

    // 2.内圆渐变layer
    CGFloat innerLayerX = (width - innerSize) * 0.5; 
    CGFloat innerLayerY = (outerSize-innerSize) * 0.5;
    self.innerGradientLayer = [self gradientLayerWithColors:@[(id)[UIColor colorWithHex:@"5a78d8"].CGColor,(id)[UIColor colorWithHex:@"3a509c"].CGColor] withFrame:CGRectMake(innerLayerX, innerLayerY, innerSize, innerSize)];
    [self.layer addSublayer:self.innerGradientLayer];
    
    // 3.复制layer
    self.replicator = [CAReplicatorLayer layer];
    self.replicator.instanceCount = 2; // 复制layer的数量
    self.replicator.frame = self.outerGradientLayer.frame;
    self.replicator.instanceDelay = 0.3; // 复制间隔的时间
    // 添加到按钮的layer
    [self.layer addSublayer:self.replicator];

    [self initLine];
}

// 根据传的颜色和frame创建渐变色的圆
- (CALayer *)gradientLayerWithColors:(NSArray *)colors withFrame:(CGRect)frame
{
    CAGradientLayer *layer = [CAGradientLayer layer];
    layer.frame = frame;
    // 这里即使用贝塞尔曲线画圆还是要裁剪
//    layer.accessibilityPath = [UIBezierPath bezierPathWithArcCenter:self.center radius:frame.size.width*0.5 startAngle:0 endAngle:180 clockwise:YES];
    layer.cornerRadius = frame.size.width * 0.5;
    layer.masksToBounds = YES;
    layer.colors = colors;
    //  设置渐变颜色方向，左上点为(0,0), 右下点为(1,1)
    layer.startPoint = CGPointMake(0, 0);
    layer.endPoint = CGPointMake(0, 1);
    return layer;
}
// 初始化runingLineLayer
- (void)initLine
{
    self.runingLine = [CAShapeLayer layer];
    CGRect frame = self.innerGradientLayer.frame;
    CGFloat radius = frame.size.width /2 - 15; // 计算半径
    CGFloat lineWidth = 15;

    self.runingLine.lineWidth = lineWidth;
    self.runingLine.frame = frame;
    self.runingLine.strokeColor = [UIColor colorWithHex:@"21e7b6"].CGColor; // 圆环颜色
    self.runingLine.fillColor = [UIColor clearColor].CGColor; // 中间为无色
    self.runingLine.lineCap = kCALineCapRound; // 设置两端圆头
    // 设置路劲，从-90°开始到270°，刚好形成一个从顶部开始沿顺时针方向闭合的路径
    self.runingLine.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.runingLine.frame.size.width / 2, self.runingLine.frame.size.height / 2)
                                                    radius:radius startAngle:-90*M_PI/180 endAngle:270*M_PI/180 clockwise:YES].CGPath;
    // 初始值结束值都为0 ，先隐藏圆环
    self.runingLine.strokeStart = 0;
    self.runingLine.strokeEnd = 0;
    [self.layer addSublayer:self.runingLine];
}

// 开始波纹动画
- (void)startWaveAnimation
{
    // 1. 设置内圆颜色渐变
    CABasicAnimation *changeColor = [CABasicAnimation animationWithKeyPath:@"colors"];
    changeColor.fromValue = [((CAGradientLayer *)self.innerGradientLayer) colors];
    changeColor.toValue = @[(id)[UIColor colorWithHex:@"21e7b6" alpha:0.5].CGColor,(id)[UIColor colorWithHex:@"21e7b6" alpha:0.5].CGColor];
    changeColor.duration = 0.5;
    changeColor.removedOnCompletion = NO;
    changeColor.fillMode = kCAFillModeBoth;
    [self.innerGradientLayer addAnimation:changeColor forKey:@"change inner colors"];
    
    // 2. 初始化波纹动画
    if (self.waveAnimation == nil) {
        self.waveAnimation = [self createWaveAnimation];
    }
    // 3. 初始化波纹
    if (self.waveLayer == nil) {
        
        CAShapeLayer *waveLayer = [CAShapeLayer layer];
        //        waveLayer.backgroundColor = [UIColor whiteColor].CGColor;
        waveLayer.frame = self.outerGradientLayer.bounds;
        waveLayer.path = [UIBezierPath bezierPathWithArcCenter:waveLayer.position
                                                        radius:self.outerGradientLayer.frame.size.width*0.5
                                                    startAngle:0
                                                      endAngle:180
                                                     clockwise:YES].CGPath;
        
        
        waveLayer.fillColor = [UIColor colorWithHex:@"21e7b6"].CGColor;
        
        self.waveLayer = waveLayer;
    }
    
    // 4. 创建圆环的旋转动画
    CAKeyframeAnimation *rotateAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation"];
    rotateAnimation.values = @[
                               @0,
                               @(M_PI),
                               @(2 * M_PI)
                               ];
    // 5. 设置圆环的动画路径
    CABasicAnimation *headAnimation = [CABasicAnimation animation];
    headAnimation.keyPath = @"strokeStart";
    headAnimation.duration = 1;
    headAnimation.fromValue = @0;
    headAnimation.toValue = @.15;
    
    CABasicAnimation *tailAnimation = [CABasicAnimation animation];
    tailAnimation.keyPath = @"strokeEnd";
    tailAnimation.duration = 1;
    tailAnimation.fromValue = @0;
    tailAnimation.toValue = @1;
    
    CABasicAnimation *endHeadAnimation = [CABasicAnimation animation];
    endHeadAnimation.keyPath = @"strokeStart";
    endHeadAnimation.beginTime = 1.;
    endHeadAnimation.duration = 1;
    endHeadAnimation.fromValue = @.15;
    endHeadAnimation.toValue = @1;
    
    CABasicAnimation *endTailAnimation = [CABasicAnimation animation];
    endTailAnimation.keyPath = @"strokeEnd";
    endTailAnimation.beginTime = 1;
    endTailAnimation.duration = 1;
    endTailAnimation.fromValue = @1;
    endTailAnimation.toValue = @1;
    
    // 统一设置添加到动画组
    CAAnimationGroup *animations = [CAAnimationGroup animation];
    animations.duration = 2;
    animations.animations = @[
//                              rotateAnimation,
                              headAnimation,
                              tailAnimation,
                              endHeadAnimation,
                              endTailAnimation
                              ];
    animations.repeatCount = INFINITY;
    
    rotateAnimation.duration = 2;
    rotateAnimation.repeatCount = INFINITY;
    
    [self.runingLine addAnimation:animations forKey:@"line rotation"];
    [self.runingLine addAnimation:rotateAnimation forKey:@"line transform.rotation"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1
                                                              * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 开始执行波纹动画
        _isWaveAnimation = YES;
        [self.waveLayer addAnimation:self.waveAnimation forKey:@"Wave Animation"];
        // 将波纹layer添加到replicator，使replicator复制waveLayer
        [self.replicator addSublayer:self.waveLayer];
    });
}

- (void)stopWaveAnimationWithStatus:(NEVPNStatus)status
{
    [self finishWaveAnimation];
    
    if (status == NEVPNStatusConnected) {

        CFTimeInterval pausedTime = [self.runingLine convertTime:CACurrentMediaTime() fromLayer:nil];
        self.runingLine.speed = 0.0;
        self.runingLine.timeOffset = pausedTime;
        
    } else if (status == NEVPNStatusReasserting) {
        CABasicAnimation *finishColor = [CABasicAnimation animationWithKeyPath:@"colors"];
        
        finishColor.fromValue = [((CAGradientLayer *)self.innerGradientLayer) colors];
        finishColor.toValue = @[(id)[UIColor colorWithHex:@"f2606f"].CGColor,(id)[UIColor colorWithHex:@"f2606f"].CGColor];
        finishColor.duration = 0.5;
        finishColor.removedOnCompletion = NO;
        finishColor.fillMode = kCAFillModeBoth;
        [self.innerGradientLayer addAnimation:finishColor forKey:@"change inner colors"];
    }
    else {
        [self.innerGradientLayer removeAllAnimations];
        [self.runingLine removeAllAnimations];
    }
}

- (void)finishWaveAnimation
{
    _isWaveAnimation = NO;
    
    [self.waveLayer removeAllAnimations];
    
    [self.waveLayer removeFromSuperlayer];
}

- (void)switchStatus:(NEVPNStatus)status
{
    switch (status) {
        case NEVPNStatusConnecting:
            [self startWaveAnimation];
            break;
        case NEVPNStatusConnected: {
            // 连接成功，停掉圆环所有动画
            [self.runingLine removeAllAnimations];
            // 设置闭合的圆环起始结束点
            CABasicAnimation *endHeadAnimation = [CABasicAnimation animation];
            endHeadAnimation.keyPath = @"strokeStart";
//            endHeadAnimation.beginTime = 1.;
//            endHeadAnimation.duration = 1;
            endHeadAnimation.fromValue = [NSNumber numberWithDouble:self.runingLine.presentationLayer.strokeStart];
            endHeadAnimation.toValue = @0;
            
            CABasicAnimation *endTailAnimation = [CABasicAnimation animation];
            endTailAnimation.keyPath = @"strokeEnd";
//            endTailAnimation.beginTime = 1;
//            endTailAnimation.duration = 1;
            endTailAnimation.fromValue = [NSNumber numberWithDouble:self.runingLine.presentationLayer.strokeEnd];
            endTailAnimation.toValue = @1;
            
            CAAnimationGroup *animations = [CAAnimationGroup animation];
            animations.duration = 1;
            animations.animations = @[
//                                      rotateAnimation,
                                      endHeadAnimation,
                                      endTailAnimation
                                      ];
//            animations.repeatCount = INFINITY;
            animations.removedOnCompletion = NO;
            // 动画结束后layer保持动画最后的状态
            animations.fillMode = kCAFillModeBoth;
//            animations.delegate = self;
            [self.runingLine addAnimation:animations forKey:@"line rotation"];
            
            [self.waveLayer removeAllAnimations];
            [self.waveLayer removeFromSuperlayer];
            break;
        }
        case NEVPNStatusDisconnecting:
            [self.waveLayer removeAllAnimations];
            [self.waveLayer removeFromSuperlayer];
            break;
        case NEVPNStatusDisconnected: {
            CABasicAnimation *finishColor = [CABasicAnimation animationWithKeyPath:@"colors"];
            finishColor.fromValue = [((CAGradientLayer *)self.innerGradientLayer.presentationLayer) colors];
            finishColor.toValue = @[(id)[UIColor colorWithHex:@"5a78d8"].CGColor,(id)[UIColor colorWithHex:@"3a509c"].CGColor];
            finishColor.duration = 0.5;
            finishColor.removedOnCompletion = NO;
            finishColor.fillMode = kCAFillModeBoth;
            [self.innerGradientLayer addAnimation:finishColor forKey:@"change inner colors"];
            
            [self.runingLine removeAllAnimations];
            
            break;
        }
        case NEVPNStatusReasserting: {
            CABasicAnimation *finishColor = [CABasicAnimation animationWithKeyPath:@"colors"];
            
            finishColor.fromValue = [((CAGradientLayer *)self.innerGradientLayer.presentationLayer) colors];
            finishColor.toValue = @[(id)[UIColor colorWithHex:@"f2606f"].CGColor,(id)[UIColor colorWithHex:@"f2606f"].CGColor];
            finishColor.duration = 0.5;
            finishColor.removedOnCompletion = NO;
            finishColor.fillMode = kCAFillModeBoth;
            [self.innerGradientLayer addAnimation:finishColor forKey:@"change inner colors"];
            
            [self.runingLine removeAllAnimations];
            break;
        }
        default:
            break;
    }
    
    //NSLog(@"动画数量:%@",[self.innerGradientLayer animationKeys]);
    //NSLog(@"动画数量:%@",[self.runingLine animationKeys]);
}

// 创建动画中扩散的两道波纹
- (CABasicAnimation *)createWaveAnimation
{
    CABasicAnimation *wave = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    // 设置波纹面积放大五倍
    wave.fromValue = [NSNumber numberWithInt:1];
    wave.toValue = [NSNumber numberWithInt:5];
    // 设置扩散过程中波纹透明度变化
    CABasicAnimation *hide = [CABasicAnimation animationWithKeyPath:@"opacity"];
    hide.fromValue = [NSNumber numberWithFloat:0.2];
    hide.toValue = [NSNumber numberWithFloat:0.0f];
    
    // 统一添加到动画组
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[wave,hide];
    
    group.repeatCount = INFINITY; // 无限次重复
    group.duration = 2; // 一个周期持续时间
    
    group.removedOnCompletion = NO;
    group.fillMode = kCAFillModeBoth;
    // 设置动画匀速执行
    group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    
    return (CABasicAnimation *)group;
}



@end
