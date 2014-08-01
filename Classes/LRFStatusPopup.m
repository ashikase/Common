/**
 * Author: Lance Fetters (aka. ashikase)
 * License: Apache License, version 2.0
 *          (http://www.apache.org/licenses/LICENSE-2.0)
 */

#import "LRFStatusPopup.h"

#import "LRFLabel.h"

#include <mach/mach_time.h>

// NOTE: Returns time in nanoseconds.
static uint64_t currentProcessTime(void) {
    static mach_timebase_info_data_t timebase;
    if (timebase.denom == 0) {
        mach_timebase_info(&timebase);
    }
    return mach_absolute_time() * timebase.numer / timebase.denom;
}

@interface LRFStatusPopup () <LRFLabelDelegate>
@end

@implementation LRFStatusPopup {
    UIWindow *window_;
    UIView *statusView_;
    UILabel *elapsedTextLabel_;

    BOOL isAnimating_;
    NSOperationQueue *operationQueue_;
}

@synthesize textLabel = textLabel_;
@synthesize detailTextLabel = detailTextLabel_;
@synthesize showsElapsedTime = showsElapsedTime_;

#pragma mark - Creation and Destruction

- (id)init {
    self = [super init];
    if (self != nil) {
        // Create a window to hold the view.
        // NOTE: Show the window just below the alert window.
        UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [window setOpaque:NO];
        [window setWindowLevel:(UIWindowLevelAlert - 1)];
        window_ = window;
    }
    return self;
}

- (void)dealloc {
    [operationQueue_ release];
    [elapsedTextLabel_ release];
    [detailTextLabel_ release];
    [textLabel_ release];
    [statusView_ release];
    [window_ release];
    [super dealloc];
}

#pragma mark - View

- (void)loadView {
    // Create status view and subviews.
    UIView *statusView = [[UIView alloc] initWithFrame:CGRectZero];
    [statusView setBackgroundColor:[UIColor colorWithRed:(36.0 / 255.0) green:(132.0 / 255.0) blue:(232.0 / 255.0) alpha:0.9]];
    CALayer *layer = [statusView layer];
    [layer setCornerRadius:8.0];
    [layer setBorderColor:[[UIColor blackColor] CGColor]];
    [layer setBorderWidth:1.0];
    statusView_ = statusView;

    LRFLabel *textLabel = (LRFLabel *)[self textLabel];
    [textLabel setDelegate:self];
    [textLabel setFont:[UIFont boldSystemFontOfSize:20.0]];
    [textLabel setTextColor:[UIColor whiteColor]];
    [textLabel setTextAlignment:NSTextAlignmentCenter];
    [statusView addSubview:textLabel];
    textLabel_ = textLabel;

    LRFLabel *detailTextLabel = (LRFLabel *)[self detailTextLabel];
    [detailTextLabel setDelegate:self];
    [detailTextLabel setNumberOfLines:0];
    [detailTextLabel setFont:[UIFont systemFontOfSize:18.0]];
    [detailTextLabel setTextColor:[UIColor whiteColor]];
    [detailTextLabel setTextAlignment:NSTextAlignmentCenter];
    [statusView addSubview:detailTextLabel];
    detailTextLabel_ = detailTextLabel;

    UILabel *elapsedTextLabel = (UILabel *)[self elapsedTextLabel];
    [elapsedTextLabel setFont:[UIFont systemFontOfSize:18.0]];
    [elapsedTextLabel setTextColor:[UIColor whiteColor]];
    [elapsedTextLabel setTextAlignment:NSTextAlignmentCenter];
    [statusView addSubview:elapsedTextLabel];
    elapsedTextLabel_ = elapsedTextLabel;

    // Create container for view controller.
    UIView *view = [[UIView alloc] initWithFrame:((CGRect){CGPointZero, [window_ bounds].size})];
    [view setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.2]];
    [view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [view addSubview:statusView];
    [self setView:view];

    // Clean-up.
    [view release];
}

- (void)viewDidLayoutSubviews {
    if (!isAnimating_) {
        UIView *view = [self view];
        static CGFloat width = 280.0;

        UILabel *textLabel = [self textLabel];
        [textLabel sizeToFit];
        CGRect textLabelFrame = [textLabel frame];
        textLabelFrame.size.width = (width - 20.0);
        textLabelFrame.origin.x = 0.5 * (width - textLabelFrame.size.width);
        textLabelFrame.origin.y = 10.0;
        [textLabel setFrame:textLabelFrame];

        UILabel *detailTextLabel = [self detailTextLabel];
        [detailTextLabel sizeToFit];
        CGRect detailTextLabelFrame = [detailTextLabel frame];
        detailTextLabelFrame.size.width = (width - 20.0);
        detailTextLabelFrame.origin.x = 0.5 * (width - detailTextLabelFrame.size.width);
        detailTextLabelFrame.origin.y = 20.0 + textLabelFrame.size.height;
        [detailTextLabel setFrame:detailTextLabelFrame];

        CGFloat height = (30.0 + textLabelFrame.size.height + detailTextLabelFrame.size.height);
        if ([self showsElapsedTime]) {
            UILabel *elapsedTextLabel = [self elapsedTextLabel];
            [elapsedTextLabel sizeToFit];
            CGRect elapsedTextLabelFrame = [elapsedTextLabel frame];
            elapsedTextLabelFrame.size.width = (width - 20.0);
            elapsedTextLabelFrame.origin.x = 0.5 * (width - elapsedTextLabelFrame.size.width);
            elapsedTextLabelFrame.origin.y = 30.0 + textLabelFrame.size.height + detailTextLabelFrame.size.height;
            [elapsedTextLabel setFrame:elapsedTextLabelFrame];

            height += (10.0 + elapsedTextLabelFrame.size.height);
        }

        CGRect viewBounds = [view bounds];
        CGRect statusViewFrame;
        statusViewFrame.size = CGSizeMake(width, height);
        statusViewFrame.origin.x = 0.5 * (viewBounds.size.width - statusViewFrame.size.width),
        statusViewFrame.origin.y = 0.5 * (viewBounds.size.height - statusViewFrame.size.height),
        [statusView_ setFrame:statusViewFrame];
    }
}

#pragma mark - Presentation

- (void)show:(BOOL)animated {
    if (!isAnimating_) {
        if (IOS_LT(4_0)) {
            [window_ addSubview:[self view]];
        } else {
            [window_ setRootViewController:self];
        }
        [window_ setHidden:NO];

        if (animated) {
            isAnimating_ = YES;

            [statusView_ setAlpha:0.0];
            [statusView_ setTransform:CGAffineTransformMakeScale(0.8, 0.8)];
            [UIView animateWithDuration:0.2
                animations:^{
                    [statusView_ setAlpha:1.0];
                    [statusView_ setTransform:CGAffineTransformIdentity];
                }
                completion:^(BOOL finished) {
                    isAnimating_ = NO;
                }];
        }
    }
}

- (void)hide:(BOOL)animated {
    [self hide:animated blinkCount:0];
}

- (void)hide:(BOOL)animated blinkCount:(NSUInteger)blinkCount {
    if (!isAnimating_) {
        if (animated) {
            isAnimating_ = YES;

            if (blinkCount > 0) {
                [UIView animateWithDuration:0.2 delay:0.2 options:UIViewAnimationOptionCurveLinear
                    animations:^{
                        [statusView_ setAlpha:0.0];
                    }
                    completion:^(BOOL finished) {
                        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseIn
                            animations:^{
                                [statusView_ setAlpha:1.0];
                            }
                            completion:^(BOOL finished) {
                                isAnimating_ = NO;
                                [self hide:animated blinkCount:(blinkCount - 1)];
                            }];
                    }];
            } else {
                [UIView animateWithDuration:0.2 delay:1.0 options:UIViewAnimationOptionCurveEaseIn
                    animations:^{
                        [statusView_ setAlpha:0.0];
                        [statusView_ setTransform:CGAffineTransformMakeScale(0.8, 0.8)];
                    }
                    completion:^(BOOL finished) {
                        [[self view] removeFromSuperview];
                        [window_ setHidden:YES];
                        isAnimating_ = NO;
                    }];
            }
        } else {
            [[self view] removeFromSuperview];
            [window_ setHidden:YES];
        }
    }
}

#pragma mark - Properties

- (UILabel *)detailTextLabel {
    if (detailTextLabel_ == nil) {
        detailTextLabel_ = [[LRFLabel alloc] initWithFrame:CGRectZero];
    }
    return detailTextLabel_;
}

- (UILabel *)elapsedTextLabel {
    if (elapsedTextLabel_ == nil) {
        elapsedTextLabel_ = [[UILabel alloc] initWithFrame:CGRectZero];
        [elapsedTextLabel_ setText:@"Elapsed Time: 00:00:000"];
    }
    return elapsedTextLabel_;
}

- (UILabel *)textLabel {
    if (textLabel_ == nil) {
        textLabel_ = [[LRFLabel alloc] initWithFrame:CGRectZero];
    }
    return textLabel_;
}

- (void)setShowsElapsedTime:(BOOL)showsElapsedTime {
    if (showsElapsedTime_ != showsElapsedTime) {
        showsElapsedTime_ = showsElapsedTime;
        [[self view] setNeedsLayout];
    }
}

#pragma mark - Timer

- (void)startElapsedTimer {
    if ([self showsElapsedTime]) {
        if (operationQueue_ == nil) {
            uint64_t routineStartTime = currentProcessTime();
            UILabel *elapsedTextLabel = [self elapsedTextLabel];

            NSBlockOperation *operation = [NSBlockOperation new];
            [operation addExecutionBlock:^(void){
                while (1) {
                    if (![operation isCancelled]) {
                        unsigned elapsed = floorf(0.000001 * (currentProcessTime() - routineStartTime));
                        unsigned seconds = 0.001 * elapsed;
                        unsigned minutes = MIN((seconds / 60), 100);
                        if (minutes < 100) {
                            unsigned milli = elapsed - (1000 * seconds);
                            seconds = seconds % 60;
                            dispatch_sync(dispatch_get_main_queue(), ^(void) {
                                elapsedTextLabel.text = [NSString stringWithFormat:
                                    @"Elapsed Time: %02u:%02u:%03u", minutes, seconds, milli];
                            });
                            usleep(1000);
                        } else {
                            break;
                        }
                    } else {
                        break;
                    }
                }
            }];

            operationQueue_ = [NSOperationQueue new];
            [operationQueue_ addOperation:operation];
        }
    }
}

- (void)stopElapsedTimer {
    [operationQueue_ cancelAllOperations];
    [operationQueue_ release];
    operationQueue_ = nil;
}

#pragma mark - Delegate (LRFLabelDelegate)

- (void)label:(LRFLabel *)label didSetText:(NSString *)text {
    [[self view] setNeedsLayout];
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
