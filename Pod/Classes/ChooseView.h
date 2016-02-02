//
//  ChooseView.h
//  ChooseView
//
//  Created by guoshencheng on 11/24/15.
//  Copyright © 2015 guoshencheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ChooseViewDatasource;
@protocol ChooseViewDelegate;

@interface ChooseView : UIView <UIGestureRecognizerDelegate>

@property (strong, nonatomic) UIView *currentView;
@property (strong, nonatomic) UIView *nextView;
@property (strong, nonatomic) UIImageView *backView;
@property (weak, nonatomic) id<ChooseViewDatasource> datasource;
@property (weak, nonatomic) id<ChooseViewDelegate> delegate;

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
- (BOOL)chooseView:(ChooseView *)chooseView shouldIgnoreGesture:(UIGestureRecognizer *)gesture;
- (void)chooseViewWillSlide:(ChooseView *)chooseView;
- (void)chooseViewDidLoadedLastCell:(ChooseView *)chooseView;
- (void)chooseView:(ChooseView *)chooseView didLikeOrNotCell:(BOOL)isLike atIndex:(NSInteger)index;
- (void)chooseView:(ChooseView *)chooseView didSlideLeftWithOffset:(CGFloat)offset;
- (void)chooseView:(ChooseView *)chooseView didSlideRightWithOffset:(CGFloat)offset;
- (void)chooseView:(ChooseView *)chooseView didEndVerticalSlideWithOffset:(CGFloat)offset index:(NSInteger)index;
- (void)chooseViewDidRecover:(ChooseView *)chooseView;

/***
 direction:
    1 for right
    -1 for left
    0 for none
 ***/
- (void)chooseView:(ChooseView *)chooseView changeDirection:(NSInteger)direction fromDirection:(NSInteger)fromDirection;

@end
