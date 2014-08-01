/**
 * Author: Lance Fetters (aka. ashikase)
 * License: Apache License, version 2.0
 *          (http://www.apache.org/licenses/LICENSE-2.0)
 */

#import <UIKit/UIKit.h>

@interface LRFStatusPopup: UIViewController
@property(nonatomic, readonly) UILabel *textLabel;
@property(nonatomic, readonly) UILabel *detailTextLabel;
@property(nonatomic, assign) BOOL showsElapsedTime;
- (void)show:(BOOL)animated;
- (void)hide:(BOOL)animated;
- (void)hide:(BOOL)animated blinkCount:(NSUInteger)blinkCount;
- (void)startElapsedTimer;
- (void)stopElapsedTimer;
@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
