//
//  ChooseView.m
//  ChooseView
//
//  Created by guoshencheng on 11/24/15.
//  Copyright © 2015 guoshencheng. All rights reserved.
//

#import "ChooseView.h"
#import "PickUpMotion.h"
#import "Masonry.h"
#import "ChooseView+Layout.h"

@implementation UIView (ChooseView)


@end

@interface ChooseView () <PickUpMotionDataSource, PickUpMotionDelegate>

@property (strong, nonatomic) PickUpMotion *pickUpMotion;
@property (strong, nonatomic) NSMutableDictionary *reusabelCellIdDictionary;
@property (strong, nonatomic) UIView *prepareView;
@property (assign, nonatomic) NSInteger cellNumber;
@property (assign, nonatomic) NSInteger currentIndex;
@property (assign, nonatomic) NSInteger direction;

@end

@implementation ChooseView

#pragma mark - LiveCycle

+ (instancetype)create {
    return [[ChooseView alloc] init];
}

- (instancetype)init {
    if (self = [super init]) {
        [self initProperties];
        [self configrePickUpMotion];
    }
    return self;
}

#pragma mark - PublicMethod

- (void)setUpCurrentIndex:(NSInteger)currentIndex {
    self.currentIndex = currentIndex;
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

#pragma mark - PickUpMotion

- (UIView *)containerViewOfPickUpmotion:(PickUpMotion *)pickUpmotion {
    return self;
}

- (void)pickUpmotion:(PickUpMotion *)pickUpmotion willBeginMoveView:(UIView *)view {
   self.direction = 0;
}

- (void)pickUpmotion:(PickUpMotion *)pickUpmotion didBeginMoveView:(UIView *)view {
    [self pickUpView];
    view.hidden = YES;
}

- (void)pickUpmotion:(PickUpMotion *)pickUpmotion didMoveView:(UIView *)view withMovement:(CGPoint)movement {
    if (![self isCellOver] && ![self loadToEnd]) {
        [self generatePrepareView];
    }
    if (movement.x > 0) {
        if ([self.delegate respondsToSelector:@selector(chooseView:didSlideRightWithOffset:)]) {
            [self.delegate chooseView:self didSlideRightWithOffset:fabs(movement.x)];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(chooseView:didSlideLeftWithOffset:)]) {
            [self.delegate chooseView:self didSlideLeftWithOffset:fabs(movement.x)];
        }
    }
    if ((self.direction == 0 || self.direction == -1) && movement.x > 0) {
        [self changeToDirection:1];
    } else if ((self.direction == 0 || self.direction == 1) && movement.x < 0) {
        [self changeToDirection:-1];
    }
}

- (void)pickUpmotion:(PickUpMotion *)pickUpmotion willEndMoveView:(UIView *)view withMovement:(CGPoint)movement {
    [self pushNextView];
}

- (void)changeToDirection:(NSInteger)direction {
    NSInteger lastDirection = self.direction;
    self.direction = direction;
    if ([self.delegate respondsToSelector:@selector(chooseView:changeDirection:fromDirection:)]) {
        [self.delegate chooseView:self changeDirection:self.direction fromDirection:lastDirection];
    }
}

#pragma mark - PrivateMethod

- (void)initCurrentCell {
    UIView *cell = [self viewWithIndex:self.currentIndex];
    [self setCell:cell atIndex:0];
    [self addSubview:cell];
}

- (void)initNextCell {
    UIView *cell = [self viewWithIndex:self.currentIndex + 1];
    [self setCell:cell atIndex:1];
}

- (void)generatePrepareView {
    self.prepareView = [self viewWithIndex:self.currentIndex + 2];;
}

- (void)pushNextView {
    [self insertSubview:self.nextView atIndex:0];
    [self.backView removeFromSuperview];
    [self removeCell:self.currentView];
    self.currentView = self.nextView;
    self.currentIndex ++;
    self.nextView = self.prepareView;
    self.prepareView = nil;
    if (self.nextView) {
        [self resetCurrentView];
    }
}

- (void)initProperties {
    self.reusabelCellIdDictionary = [[NSMutableDictionary alloc] init];
    self.currentIndex = 0;
    self.direction = 0;
}

- (void)configrePickUpMotion {
    self.pickUpMotion = [PickUpMotion new];
    self.pickUpMotion.animationType = PickUpMotionAnimationFlyAway;
    self.pickUpMotion.delegate = self;
    self.pickUpMotion.dataSource = self;
}

- (NSInteger)abledCellCount {
    NSInteger count = self.cellNumber;
    return (count < 2) ? count : 2;
}

- (UIView *)viewWithIndex:(NSInteger)index {
    UIView *view = [self.datasource viewInChooseView:self atIndex:index];
    view.frame = [self.datasource itemFameInChooseView:self atIndex:index];
    [self.pickUpMotion attachToView:view];
    return view;
}

#pragma mark -- Tools

- (void)pickUpView {
    [self.backView removeFromSuperview];
    UIImage *snapshot = [self imageWithView:self.nextView];
    self.backView = [[UIImageView alloc] initWithImage:snapshot];
    [self.backView setBackgroundColor:[UIColor clearColor]];
    [self insertSubview:self.backView atIndex:0];
}

- (UIImage *)imageWithView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (BOOL)isCellOver {
    return self.currentIndex + 1 >= self.cellNumber;
}

- (BOOL)loadToEnd {
    return self.currentIndex + 2 >= self.cellNumber;
}

- (void)updateCellNumber {
    NSInteger cellNumber = [self.datasource numberOfViewsInChooseView:self];
    self.currentIndex = (cellNumber > self.cellNumber) ? self.currentIndex : 0;
    self.cellNumber = cellNumber;
    
}


@end

