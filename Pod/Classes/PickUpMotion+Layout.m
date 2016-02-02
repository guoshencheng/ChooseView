//
//  PickUpMotion+Layout.m
//  Pods
//
//  Created by guoshencheng on 2/2/16.
//
//

#import "PickUpMotion+Layout.h"
#import "PickUpMotion+Calculation.h"

@implementation PickUpMotion (Layout)

- (void)pickUpView:(UIView *)pickedView {
    [self removeView]; // remove old view if needed
    UIImage *snapshot = [self imageWithView:pickedView];
    self.view = [[UIView alloc] initWithFrame:[self frameOfView:pickedView]];
    [self.view addSubview:[[UIImageView alloc] initWithImage:snapshot]];
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.view.layer setMasksToBounds:YES];
    [[self.dataSource containerViewOfPickUpmotion:self] addSubview:self.view];
}

- (void)moveViewWithMovement:(CGPoint)movement fromPickedView:(UIView *)pickedView {
    self.view.center = [self centerOfView:pickedView withMovement:movement];
    self.view.transform = CGAffineTransformMakeRotation(M_PI_4 / 2 * movement.x / 320.0);
    if ([self.delegate respondsToSelector:@selector(pickUpmotion:viewAlphaForMovement:)]) {
        self.view.alpha = [self.delegate pickUpmotion:self viewAlphaForMovement:movement];
    }
}

- (void)removeView {
    if (self.view && self.view.superview) {
        [self.view removeFromSuperview];
    }
}

#pragma mark - Private Methods

- (UIImage *)imageWithView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
