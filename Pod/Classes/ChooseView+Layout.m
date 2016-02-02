//
//  ChooseView+Layout.m
//  Pods
//
//  Created by guoshencheng on 2/2/16.
//
//

#import "Masonry.h"
#import "ChooseView+Layout.h"

@implementation ChooseView (Layout)

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

- (void)resetCurrentView {
    [self updateCurrentViewWithOffset:0];
}

#pragma mark - PrivateMethod

- (void)updateCurrentViewWithOffset:(CGFloat)offset {
    CGSize size = self.currentView.superview.frame.size;
    self.currentView.center = CGPointMake(size.width / 2 + offset, size.height / 2 + fabs(offset) / self.frame.size.width * 20);
    self.currentView.transform = CGAffineTransformMakeRotation(M_PI_4 / 2 * offset / self.frame.size.width);
    [self layoutIfNeeded];
}

@end
