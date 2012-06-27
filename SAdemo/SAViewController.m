//
//  SAViewController.m
//  SituationalAwareness
//
//  Created by Xi Cao on 26/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SAViewController.h"
#import "GvaView.h"

@interface SAViewController ()
@property (nonatomic, weak) IBOutlet GvaView *gvaView;
@end

@implementation SAViewController

@synthesize gvaView = _gvaView;
@synthesize locationManager;

- (void)setGvaView:(GvaView *)gvaView
{
    _gvaView = gvaView;
    [self.gvaView setNeedsDisplay];
    [self.gvaView setNeedsLayout];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];// hide status bar
    return UIInterfaceOrientationIsLandscape(orientation);// only support landscape
}

- (IBAction)functionalAreaSelected:(UIButton *)sender {
    // highlight current functional area label
    [self.gvaView functionalAreaLabelSelected:sender.currentTitle];
}

//back to mode select view
- (IBAction)quitCurrentMode:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


//hide navigation bar
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
	[self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    
	[self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidUnload {
    compass = nil;
    [super viewDidUnload];
}

- (void)viewDidLoad{
    [super viewDidLoad];
	locationManager=[[CLLocationManager alloc] init];
	locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	locationManager.headingFilter = 1;
	locationManager.delegate=self;
	[locationManager startUpdatingHeading];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading{
	// Convert Degree to Radian and move the needle
	float oldRad =  -manager.heading.trueHeading * M_PI / 180.0f;
	float newRad =  -newHeading.trueHeading * M_PI / 180.0f;
	CABasicAnimation *theAnimation;
    theAnimation=[CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    theAnimation.fromValue = [NSNumber numberWithFloat:oldRad];
    theAnimation.toValue=[NSNumber numberWithFloat:newRad];
    theAnimation.duration = 0.5f;
    [compass.layer addAnimation:theAnimation forKey:@"animateMyRotation"];
    compass.transform = CGAffineTransformMakeRotation(newRad);
	NSLog(@"%f (%f) => %f (%f)", manager.heading.trueHeading, oldRad, newHeading.trueHeading, newRad);
}
@end
