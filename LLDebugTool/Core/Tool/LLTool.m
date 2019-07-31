//
//  LLTool.m
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

#import "LLTool.h"
#import "LLConfig.h"
#import "LLMacros.h"
#import "LLRoute.h"
#import "LLFactory.h"
#import "UIView+LL_Utils.h"

static LLTool *_instance = nil;

static CGFloat _toastTime = 2.0;

static NSDateFormatter *_dateFormatter = nil;
static NSDateFormatter *_dayDateFormatter = nil;
static NSDateFormatter *_staticDateFormatter = nil;
static NSNumberFormatter *_numberFormatter = nil;

static UILabel *_toastLabel = nil;
static UILabel *_loadingLabel = nil;
static NSTimer *_loadingTimer = nil;

static unsigned long long _absolutelyIdentity = 0;

@implementation LLTool

#pragma mark - Class Method
+ (NSString *)absolutelyIdentity {
    @synchronized (self) {
        _absolutelyIdentity++;
        return [NSString stringWithFormat:@"%lld",_absolutelyIdentity];
    }
}

+ (NSString *)stringFromDate:(NSDate *)date {
    return [[self dateFormatter] stringFromDate:date];
}

+ (NSDate *)dateFromString:(NSString *)string {
    return [[self dateFormatter] dateFromString:string];
}

+ (NSString *)dayStringFromDate:(NSDate *)date {
    return [[self dayDateFormatter] stringFromDate:date];
}

+ (NSDate *)dayDateFromString:(NSString *)string {
    return [[self dayDateFormatter] dateFromString:string];
}

+ (NSString *)staticStringFromDate:(NSDate *)date {
    return [[self staticDateFormatter] stringFromDate:date];
}

+ (NSDate *)staticDateFromString:(NSString *)string {
    return [[self staticDateFormatter] dateFromString:string];
}

+ (NSString *)convertJSONStringFromData:(NSData *)data
{
    if ([data length] == 0) {
        return @"";
    }
    NSString *prettyString = @"";
    
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    if ([NSJSONSerialization isValidJSONObject:jsonObject]) {
        prettyString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:NULL] encoding:NSUTF8StringEncoding];
        // NSJSONSerialization escapes forward slashes. We want pretty json, so run through and unescape the slashes.
        prettyString = [prettyString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
    } else {
        prettyString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    return prettyString ?: @"";
}

+ (NSString *)convertJSONStringFromDictionary:(NSDictionary *)dictionary {
    
    if (dictionary.allKeys.count == 0) {
        return @"";
    }
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                       options:0
                                                         error:&error];

    NSString *jsonString = @"";
    
    if (jsonData) {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    jsonString = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    return jsonString ?: @"";
}

+ (BOOL)createDirectoryAtPath:(NSString *)path {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error;
        [[NSFileManager  defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            [LLRoute logWithMessage:[NSString stringWithFormat:@"Create folder fail, path = %@, error = %@",path,error.description] event:kLLDebugToolEvent];
            NSAssert(!error, error.description);
            return NO;
        }
        return YES;
    }
    return YES;
}

+ (CGRect)rectWithPoint:(CGPoint)point otherPoint:(CGPoint)otherPoint {
    
    CGFloat x = MIN(point.x, otherPoint.x);
    CGFloat y = MIN(point.y, otherPoint.y);
    CGFloat maxX = MAX(point.x, otherPoint.x);
    CGFloat maxY = MAX(point.y, otherPoint.y);
    CGFloat width = maxX - x;
    CGFloat height = maxY - y;
    // Return rect nearby
    CGFloat gap = 1 / 2.0;
    if (width == 0) {
        width = gap;
    }
    if (height == 0) {
        height = gap;
    }
    return CGRectMake(x, y, width, height);
}

+ (void)toastMessage:(NSString *)message {
    if (_toastLabel) {
        [_toastLabel removeFromSuperview];
        _toastLabel = nil;
    }
    
    __block UILabel *label = [LLFactory getLabel:[UIApplication sharedApplication].delegate.window frame:CGRectMake(20, 0, LL_SCREEN_WIDTH - 40, 100) text:message font:17 textColor:[UIColor whiteColor]];
    [LLTool setLabel:label numberOfLines:0];
    label.textAlignment = NSTextAlignmentCenter;
    label.alpha = 0;
    label.backgroundColor = [UIColor blackColor];
    [label sizeToFit];
    [label setCornerRadius:label.font.lineHeight / 2.0];
    label.center = CGPointMake(LL_SCREEN_WIDTH / 2.0, LL_SCREEN_HEIGHT / 2.0);
    _toastLabel = label;
    [UIView animateWithDuration:0.25 animations:^{
        label.alpha = 1;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_toastTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.1 animations:^{
                _toastLabel.alpha = 0;
            } completion:^(BOOL finished) {
                [_toastLabel removeFromSuperview];
                _toastLabel = nil;
            }];
        });
    }];
}

+ (void)loadingMessage:(NSString *)message {
    if (_loadingLabel) {
        [_loadingLabel removeFromSuperview];
        _loadingLabel = nil;
    }
    
    __block UILabel *label = [LLFactory getLabel:[UIApplication sharedApplication].delegate.window frame:CGRectMake(20, 0, LL_SCREEN_WIDTH - 40, 100) text:message font:17 textColor:[UIColor whiteColor]];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.LL_horizontalPadding = 20;
    label.LL_verticalPadding = 5;
    [label sizeToFit];
    
    label.layer.cornerRadius = label.font.lineHeight / 2.0;
    label.layer.masksToBounds = YES;
    label.center = CGPointMake(LL_SCREEN_WIDTH / 2.0, LL_SCREEN_HEIGHT / 2.0);
    label.alpha = 0;
    label.backgroundColor = [UIColor blackColor];
    label.textColor = [UIColor whiteColor];
    [[UIApplication sharedApplication].delegate.window addSubview:label];
    _loadingLabel = label;
    [UIView animateWithDuration:0.25 animations:^{
        label.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
    [self startLoadingMessageTimer];
}

+ (void)hideLoadingMessage {
    if (_loadingLabel.superview) {
        [self removeLoadingMessageTimer];
        [UIView animateWithDuration:0.1 animations:^{
            _loadingLabel.alpha = 0;
        } completion:^(BOOL finished) {
            [_loadingLabel removeFromSuperview];
            _loadingLabel = nil;
        }];
    }
}

+ (void)startLoadingMessageTimer {
    [self removeLoadingMessageTimer];
    _loadingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(loadingMessageTimerAction:) userInfo:nil repeats:YES];
}

+ (void)removeLoadingMessageTimer {
    if ([_loadingTimer isValid]) {
        [_loadingTimer invalidate];
        _loadingTimer = nil;
    }
}

+ (void)loadingMessageTimerAction:(NSTimer *)timer {
    if (_loadingLabel.superview) {
        if ([_loadingLabel.text hasSuffix:@"..."]) {
            _loadingLabel.text = [_loadingLabel.text substringToIndex:_loadingLabel.text.length - 3];
        } else {
            _loadingLabel.text = [_loadingLabel.text stringByAppendingString:@"."];
        }
    } else {
        [self removeLoadingMessageTimer];
    }
}

+ (NSString *)stringFromFrame:(CGRect)frame {
    return [NSString stringWithFormat:@"{{%@, %@}, {%@, %@}}",[LLTool formatNumber:@(frame.origin.x)],[LLTool formatNumber:@(frame.origin.y)],[LLTool formatNumber:@(frame.size.width)],[LLTool formatNumber:@(frame.size.height)]];
}

+ (UIColor *)colorFromObject:(NSObject *)object {
    CGFloat hue = (((NSUInteger)object >> 4) % 256) / 255.0;
    return [UIColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:1.0];
}

+ (UIInterfaceOrientationMask)infoPlistSupportedInterfaceOrientationsMask
{
    NSArray<NSString *> *supportedOrientations = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UISupportedInterfaceOrientations"];
    UIInterfaceOrientationMask supportedOrientationsMask = 0;
    if ([supportedOrientations containsObject:@"UIInterfaceOrientationPortrait"]) {
        supportedOrientationsMask |= UIInterfaceOrientationMaskPortrait;
    }
    if ([supportedOrientations containsObject:@"UIInterfaceOrientationMaskLandscapeRight"]) {
        supportedOrientationsMask |= UIInterfaceOrientationMaskLandscapeRight;
    }
    if ([supportedOrientations containsObject:@"UIInterfaceOrientationMaskPortraitUpsideDown"]) {
        supportedOrientationsMask |= UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    if ([supportedOrientations containsObject:@"UIInterfaceOrientationLandscapeLeft"]) {
        supportedOrientationsMask |= UIInterfaceOrientationMaskLandscapeLeft;
    }
    return supportedOrientationsMask;
}

+ (void)setView:(UIView *)view
           cornerRadius:(CGFloat)cornerRadius {
    view.layer.cornerRadius = cornerRadius;
    view.layer.masksToBounds = YES;
}

+ (void)setView:(UIView *)view
           borderWidth:(CGFloat)borderWidth {
    [self setView:view
                   borderColor:nil
             borderWidth:borderWidth];
}

+ (void)setView:(UIView *)view
                 borderColor:(UIColor *_Nullable)color
           borderWidth:(CGFloat)borderWidth {
    view.layer.borderColor = color.CGColor;
    view.layer.borderWidth = borderWidth;
}

+ (void)setLabel:(UILabel *)label
           numberOfLines:(NSInteger)numberOfLines {
    label.numberOfLines = numberOfLines;
    if (numberOfLines != 1) {
        label.lineBreakMode = NSLineBreakByCharWrapping;
    }
}

+ (NSString *)formatNumber:(NSNumber *)number {
    return [[self numberFormatter] stringFromNumber:number];
}

#pragma mark - Lazy load
+ (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = [LLConfig sharedConfig].dateFormatter;
    }
    return _dateFormatter;
}

+ (NSDateFormatter *)dayDateFormatter {
    if (!_dayDateFormatter) {
        _dayDateFormatter = [[NSDateFormatter alloc] init];
        _dayDateFormatter.dateFormat = @"yyyy-MM-dd";
    }
    return _dayDateFormatter;
}

+ (NSDateFormatter *)staticDateFormatter {
    if (!_staticDateFormatter) {
        _staticDateFormatter = [[NSDateFormatter alloc] init];
        _staticDateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    }
    return _staticDateFormatter;
}

+ (NSNumberFormatter *)numberFormatter {
    if (!_numberFormatter) {
        _numberFormatter = [[NSNumberFormatter alloc] init];
        _numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        _numberFormatter.maximumFractionDigits = 2;
        _numberFormatter.usesGroupingSeparator = NO;
    }
    return _numberFormatter;
}

#pragma mark - DEPRECATED

+ (instancetype)sharedTool {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[LLTool alloc] init];
    });
    return _instance;
}

- (NSString *)absolutelyIdentity {
    return [LLTool absolutelyIdentity];
}

- (NSString *)stringFromDate:(NSDate *)date {
    return [LLTool stringFromDate:date];
}

- (NSDate *)dateFromString:(NSString *)string {
    return [LLTool dateFromString:string];
}

- (NSString *)dayStringFromDate:(NSDate *)date {
    return [LLTool dayStringFromDate:date];
}

- (NSDate *)staticDateFromString:(NSString *)string {
    return [LLTool staticDateFromString:string];
}

- (NSString *)staticStringFromDate:(NSDate *)date {
    return [LLTool staticStringFromDate:date];
}

- (void)toastMessage:(NSString *)message {
    [LLTool toastMessage:message];
}

@end