//
//  PACViewController.m
//  indicatorTest
//
//  Created by Famille CLAUDOT on 02/03/2014.
//  Copyright (c) 2014 Paul-Anatole CLAUDOT. All rights reserved.
//

#import "PACViewController.h"

// Category
#import "UIScrollView+Indicators.h"

@interface PACViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation PACViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [_scrollView setContentSize:_imageView.frame.size];
    
    // let's customize it
    [_scrollView setCustomHorizontalScrollIndicator:[UIImage imageNamed:@"rugby.png"]];
    [_scrollView setCustomVerticalScrollIndicator:[UIImage imageNamed:@"foot.png"]];
}

@end
