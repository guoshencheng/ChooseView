//
//  ChooseView+Layout.h
//  Pods
//
//  Created by guoshencheng on 2/2/16.
//
//

#import <ChooseView/ChooseView.h>

@interface ChooseView (Layout)

- (void)clear;
- (void)removeCell:(UIView *)cell;
- (void)setCell:(UIView *)cell atIndex:(NSInteger)index;
- (UIView *)cellOfIndex:(NSInteger)index;
- (void)resetCurrentView;

@end
