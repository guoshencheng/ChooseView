//
//  PickUpMotion+Animation.h
//  Pods
//
//  Created by guoshencheng on 2/2/16.
//
//

#import "PickUpMotion.h"

@interface PickUpMotion (Animation)

- (void)animateViewWithPickedView:(UIView *)pickedView completion:(void (^)(BOOL finished))completion;

- (void)fadeOutWithCompletion:(void (^)(BOOL finished))completion;
- (void)flyBackToView:(UIView *)view completion:(void (^)(BOOL finished))completion;
- (void)flyAwayFromView:(UIView *)view completion:(void (^)(BOOL finished))completion;

@end
