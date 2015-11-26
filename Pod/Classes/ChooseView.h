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
@property (weak, nonatomic) id<ChooseViewDatasource> datasource;
@property (weak, nonatomic) id<ChooseViewDelegate> delegate;

+ (instancetype)create;
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
- (void)chooseViewDidLoadedLastCell:(ChooseView *)chooseView;
- (void)chooseView:(ChooseView *)chooseView didLikeOrNotCell:(BOOL)isLike atIndex:(NSInteger)index;
- (void)chooseView:(ChooseView *)chooseView didSlideLeftWithOffset:(CGFloat)offset;
- (void)chooseView:(ChooseView *)chooseView didSlideRightWithOffset:(CGFloat)offset;
- (void)chooseView:(ChooseView *)chooseView didEndVerticalSlideWithOffset:(CGFloat)offset index:(NSInteger)index;

@end
