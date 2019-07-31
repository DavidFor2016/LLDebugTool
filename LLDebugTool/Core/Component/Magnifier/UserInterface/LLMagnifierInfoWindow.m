//
//  LLMagnifierInfoWindow.m
//
//  Copyright (c) 2018 LLDebugTool Software Foundation (https://github.com/HDB-Li/LLDebugTool)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "LLMagnifierInfoWindow.h"
#import "LLMacros.h"
#import "LLFactory.h"
#import "UIView+LL_Utils.h"
#import "LLImageNameConfig.h"
#import "LLConfig.h"
#import "UIColor+LL_Utils.h"
#import "LLWindowManager.h"

@interface LLMagnifierInfoWindow ()

@property (nonatomic, strong) UIView *colorView;

@property (nonatomic, strong) UILabel *colorLabel;

@end

@implementation LLMagnifierInfoWindow

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initial];
    }
    return self;
}

- (void)updateColor:(NSString *)hexColor point:(CGPoint)point {
    self.colorView.backgroundColor = [UIColor LL_colorWithHex:hexColor];
    self.colorLabel.text = [NSString stringWithFormat:@"%@\nX: %0.1f, Y: %0.1f", hexColor, point.x, point.y];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect colorRect = CGRectMake(20, (self.LL_height - 20) / 2.0, 20, 20);
    if (!CGRectEqualToRect(self.colorView.frame, colorRect)) {
        self.colorView.frame = colorRect;
    }
    
    CGRect colorLabelRect = CGRectMake(self.colorView.LL_right + 20, 0, self.LL_width - self.colorView.LL_right - 20, self.LL_height);
    if (!CGRectEqualToRect(self.colorLabel.frame, colorLabelRect)) {
        self.colorLabel.frame = colorLabelRect;
    }
}

- (void)componentDidFinish {
    [[LLWindowManager shared] hideWindow:self animated:YES];
    [[LLWindowManager shared] hideWindow:[LLWindowManager shared].magnifierWindow animated:YES];
    [[LLWindowManager shared] showWindow:[LLWindowManager shared].suspensionWindow animated:YES];
    [[LLWindowManager shared] reloadMagnifierColorWindow];
    [[LLWindowManager shared] reloadMagnifierWindow];
}

#pragma mark - Primary
- (void)initial {
    if (!self.rootViewController) {
        self.rootViewController = [[UIViewController alloc] init];
        self.rootViewController.view.userInteractionEnabled = NO;
    }
    
    self.colorView = [LLFactory getView:self frame:CGRectZero];
    self.colorView.layer.borderColor = LLCONFIG_TEXT_COLOR.CGColor;
    self.colorView.layer.borderWidth = 0.5;
    
    self.colorLabel = [LLFactory getLabel:self frame:CGRectZero text:nil font:14 textColor:LLCONFIG_TEXT_COLOR];
    self.colorLabel.numberOfLines = 0;
}

@end