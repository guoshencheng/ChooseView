//
//  ChooseView.m
//  ChooseView
//
//  Created by guoshencheng on 11/24/15.
//  Copyright © 2015 guoshencheng. All rights reserved.
//

#import "ChooseView.h"
#import "Masonry.h"
#define TRIGGER_SENSITIVITY 1.3

@interface ChooseView ()

@property (strong, nonatomic) NSMutableDictionary *reusabelCellIdDictionary;
@property (strong, nonatomic) UIView *prepareView;
@property (assign, nonatomic) NSInteger cellNumber;
@property (strong, nonatomic) UIView *maskView;
@property (assign, nonatomic) CGPoint panGestureStartLocation;
@property (assign, nonatomic) CGPoint swipeGestureStartLocation;
@property (assign, nonatomic) ChooseViewSlideDirection direction;
@property (assign, nonatomic) BOOL isFlyout;

@end

@implementation ChooseView

+ (instancetype)create {
    return [[ChooseView alloc] init];
}

- (void)setUpCurrentIndex:(NSInteger)currentIndex {
    self.currentIndex = currentIndex;
}

- (instancetype)init {
    if (self = [super init]) {
        [self addPanGesture];
        [self addSwipeGesture];
        [self initProperties];
        [self initMaskView];
        self.cellSize = [UIScreen mainScreen].bounds.size;
    }
    return self;
}

- (void)setDatasource:(id<ChooseViewDatasource>)datasource {
    _datasource = datasource;
    [self reloadData];
}

- (void)reloadData {
    [self clear];
    [self updateCellNumber];
    NSInteger abledCellCount = [self abledCellCount];
    for (int i = 0; i < abledCellCount; i++) {
        if (i == 0) {
            [self generateCurrentView];
        } else {
            [self generateNextView];
        }
    }
}

- (void)loadMoreData {
    [self updateCellNumber];
    [self removeCell:self.nextView];
    NSInteger abledCellCount = [self abledCellCount];
    if (abledCellCount > 1) {
        [self generateNextView];
    }
}

- (UIView *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index {
    NSString *nibName = [self.reusabelCellIdDictionary objectForKey:identifier];
    UIView *view = [[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] lastObject];
    return view;
}

- (void)registerCellWithNibName:(NSString *)nibName forCellReuseIdentifier:(NSString *)identifier {
    [self.reusabelCellIdDictionary setValue:nibName forKey:identifier];
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
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

- (void)swipeGestureAction:(UISwipeGestureRecognizer *)gesture {
    if ([self.delegate respondsToSelector:@selector(chooseView:swipeDirection:index:)]) {
        [self.delegate chooseView:self swipeDirection:gesture.direction index:self.currentIndex];
    }
}

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
            //            [self panGestureDidEnd:gesture];
            break;
        default:
            break;
    }
}

- (void)panGestureDidBegin:(UIPanGestureRecognizer *)gesture {
    self.panGestureStartLocation = [gesture locationInView:self];
    CGPoint velocity = [gesture velocityInView:self];
    //TODO ADD DIRECTION
    self.direction = ChooseViewSlideDirectionOrigin;
    [self generatePrepareView];
    if ([self.delegate respondsToSelector:@selector(chooseViewWillSlide:direction:)]) {
        [self.delegate chooseViewWillSlide:self direction:velocity.x > 0 ? ChooseViewSlideDirectionRight : ChooseViewSlideDirectionLeft];
    }
    if (self.currentView) {
        if (self.maskView.superview) [self.maskView removeFromSuperview];
        [self insertSubview:self.maskView belowSubview:self.currentView];
        [self.maskView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@(0));
            make.right.equalTo(@(0));
            make.top.equalTo(@(0));
            make.bottom.equalTo(@(0));
        }];
    }
}

- (void)panGestureDidMove:(UIPanGestureRecognizer *)gesture {
    CGFloat xOffset = [gesture locationInView:self].x - self.panGestureStartLocation.x;
    if ((self.direction == ChooseViewSlideDirectionOrigin || self.direction == ChooseViewSlideDirectionLeft) && xOffset > 0) {
        [self changeToDirection:ChooseViewSlideDirectionRight];
    } else if ((self.direction == ChooseViewSlideDirectionOrigin || self.direction == ChooseViewSlideDirectionRight) && xOffset < 0) {
        [self changeToDirection:ChooseViewSlideDirectionLeft];
    }
    self.maskView.alpha = (1 - fabs(xOffset) / (2 * self.frame.size.width)) * 0.5;
    if ([self.delegate respondsToSelector:@selector(chooseView:didSlideWithOffset:)]) {
        [self.delegate chooseView:self didSlideWithOffset:xOffset];
    }
    [self updateCurrentViewWithOffset:xOffset];
}

- (void)panGestureDidEnd:(UIPanGestureRecognizer *)gesture {
    CGFloat xOffset = [gesture locationInView:self].x - self.panGestureStartLocation.x;
    ChooseViewSlideDirection direction = [self directionWithOffset:xOffset];
    if ([self.delegate respondsToSelector:@selector(chooseViewDidEndSlide:direction:index:)]) {
        [self.delegate chooseViewDidEndSlide:self direction:direction index:self.currentIndex];
    }
    switch (direction) {
        case ChooseViewSlideDirectionRight:
            [self handlePushToRight];
            break;
        case ChooseViewSlideDirectionLeft:
            [self handlePushToLeft];
            break;
        default:
            [self recover];
            break;
    }
    [gesture removeTarget:self action:@selector(panGestureAction:)];
}

#pragma mark - PrivateMethod

- (ChooseViewSlideDirection)directionWithOffset:(CGFloat)offset {
    if (offset > self.frame.size.width / 4) {
        return ChooseViewSlideDirectionRight;
    } else if(offset < -self.frame.size.width / 4) {
        return ChooseViewSlideDirectionLeft;
    } else {
        return ChooseViewSlideDirectionOrigin;
    }
}

- (NSInteger)abledCellCount {
    NSInteger count = self.cellNumber;
    return (count < 2) ? count : 2;
}

- (void)clear {
    [self removeCell:self.currentView];
    [self removeCell:self.nextView];
    self.currentView = nil;
    self.nextView = nil;
    self.isFlyout = NO;
}

- (void)updateCellNumber {
    NSInteger cellNumber = [self.datasource numberOfViewsInChooseView:self];
    self.currentIndex = (cellNumber >= self.cellNumber) ? self.currentIndex : 0;
    self.cellNumber = cellNumber;
}

- (void)handlePushToRight {
    self.isFlyout = YES;
    self.currentIndex ++;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.25 animations:^{
        self.maskView.alpha = 0;
        [self updateCurrentViewWithOffset:weakSelf.frame.size.width * 2];
    } completion:^(BOOL finished) {
        [self.maskView removeFromSuperview];
        if (finished) {
            [self pushNextView];
            if ([self.delegate respondsToSelector:@selector(chooseView:slideDirection:atIndex:)]) {
                [self.delegate chooseView:self slideDirection:ChooseViewSlideDirectionRight atIndex:self.currentIndex - 1];
            }
        }
    }];
}

- (void)handlePushToLeft {
    self.isFlyout = YES;
    self.currentIndex ++;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.25 animations:^{
        self.maskView.alpha = 0;
        [weakSelf updateCurrentViewWithOffset:-weakSelf.frame.size.width * 2];
    } completion:^(BOOL finished) {
        [self.maskView removeFromSuperview];
        if (finished) {
            [self pushNextView];
            if ([self.delegate respondsToSelector:@selector(chooseView:slideDirection:atIndex:)]) {
                [self.delegate chooseView:self slideDirection:ChooseViewSlideDirectionLeft atIndex:self.currentIndex - 1];
            }
        }
    }];
}

- (void)resetCurrentView {
    [self updateCurrentViewWithOffset:0];
}

- (void)pushNextView {
    [self removeCell:self.currentView];
    self.currentView = self.nextView;
    self.nextView = !!self.prepareView ? self.prepareView : [self.datasource viewInChooseView:self atIndex:self.currentIndex + 1];
    self.prepareView = nil;
    if (self.nextView) {
        [self resetCurrentView];
        [self addConstraintToCell:self.nextView];
    }
    self.isFlyout = NO;
}

- (void)recover {
    self.isFlyout = NO;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.15 animations:^{
        self.maskView.alpha = 0.0;
        [weakSelf updateCurrentViewWithOffset:0];
    } completion:^(BOOL finished) {
        [self.maskView removeFromSuperview];
        if ([self.delegate respondsToSelector:@selector(chooseViewDidRecover:)]) {
            [self.delegate chooseViewDidRecover:self];
        }
    }];
}

- (void)updateCurrentViewWithOffset:(CGFloat)offset {
    CGFloat offsetY = fabs(offset) / self.frame.size.width * 20;
    __weak typeof(self) weakSelf = self;
    [self.currentView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(weakSelf).centerOffset(CGPointMake(offset, offsetY));
    }];
    self.currentView.transform = CGAffineTransformMakeRotation(M_PI_4 / 2 * offset / self.frame.size.width);
    [self layoutIfNeeded];
}

- (void)addConstraintToCell:(UIView *)cell {
    __weak typeof(self) weakSelf = self;
    [self insertSubview:cell atIndex:0];
    [cell mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(weakSelf).centerOffset(CGPointMake(0, 0));
        make.width.equalTo(@(weakSelf.cellSize.width));
        make.height.equalTo(@(weakSelf.cellSize.height));
    }];
    [self layoutIfNeeded];
}

- (void)generateNextView {
    self.nextView = [self.datasource viewInChooseView:self atIndex:self.currentIndex + 1];
    [self addConstraintToCell:self.nextView];
}

- (void)generateCurrentView {
    self.currentView = [self.datasource viewInChooseView:self atIndex:self.currentIndex];
    [self addConstraintToCell:self.currentView];
}

- (void)generatePrepareView {
    if (![self isCellOver] && ![self loadToEnd]) {
        self.prepareView = [self.datasource viewInChooseView:self atIndex:self.currentIndex + 2];
    }
}

- (void)initProperties {
    self.reusabelCellIdDictionary = [[NSMutableDictionary alloc] init];
    self.currentIndex = 0;
    self.direction = 0;
    self.isFlyout = NO;
}

- (void)initMaskView {
    self.maskView = [[UIView alloc] init];
    self.maskView.backgroundColor = [UIColor blackColor];
}

- (void)changeToDirection:(ChooseViewSlideDirection)direction {
    ChooseViewSlideDirection lastDirection = self.direction;
    self.direction = direction;
    if ([self.delegate respondsToSelector:@selector(chooseView:changeDirection:fromDirection:)]) {
        [self.delegate chooseView:self changeDirection:self.direction fromDirection:lastDirection];
    }
}

- (void)addSwipeGesture {
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureAction:)];
    [swipeUp setDirection:UISwipeGestureRecognizerDirectionUp];
    [self addGestureRecognizer:swipeUp];
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureAction:)];
    [swipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
    [self addGestureRecognizer:swipeDown];
}

- (void)addPanGesture {
    for (UIGestureRecognizer *gestureRecognizer in self.gestureRecognizers) {
        if (gestureRecognizer.delegate == self && [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
            return; // skip if already attached
        }
    }
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:nil];
    panRecognizer.delegate = self;
    [self addGestureRecognizer:panRecognizer];
}

- (BOOL)shouldIgnoreGesture:(UIPanGestureRecognizer *)gesture {
    CGPoint velocity = [gesture velocityInView:self];
    //MotionHorizontal
    if (!self.currentView) {
        return YES;
    }
    BOOL shouldIgnoreGesture = ABS(velocity.y * TRIGGER_SENSITIVITY) > ABS(velocity.x);
    if (shouldIgnoreGesture || self.isFlyout) {
        return YES;
    } else {
        if ([self.delegate respondsToSelector:@selector(chooseView:shouldIgnoreGesture:)]) {
            return [self.delegate chooseView:self shouldIgnoreGesture:gesture];
        } else {
            return NO;
        }
    }
}

- (BOOL)isCellOver {
    return self.currentIndex + 1 >= [self.datasource numberOfViewsInChooseView:self];
}

- (BOOL)loadToEnd {
    return self.currentIndex + 2 >= [self.datasource numberOfViewsInChooseView:self];
}

- (void)removeCell:(UIView *)cell {
    [cell.layer removeAllAnimations];
    [cell removeFromSuperview];
    //TODO insert cell into reusepool
}

@end

