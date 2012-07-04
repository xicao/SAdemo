//
//  SAViewController.h
//  SituationalAwareness
//
//  Created by Xi Cao on 26/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <QuartzCore/QuartzCore.h>
#import <GameKit/GameKit.h>

@interface SAViewController : UIViewController<CLLocationManagerDelegate,GKSessionDelegate>
{
    CLLocationManager *locationManager;
    
    __weak IBOutlet UIImageView *compass;
}

@property (weak, nonatomic) IBOutlet UILabel *informationBar;
@property (nonatomic,retain) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *mode;

@end
