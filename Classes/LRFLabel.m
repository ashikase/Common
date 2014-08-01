/**
 * Author: Lance Fetters (aka. ashikase)
 * License: Apache License, version 2.0
 *          (http://www.apache.org/licenses/LICENSE-2.0)
 */

#import "LRFLabel.h"

@implementation LRFLabel

- (void)setText:(NSString *)text {
    NSString *oldText = [super text];

    [super setText:text];

    if ([text length] != [oldText length]) {
        id<LRFLabelDelegate> delegate = [self delegate];
        if ([delegate respondsToSelector:@selector(label:didSetText:)]) {
            [delegate label:self didSetText:text];
        }
    }
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
