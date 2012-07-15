//
//  SessionHelper.h
//  SAdemo
//
//  Created by Xi Cao on 11/07/12.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

@protocol SessionHelperDataDelegate <NSObject>
@optional
- (void)connect;
- (void)disconnect;
- (void)sendData;
- (void)receiceData;
@end

@interface SessionHelper : NSObject <GKPeerPickerControllerDelegate, GKSessionDelegate>

@property (weak) UIViewController <SessionHelperDataDelegate> *dataDelegate;
@property (strong) NSString *sessionID;
@property (strong, readonly) GKSession *gkSession;
@property (assign, readonly) BOOL isConnected;

- (void)connect;
- (void)disconnect;

+ (id)initWithSessionName:(NSString *)name andDelegate:(UIViewController <SessionHelperDataDelegate> *)delegate;

@end
