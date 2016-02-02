//
//  PickUpMotion+Calculation.h
//  Pods
//
//  Created by guoshencheng on 2/2/16.
//
//

#import "PickUpMotion.h"

typedef struct {
    PickUpMotionDirection horizontalDirection;
    BOOL needDecelerateHorizontal;
} PickUpMotionDecelerateState;

@interface PickUpMotion (Calculation)

/**
 * The frame of view in the container area, usually its the origin picked up view
 **/
- (CGRect)frameOfView:(UIView *)view;

/**
 * The new center position of view in the container area with a certain movement
 **/
- (CGPoint)centerOfView:(UIView *)view withMovement:(CGPoint)movement;

/**
 * The new center position make the current motion view off screen with the direction against to the given view(usually the picked view)
 **/
- (CGPoint)centerOutOfScreenAgainstView:(UIView *)view;
- (CGPoint)locationOfGesture:(UIPanGestureRecognizer *)gesture;
- (CGPoint)movementOfGesture:(UIPanGestureRecognizer *)gesture fromLocation:(CGPoint)startLocation;
- (CGPoint)decelerateMovement:(CGPoint)movement ofState:(PickUpMotionDecelerateState)decelerateState;
- (PickUpMotionDecelerateState)decelerateStateOfView:(UIView *)view withMovement:(CGPoint)movement;
- (BOOL)shouldIgnoreGesture:(UIPanGestureRecognizer *)gesture;

@end
