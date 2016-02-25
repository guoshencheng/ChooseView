//
//  RYViewController.m
//  ChooseView
//
//  Created by guoshencheng on 11/26/2015.
//  Copyright (c) 2015 guoshencheng. All rights reserved.
//

#import "RYViewController.h"
#import "Masonry.h"

@interface RYViewController ()

@property (strong, nonatomic) NSArray *array;
@property (strong, nonatomic) ChooseView *chooseView;

@end

@implementation RYViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.array = @[@(1), @(1), @(1), @(1)];
    self.chooseView = [ChooseView create];
    [self.view addSubview:self.chooseView];
    [self.chooseView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@(0));
        make.top.equalTo(@(0));
        make.right.equalTo(@(0));
        make.bottom.equalTo(@(0));
    }];
    [self.view layoutIfNeeded];
    self.chooseView.datasource = self;
    self.chooseView.delegate = self;
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfViewsInChooseView:(ChooseView *)chooseView {
    return 100;
}

- (CGRect)itemFameInChooseView:(ChooseView *)chooseView atIndex:(NSInteger)index {
    return [UIScreen mainScreen].bounds;
}

- (UIView *)viewInChooseView:(ChooseView *)chooseView atIndex:(NSInteger)index {
    UIView *cell = [[UIView alloc] init];
    if (index % 2 == 0) {
        cell.backgroundColor = [UIColor blackColor];
    } else {
        cell.backgroundColor = [UIColor yellowColor];
    }
    cell.layer.cornerRadius = 10;
    return cell;
}

- (void)chooseView:(ChooseView *)chooseView slideDirection:(ChooseViewSlideDirection)direction atIndex:(NSInteger)index {
    NSString *string = direction == ChooseViewSlideDirectionRight ? @"like " : @"unLike";
    NSLog(@"%@ in index : %@", string, @(index));
    if (index >= self.array.count - 2) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [array addObjectsFromArray:self.array];
        [array addObjectsFromArray:@[@(1), @(1), @(1), @(1)]];
        self.array = array;
        [self.chooseView performSelector:@selector(loadMoreData) withObject:nil afterDelay:10];
    }
}

- (void)chooseView:(ChooseView *)chooseView swipeDirection:(UISwipeGestureRecognizerDirection)direction index:(NSInteger)index {
    switch (direction) {
        case UISwipeGestureRecognizerDirectionUp:
            NSLog(@"up");
            break;
        case UISwipeGestureRecognizerDirectionDown:
            NSLog(@"down");
            break;
        default:
            break;
    }
}

@end
