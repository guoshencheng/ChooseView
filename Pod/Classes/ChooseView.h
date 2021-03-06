//
//  ChooseView.h
//  ChooseView
//
//  Created by guoshencheng on 11/24/15.
//  Copyright © 2015 guoshencheng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    ChooseViewSlideDirectionRight,
    ChooseViewSlideDirectionLeft,
    ChooseViewSlideDirectionOrigin
} ChooseViewSlideDirection;

@protocol ChooseViewDatasource;
@protocol ChooseViewDelegate;

@interface ChooseView : UIView <UIGestureRecognizerDelegate>

@property (strong, nonatomic) UIView *currentView;
@property (strong, nonatomic) UIView *nextView;
@property (strong, nonatomic) UIImageView *backView;
@property (weak, nonatomic) id<ChooseViewDatasource> datasource;
@property (weak, nonatomic) id<ChooseViewDelegate> delegate;
@property (assign, nonatomic) NSInteger currentIndex;
@property (assign, nonatomic) CGSize cellSize;

+ (instancetype)create;
- (void)setUpCurrentIndex:(NSInteger)index;
- (void)reloadData;
- (void)loadMoreData;
- (void)registerCellWithNibName:(NSString *)nibName forCellReuseIdentifier:(NSString *)identifier;
- (UIView *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index;

@end

@protocol ChooseViewDatasource <NSObject>
@required
- (NSInteger)numberOfViewsInChooseView:(ChooseView *)chooseView;
- (UIView *)viewInChooseView:(ChooseView *)chooseView atIndex:(NSInteger)index;
@end

@protocol ChooseViewDelegate <NSObject>
@optional
- (void)chooseView:(ChooseView *)chooseView didSlideWithOffset:(CGFloat)offset;
- (void)chooseViewWillSlide:(ChooseView *)chooseView direction:(ChooseViewSlideDirection)direction;
- (void)chooseViewDidRecover:(ChooseView *)chooseView;
- (BOOL)chooseView:(ChooseView *)chooseView shouldIgnoreGesture:(UIGestureRecognizer *)gesure;
- (void)chooseViewDidEndSlide:(ChooseView *)chooseView direction:(ChooseViewSlideDirection)direction index:(NSInteger)index;
- (void)chooseView:(ChooseView *)chooseView slideDirection:(ChooseViewSlideDirection)direction atIndex:(NSInteger)index;
- (void)chooseView:(ChooseView *)chooseView swipeDirection:(UISwipeGestureRecognizerDirection)direction index:(NSInteger)index;
- (void)chooseView:(ChooseView *)chooseView changeDirection:(ChooseViewSlideDirection)direction fromDirection:(ChooseViewSlideDirection)fromDirection;

@end
