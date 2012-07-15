//
//  SessionHelper.m
//  SAdemo
//
//  Created by Xi Cao on 11/07/12.
//
//

#import "SessionHelper.h"

@implementation SessionHelper

@synthesize dataDelegate = _dataDelegate;
@synthesize sessionID = _sessionID;
@synthesize gkSession = _gkSession;
@synthesize isConnected = _isConnected;

- (void)connect {
    
}

- (void)disconnect {
    
}

+(id)initWithSessionName:(NSString *)name andDelegate:(UIViewController <SessionHelperDataDelegate> *)delegate {
    SessionHelper *helper = [[SessionHelper alloc] init];
    
    helper.sessionID = name;
    helper.dataDelegate = delegate;
    
    return helper;
}

@end
