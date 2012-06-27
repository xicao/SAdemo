//
//  SAdemoViewController.m
//  SAdemo
//
//  Created by Xi Cao on 27/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SAdemoViewController.h"

@interface SAdemoViewController ()

@end

@implementation SAdemoViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];// hide status bar
    return UIInterfaceOrientationIsLandscape(orientation);// only support landscape
}

@end
