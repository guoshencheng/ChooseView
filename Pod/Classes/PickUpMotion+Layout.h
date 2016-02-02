//
//  PickUpMotion+Layout.h
//  Pods
//
//  Created by guoshencheng on 2/2/16.
//
//

#import "PickUpMotion.h"

@interface PickUpMotion (Layout)

- (void)pickUpView:(UIView *)pickedView;

- (void)moveViewWithMovement:(CGPoint)movement fromPickedView:(UIView *)pickedView;

- (void)removeView;

@end
