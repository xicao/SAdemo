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
@synthesize indicator = _indicator;
@synthesize progressView = _progressView;

@synthesize id = _id;
@synthesize gvaView = _gvaView;
@synthesize informationBar = _informationBar;
@synthesize locationManager;

- (void)setGvaView:(GvaView *)gvaView
{
    _gvaView = gvaView;
    [self.gvaView setNeedsDisplay];
    [self.gvaView setNeedsLayout];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    //[[UIApplication sharedApplication] setStatusBarHidden:YES];// hide status bar
    return UIInterfaceOrientationIsLandscape(orientation);// only support landscape
}

- (IBAction)functionalAreaSelectionButtonsPressed:(UIButton *)sender {
    // highlight current functional area label
    [self.gvaView functionalAreaLabelSelected:sender.currentTitle];
}

- (IBAction)reconfigurableButtonsPressed:(UIButton *)sender {
    if ([sender.currentTitle isEqualToString:@"F1"]) {
        self.informationBar.text = [self.informationBar.text stringByReplacingOccurrencesOfString:self.informationBar.text withString:@"Start searching..."];
    }
}

- (IBAction)commonTaskButtonsPressed:(UIButton *)sender {
    if ([sender.currentTitle isEqualToString:@"F20"]) {//back to mode select view
        [self.navigationController popViewControllerAnimated:YES];
    }
}

//hide navigation bar---------------------------
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
	[self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    
	[self.navigationController setNavigationBarHidden:NO animated:YES];
}
//hide navigation bar---------------------------

- (void)viewDidUnload {
    compass = nil;
    [self setInformationBar:nil];
    [self setIndicator:nil];
    [self setProgressView:nil];
    [super viewDidUnload];
}

- (void)viewDidLoad{
    [super viewDidLoad];
	locationManager = [[CLLocationManager alloc] init];
	locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	locationManager.headingFilter = 1;
	locationManager.delegate = self;
	[locationManager startUpdatingHeading];
    
    self.informationBar.text = @"";
    self.indicator.hidesWhenStopped = YES;
    self.progressView.hidden = YES;
}

//referene:
//http://blog.objectgraph.com/index.php/2012/01/10/how-to-create-a-compass-in-iphone/
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading{
	// Convert Degree to Radian and move the needle
	float oldRad = -manager.heading.trueHeading * M_PI / 180.0f;
	float newRad = -newHeading.trueHeading * M_PI / 180.0f;
	CABasicAnimation * theAnimation;
    theAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    theAnimation.fromValue = [NSNumber numberWithFloat:oldRad];
    theAnimation.toValue = [NSNumber numberWithFloat:newRad];
    theAnimation.duration = 0.5f;
    [compass.layer addAnimation:theAnimation forKey:@"animateMyRotation"];
    compass.transform = CGAffineTransformMakeRotation(newRad);
	NSLog(@"%f (%f) => %f (%f)", manager.heading.trueHeading, oldRad, newHeading.trueHeading, newRad);
}
@end
