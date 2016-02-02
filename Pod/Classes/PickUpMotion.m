//
//  PickUpMotion.m
//  Pods
//
//  Created by guoshencheng on 2/2/16.
//
//

#import "PickUpMotion.h"
#import "PickUpMotion+Animation.h"
#import "PickUpMotion+Calculation.h"
#import "PickUpMotion+Layout.h"

@interface PickUpMotion() <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIView *currentPickedView;
@property (nonatomic, assign) CGPoint gestureStartLocation;

@end

@implementation PickUpMotion

- (id)init {
    if (self = [super init]) {
        _view = nil;
        _enabled = YES;
        _currentPickedView = nil;
        _animationType = PickUpMotionAnimationFade;
    }
    return self;
}

#pragma mark - Public Methods

- (void)attachToView:(UIView *)view {
    for (UIGestureRecognizer *gestureRecognizer in view.gestureRecognizers) {
        if (gestureRecognizer.delegate == self && [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
            return; // skip if already attached
        }
    }
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:view action:nil];
    panRecognizer.delegate = self;
    [view addGestureRecognizer:panRecognizer];
}

- (void)fadeOut {
    [self fadeOutWithCompletion:^(BOOL finished) {
        [self removeView];
    }];
}

- (void)flyBack {
    [self flyBackToView:self.currentPickedView completion:^(BOOL finished) {
        [self removeView];
    }];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.enabled && self.dataSource && [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        UIPanGestureRecognizer *gesture = (UIPanGestureRecognizer *)gestureRecognizer;
        if (![self shouldIgnoreGesture:gesture]) {
            [gestureRecognizer addTarget:self action:@selector(panGestureAction:)];
        }
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - PanGestureRecognizer Action

- (void)panGestureAction:(UIPanGestureRecognizer *)gesture {
    switch ([gesture state]) {
        case UIGestureRecognizerStateBegan:{
            [self panGestureDidBegin:gesture];
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            [self panGestureDidMove:gesture];
            break;
        }
            
        case UIGestureRecognizerStateEnded: {
            [self panGestureDidEnd:gesture];
            break;
        }
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStatePossible:
            [self panGestureDidEnd:gesture];
            break;
            
        default:
            break;
    }
}

- (void)panGestureDidBegin:(UIPanGestureRecognizer *)gesture {
    self.currentPickedView = [gesture view];
    if ([self.delegate respondsToSelector:@selector(pickUpmotion:willBeginMoveView:)]) [self.delegate pickUpmotion:self willBeginMoveView:self.currentPickedView];
    self.gestureStartLocation = [self locationOfGesture:gesture];
    [self pickUpView:self.currentPickedView];
    [self.view addGestureRecognizer:gesture];
    if ([self.delegate respondsToSelector:@selector(pickUpmotion:didBeginMoveView:)]) [self.delegate pickUpmotion:self didBeginMoveView:self.currentPickedView];

}

- (void)panGestureDidMove:(UIPanGestureRecognizer *)gesture {
    CGPoint movement = [self movementOfGesture:gesture fromLocation:self.gestureStartLocation];
    PickUpMotionDecelerateState decelerateState = [self decelerateStateOfView:self.currentPickedView withMovement:movement];
    movement = [self decelerateMovement:movement ofState:decelerateState];
    [self moveViewWithMovement:movement fromPickedView:self.currentPickedView];
    if ([self.delegate respondsToSelector:@selector(pickUpmotion:didMoveView:withMovement:)]) {
        [self.delegate pickUpmotion:self didMoveView:self.currentPickedView withMovement:movement];
    }
}

- (void)panGestureDidEnd:(UIPanGestureRecognizer *)gesture {
    if ([self.delegate respondsToSelector:@selector(pickUpmotion:willEndMoveView:withMovement:)]) {
        [self.delegate pickUpmotion:self willEndMoveView:self.currentPickedView withMovement:[self movementOfGesture:gesture fromLocation:self.gestureStartLocation]];
    }
    if (self.view && self.view.superview) {
        // motion view is not removed yet, then animate to reomve
        [self animateFinishMotionWithGesture:gesture];
    } else {
        // this condition will happen when manually end the motion
        [self finishMotionWithGesture:gesture];
    }
}


#pragma mark - Private Methods

- (void)animateFinishMotionWithGesture:(UIPanGestureRecognizer *)gesture {
    [self animateViewWithPickedView:self.currentPickedView completion:^(BOOL finished) {
        [self removeView];
        [self finishMotionWithGesture:gesture];
    }];
}

- (void)finishMotionWithGesture:(UIPanGestureRecognizer *)gesture {
    [gesture removeTarget:self action:@selector(panGestureAction:)];
    [self.currentPickedView addGestureRecognizer:gesture]; // switch gesture back to the view
    
    if ([self.delegate respondsToSelector:@selector(pickUpmotion:didEndMoveView:withMovement:)]) {
        [self.delegate pickUpmotion:self didEndMoveView:self.currentPickedView withMovement:[self movementOfGesture:gesture fromLocation:self.gestureStartLocation]];
    }
    self.currentPickedView = nil;
}

@end
