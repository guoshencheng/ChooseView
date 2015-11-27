//
//  ChooseView.m
//  ChooseView
//
//  Created by guoshencheng on 11/24/15.
//  Copyright © 2015 guoshencheng. All rights reserved.
//

#import "ChooseView.h"
#import "Masonry.h"

@implementation UIView (ChooseView)


@end

@interface ChooseView ()

@property (strong, nonatomic) NSMutableDictionary *reusabelCellIdDictionary;
@property (strong, nonatomic) UIView *prepareView;
@property (assign, nonatomic) CGPoint panGestureStartLocation;
@property (assign, nonatomic) CGPoint swipeGestureStartLocation;
@property (assign, nonatomic) NSInteger cellNumber;
@property (assign, nonatomic) NSInteger currentIndex;
@property (assign, nonatomic) NSInteger direction;

@end

@implementation ChooseView

+ (instancetype)create {
    return [[ChooseView alloc] init];
}

- (instancetype)init {
    if (self = [super init]) {
        [self addPanGesture];
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
            [self initCurrentCell];
        } else {
            [self initNextCell];
        }
    }
}

- (void)loadMoreData {
    [self updateCellNumber];
    [self removeCell:self.nextView];
    NSInteger abledCellCount = [self abledCellCount];
    if (abledCellCount > 1) {
        [self initNextCell];
    }
    if (!self.currentView) {
        [self initCurrentCell];
    }
}

- (void)registerCellWithNibName:(NSString *)nibName forCellReuseIdentifier:(NSString *)identifier {
    [self.reusabelCellIdDictionary setValue:nibName forKey:identifier];
}

- (UIView *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index {
    NSString *nibName = [self.reusabelCellIdDictionary objectForKey:identifier];
    UIView *view = [[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] lastObject];
    return view;
}

#pragma mark - GestureActionDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (!self.currentView) {
        return NO;
    }
    return YES;
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
        default:
            break;
    }
}

- (void)panGestureDidBegin:(UIPanGestureRecognizer *)gesture {
    self.panGestureStartLocation = [gesture locationInView:self];
    self.direction = 0;
    if (!self.currentView) return;
    if ([self.delegate respondsToSelector:@selector(chooseViewWillSlide:)]) {
        [self.delegate chooseViewWillSlide:self];
    }
}

- (void)panGestureDidMove:(UIPanGestureRecognizer *)gesture {
    CGFloat xOffset = [gesture locationInView:self].x - self.panGestureStartLocation.x;
    CGFloat yOffset = [gesture locationInView:self].y - self.panGestureStartLocation.y;
    if (fabs(xOffset) > fabs(yOffset)) {
        if ((self.direction == 0 || self.direction == -1) && xOffset > 0) {
            [self changeToDirection:1];
        } else if ((self.direction == 0 || self.direction == 1) && xOffset < 0) {
            [self changeToDirection:-1];
        }
        if (![self isCellOver] && ![self loadToEnd]) {
            [self generatePrepareView];
        }
        if (xOffset > 0) {
            if ([self.delegate respondsToSelector:@selector(chooseView:didSlideRightWithOffset:)]) {
                [self.delegate chooseView:self didSlideRightWithOffset:fabs(xOffset)];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(chooseView:didSlideLeftWithOffset:)]) {
                [self.delegate chooseView:self didSlideLeftWithOffset:fabs(xOffset)];
            }
        }
        
        [self updateCurrentViewWithOffset:xOffset];
    }
}

- (void)changeToDirection:(NSInteger)direction {
    NSInteger lastDirection = self.direction;
    self.direction = direction;
    if ([self.delegate respondsToSelector:@selector(chooseView:changeDirection:fromDirection:)]) {
        [self.delegate chooseView:self changeDirection:self.direction fromDirection:lastDirection];
    }
}

- (void)panGestureDidEnd:(UIPanGestureRecognizer *)gesture {
    CGFloat xOffset = [gesture locationInView:self].x - self.panGestureStartLocation.x;
    CGFloat yOffset = [gesture locationInView:self].y - self.panGestureStartLocation.y;
    if (fabs(xOffset) > fabs(yOffset))  {
        if (xOffset > self.frame.size.width / 2) {
            [self handlePushToRight];
        } else if(xOffset < -self.frame.size.width / 2) {
            [self handlePushToLeft];
        } else {
            [self recover];
        }
    } else {
        if([self.delegate respondsToSelector:@selector(chooseView:didEndVerticalSlideWithOffset:index:)]) {
            [self.delegate chooseView:self didEndVerticalSlideWithOffset:yOffset index:self.currentIndex];
        }
    }
}

#pragma mark - PrivateMethod

- (void)updateCurrentViewWithOffset:(CGFloat)offset {
    __weak typeof(self) weakSelf = self;
    [self.currentView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(weakSelf).centerOffset(CGPointMake(offset, fabs(offset) / self.frame.size.width * 20));
    }];
    self.currentView.transform = CGAffineTransformMakeRotation(M_PI_4 / 2 * offset / self.frame.size.width);
    [self layoutIfNeeded];
}

- (void)initCurrentCell {
    UIView *cell = [self.datasource viewInChooseView:self atIndex:(self.currentIndex + 0)];
    [self setCell:cell atIndex:0];
    [self addSubview:cell];
    [self addConstraintToCell:cell];
}

- (void)initNextCell {
    UIView *cell = [self.datasource viewInChooseView:self atIndex:(self.currentIndex + 1)];
    [self setCell:cell atIndex:1];
    [self insertSubview:cell atIndex:0];
    [self addConstraintToCell:cell];
}

- (void)handlePushToRight {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.2 animations:^{
        [self updateCurrentViewWithOffset:weakSelf.frame.size.width];
    } completion:^(BOOL finished) {
        [self pushNextView];
        if ([self.delegate respondsToSelector:@selector(chooseView:didLikeOrNotCell:atIndex:)]) {
            [self.delegate chooseView:self didLikeOrNotCell:YES atIndex:self.currentIndex];
        }
    }];
}

- (void)handlePushToLeft {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.2 animations:^{
        [weakSelf updateCurrentViewWithOffset:-weakSelf.frame.size.width];
    } completion:^(BOOL finished) {
        [self pushNextView];
        if ([self.delegate respondsToSelector:@selector(chooseView:didLikeOrNotCell:atIndex:)]) {
            [self.delegate chooseView:self didLikeOrNotCell:NO atIndex:self.currentIndex];
        }
    }];
}

- (void)pushNextView {
    [self removeCell:self.currentView];
    self.currentView = self.nextView;
    self.currentIndex ++;
    self.nextView = self.prepareView;
    self.prepareView = nil;
    if (self.nextView) {
        [self insertSubview:self.nextView atIndex:0];
        [self resetCurrentView];
        [self configureNextView];
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

- (void)resetCurrentView {
    [self updateCurrentViewWithOffset:0];
}

- (void)configureNextView {
    __weak typeof(self) weakSelf = self;
    [self.nextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(weakSelf).centerOffset(CGPointMake(0, 0));
        make.width.equalTo(@(weakSelf.frame.size.width));
        make.height.equalTo(@(weakSelf.frame.size.height));
    }];
}

- (void)generatePrepareView {
    self.prepareView = [self.datasource viewInChooseView:self atIndex:self.currentIndex + 2];
}

- (void)setCell:(UIView *)cell atIndex:(NSInteger)index {
    switch (index) {
        case 0:
            self.currentView = cell;
            break;
        case 1:
            self.nextView = cell;
            break;
        default:
            break;
    }
}

- (UIView *)cellOfIndex:(NSInteger)index {
    switch (index) {
        case 0:
            return self.currentView;
            break;
        case 1:
            return self.nextView;
            break;
        default:
            return nil;
            break;
    }
}

- (void)initProperties {
    self.reusabelCellIdDictionary = [[NSMutableDictionary alloc] init];
    self.currentIndex = 0;
    self.direction = 0;
}

- (void)addPanGesture {
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
    panRecognizer.delegate = self;
    [self addGestureRecognizer:panRecognizer];
}

- (void)clear {
    [self removeCell:self.currentView];
    [self removeCell:self.nextView];
    self.currentView = nil;
    self.nextView = nil;
}

- (void)removeCell:(UIView *)cell {
    [cell.layer removeAllAnimations];
    [cell removeFromSuperview];
    //TODO insert cell into reusepool
}

- (void)addConstraintToCell:(UIView *)cell {
    __weak typeof(self) weakSelf = self;
    [cell mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(weakSelf).centerOffset(CGPointMake(0, 0));
        make.width.equalTo(@(weakSelf.frame.size.width));
        make.height.equalTo(@(weakSelf.frame.size.height));
    }];
}

- (NSInteger)abledCellCount {
    NSInteger count = self.cellNumber;
    return (count < 2) ? count : 2;
}

- (BOOL)isCellOver {
    return self.currentIndex + 1 >= self.cellNumber;
}

- (BOOL)loadToEnd {
    return self.currentIndex + 2 >= self.cellNumber;
}

#pragma mark -- Tools

- (void)updateCellNumber {
    NSInteger cellNumber = [self.datasource numberOfViewsInChooseView:self];
    self.currentIndex = (cellNumber > self.cellNumber) ? self.currentIndex : 0;
    self.cellNumber = cellNumber;
    
}


@end

