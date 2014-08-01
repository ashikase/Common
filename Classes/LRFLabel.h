/**
 * Author: Lance Fetters (aka. ashikase)
 * License: Apache License, version 2.0
 *          (http://www.apache.org/licenses/LICENSE-2.0)
 */

#import <UIKit/UIKit.h>

@protocol LRFLabelDelegate;

@interface LRFLabel : UILabel
@property(nonatomic, assign) id<LRFLabelDelegate>delegate;
@end

@protocol LRFLabelDelegate <NSObject>;
- (void)label:(LRFLabel *)label didSetText:(NSString *)text;
@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
