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
@property (assign, nonatomic) CGPoint panGestureStartLocation;
@property (assign, nonatomic) CGPoint swipeGestureStartLocation;
@property (assign, nonatomic) NSInteger cellNumber;
@property (assign, nonatomic) ChooseViewSlideDirection direction;

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
        [self generateCurrentView];
    }
    if (!self.currentView) {
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
    [self generatePrepareView];
    if ([self.delegate respondsToSelector:@selector(chooseViewWillSlide:)]) {
        [self.delegate chooseViewWillSlide:self];
    }
}

- (void)panGestureDidMove:(UIPanGestureRecognizer *)gesture {
    CGFloat xOffset = [gesture locationInView:self].x - self.panGestureStartLocation.x;
    if ((self.direction == ChooseViewSlideDirectionOrigin || self.direction == ChooseViewSlideDirectionLeft) && xOffset > 0) {
        [self changeToDirection:ChooseViewSlideDirectionRight];
    } else if ((self.direction == ChooseViewSlideDirectionOrigin || self.direction == ChooseViewSlideDirectionRight) && xOffset < 0) {
        [self changeToDirection:ChooseViewSlideDirectionLeft];
    }
    [self updateCurrentViewWithOffset:xOffset];
}

- (void)panGestureDidEnd:(UIPanGestureRecognizer *)gesture {
    CGFloat xOffset = [gesture locationInView:self].x - self.panGestureStartLocation.x;
    if (xOffset > self.frame.size.width / 4) {
        [self handlePushToRight];
    } else if(xOffset < -self.frame.size.width / 4) {
        [self handlePushToLeft];
    } else {
        [self recover];
    }
    [gesture removeTarget:self action:@selector(panGestureAction:)];
}

#pragma mark - PrivateMethod

- (NSInteger)abledCellCount {
    NSInteger count = self.cellNumber;
    return (count < 2) ? count : 2;
}

- (void)clear {
    [self removeCell:self.currentView];
    [self removeCell:self.nextView];
    self.currentView = nil;
    self.nextView = nil;
}

- (void)updateCellNumber {
    NSInteger cellNumber = [self.datasource numberOfViewsInChooseView:self];
    self.currentIndex = (cellNumber >= self.cellNumber) ? self.currentIndex : 0;
    self.cellNumber = cellNumber;
}

- (void)handlePushToRight {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.1 animations:^{
        [self updateCurrentViewWithOffset:weakSelf.frame.size.width * 1.5];
    } completion:^(BOOL finished) {
        [self pushNextView];
        if ([self.delegate respondsToSelector:@selector(chooseView:slideDirection:atIndex:)]) {
            [self.delegate chooseView:self slideDirection:ChooseViewSlideDirectionRight atIndex:self.currentIndex - 1];
        }
    }];
}

- (void)handlePushToLeft {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.1 animations:^{
        [weakSelf updateCurrentViewWithOffset:-weakSelf.frame.size.width * 1.5];
    } completion:^(BOOL finished) {
        [self pushNextView];
        if ([self.delegate respondsToSelector:@selector(chooseView:slideDirection:atIndex:)]) {
            [self.delegate chooseView:self slideDirection:ChooseViewSlideDirectionLeft atIndex:self.currentIndex - 1];
        }
    }];
}

- (void)resetCurrentView {
    [self updateCurrentViewWithOffset:0];
}

- (void)pushNextView {
    [self removeCell:self.currentView];
    self.currentView = self.nextView;
    self.currentIndex ++;
    self.nextView = self.prepareView;
    self.prepareView = nil;
    if (self.nextView) {
        [self resetCurrentView];
        [self addConstraintToCell:self.nextView];
    }
}

- (void)recover {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.2 animations:^{
        [weakSelf updateCurrentViewWithOffset:0];
    } completion:^(BOOL finished) {
        if ([self.delegate respondsToSelector:@selector(chooseViewDidRecover:)]) {
            [self.delegate chooseViewDidRecover:self];
        }
    }];
}

- (void)updateCurrentViewWithOffset:(CGFloat)offset {
    __weak typeof(self) weakSelf = self;
    [self.currentView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(weakSelf).centerOffset(CGPointMake(offset, fabs(offset) / self.frame.size.width * 20));
    }];
    self.currentView.transform = CGAffineTransformMakeRotation(M_PI_4 / 2 * offset / self.frame.size.width);
    [self layoutIfNeeded];
}

- (void)addConstraintToCell:(UIView *)cell {
    [self insertSubview:cell atIndex:0];
    __weak typeof(self) weakSelf = self;
    [cell mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(weakSelf).centerOffset(CGPointMake(0, 0));
        make.width.equalTo(@(weakSelf.frame.size.width));
        make.height.equalTo(@(weakSelf.frame.size.height));
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
    if (shouldIgnoreGesture) {
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

