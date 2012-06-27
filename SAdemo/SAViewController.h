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

@interface SAViewController : UIViewController<CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
    
    __weak IBOutlet UIImageView *compass;
}

@property (nonatomic,retain) CLLocationManager *locationManager;
@end
