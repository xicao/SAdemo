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
@property BOOL readyToSendText;
@property BOOL readyToSendImage;
@end

@implementation SAViewController

# pragma mark - properties

@synthesize indicator = _indicator;
@synthesize progressView = _progressView;
@synthesize mode = _mode;
@synthesize textField = _textField;
@synthesize textView = _textView;
@synthesize imageView = _imageView;
@synthesize sendTextButton = _sendTextButton;
@synthesize sendImageButton = _sendImageButton;
@synthesize saveImageButton = _saveImageButton;

@synthesize gvaView = _gvaView;
@synthesize informationBar = _informationBar;
@synthesize locationManager;
@synthesize session = _session;
@synthesize peerID = _peerID;

# pragma mark - simple alert utility

/*
  Reference:
  Erica Sadun, http://ericasadun.com
  iPhone Developer's Cookbook, 3.0 Edition
  BSD License
 */
#define showAlert(format, ...) myShowAlert(__LINE__, (char *)__FUNCTION__, format, ##__VA_ARGS__)
void myShowAlert(int line, char *functname, id formatstring,...)
{
	va_list arglist;
	if (!formatstring) return;
	va_start(arglist, formatstring);
	id outstring = [[NSString alloc] initWithFormat:formatstring arguments:arglist];
	va_end(arglist);
	
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:outstring message:nil delegate:nil cancelButtonTitle:@"OK"otherButtonTitles:nil];
	[av show];
}

#pragma mark - game picker methods

- (void)peerPickerController:(GKPeerPickerController *)picker didSelectConnectionType:(GKPeerPickerConnectionType)type {
    
    if (type == GKPeerPickerConnectionTypeOnline) {
		picker.delegate = nil;
		[picker dismiss];
		
		self.session = [[GKSession alloc] initWithSessionID:nil
                                                displayName:self.mode.text
                                                sessionMode:GKSessionModePeer];
		self.session.delegate = self;
		self.session.available = YES;
		[self.session setDataReceiveHandler:self withContext:nil];
	}
}

- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session {
    // from Apple - Game Kit Programmiing Guide: Finding Peers with Peer Picker
    
    self.session = session;
	session.delegate = self;
	[session setDataReceiveHandler:self withContext:nil];
	picker.delegate = nil;
	[picker dismiss];
}

- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker {
	// from Apple - Game Kit Programmiing Guide: Finding Peers with Peer Picker;
	picker.delegate = nil;
}

#pragma mark - session methods

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
    
    switch (state) {
		case GKPeerStateAvailable:
			[self setInformationBarText:[NSString stringWithFormat:@"connecting to %@ ...", [session displayNameForPeer:peerID]]];
			[session connectToPeer:peerID withTimeout:10];
			break;
			
		case GKPeerStateConnected:
			[self setInformationBarText:@"connected"];
			self.peerID = peerID;
			break;
            
		case GKPeerStateDisconnected:
			[self setInformationBarText:@"disconnected"];
			self.session = nil;
            
		default:
			break;
	}
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID {
	NSError* error = nil;
	[session acceptConnectionFromPeer:peerID error:&error];
	if (error) {
		NSLog(@"%@", error);
	}
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error {
	NSLog(@"%@|%@", peerID, error);
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error {
	NSLog(@"%@", error);
}

#pragma mark - send and receive methods

- (IBAction)sendText:(UIButton *)sender {
    
    if (self.session == nil) {
		showAlert(@"You are not connected to any devices.");
		return;
	}
    
	NSError* error = nil;
	[self.session sendData:[self.textField.text dataUsingEncoding:NSUTF8StringEncoding]
				   toPeers:[NSArray arrayWithObject:self.peerID]
			  withDataMode:GKSendDataReliable
					 error:&error];
    
	if (error) {
		NSLog(@"%@", error);
	}
    
	self.textField.text = @"";//clear text field
}

- (IBAction)sengImage:(id)sender {
	
	UIActionSheet* sheet = [[UIActionSheet alloc]
							 initWithTitle:nil
							 delegate:self
							 cancelButtonTitle:@"cancel"
							 destructiveButtonTitle:nil
							 otherButtonTitles:@"choose", nil];
    
	[sheet showInView:self.view];
}

- (void) receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context {
	if ([data length] < 1024) {// receice text
        NSLog(@"text received");
		NSString* text = [self.textView.text stringByAppendingFormat:@"%@\n", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
		self.textView.text = text;

		[self.textView scrollRangeToVisible:NSMakeRange([text length]-1, 1)];
	} else {// receive image
		NSLog(@"image received");
		self.imageView.image = [UIImage imageWithData:data];
	}
}

#pragma mark - image picker methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissModalViewControllerAnimated:YES];
	UIImage* image = [info objectForKey:UIImagePickerControllerEditedImage];
	
	NSError* error = nil;

	[self.session sendData:UIImageJPEGRepresentation(image, 0.5)
				   toPeers:[NSArray arrayWithObject:self.peerID]
			  withDataMode:GKSendDataReliable
					 error:&error];
    
	if (error) {
		NSLog(@"%@", error);
	}
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissModalViewControllerAnimated:YES];
}

#pragma mark - action sheet methods

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1) {// cancle
		return;
	}
	
	UIImagePickerController* picker = [[UIImagePickerController alloc] init];
	picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	
	picker.delegate = self;
	picker.allowsEditing = YES;
	picker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	[self presentModalViewController:picker animated:YES];
}


#pragma mark - helper methods

- (void)clearInformationBarText {
    self.informationBar.text = @"";
}

- (void)setInformationBarText:(NSString *)info {
    [self clearInformationBarText];
    self.informationBar.text = [self.informationBar.text stringByAppendingString:info];
}

#pragma mark - functional area selection buttons methods

- (IBAction)functionalAreaSelectionButtonsPressed:(UIButton *)sender {
    // highlight current functional area label
    [self.gvaView functionalAreaLabelSelected:sender.currentTitle];
}

#pragma mark - reconfigurable buttons methods

- (IBAction)reconfigurableButtonsPressed:(UIButton *)sender {
    if ([sender.currentTitle isEqualToString:@"F1"]) {
        [self setInformationBarText:@"Start searching..."];
        
        GKPeerPickerController* picker = [[GKPeerPickerController alloc] init];
        picker.delegate = self;
        picker.connectionTypesMask = GKPeerPickerConnectionTypeOnline | GKPeerPickerConnectionTypeNearby;
        
        [picker show];
    } else if ([sender.currentTitle isEqualToString:@"F2"]) {// send message
        if (!self.readyToSendText) {
            self.readyToSendText = YES;
            
            self.textView.hidden = NO;
            self.textField.hidden = NO;
            self.sendTextButton.hidden = NO;
        } else {
            self.readyToSendText = NO;
            
            self.textView.hidden = YES;
            self.textField.hidden = YES;
            self.sendTextButton.hidden = YES;
        }
        
    } else if ([sender.currentTitle isEqualToString:@"F3"]) {// send image
        if (!self.readyToSendImage) {
            self.readyToSendImage = YES;
            
            self.imageView.hidden = NO;
            self.sendImageButton.hidden = NO;
            self.saveImageButton.hidden = NO;
        } else {
            self.readyToSendImage = NO;
            
            self.imageView.hidden = YES;
            self.sendImageButton.hidden = YES;
            self.saveImageButton.hidden = YES;
        }
        
    }
}

#pragma mark - common task buttons methods

- (IBAction)commonTaskButtonsPressed:(UIButton *)sender {
    if ([sender.currentTitle isEqualToString:@"F20"]) {//back to mode select view
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - view methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    //[[UIApplication sharedApplication] setStatusBarHidden:YES];// hide status bar
    return UIInterfaceOrientationIsLandscape(orientation);// only support landscape
}

- (void)setGvaView:(GvaView *)gvaView
{
    _gvaView = gvaView;
    [self.gvaView setNeedsDisplay];
    [self.gvaView setNeedsLayout];
}

- (void)viewDidUnload {
    compass = nil;
    [self setInformationBar:nil];
    [self setIndicator:nil];
    [self setProgressView:nil];
    [self setMode:nil];
    [self setTextField:nil];
    [self setSendTextButton:nil];
    [self setTextView:nil];
    [self setImageView:nil];
    [self setSendImageButton:nil];
    [self setSaveImageButton:nil];
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
    
    self.textView.hidden = YES;
    self.textField.hidden = YES;
    self.sendTextButton.hidden = YES;
    
    self.imageView.hidden = YES;
    self.sendImageButton.hidden = YES;
    self.saveImageButton.hidden = YES;
    
}

#pragma mark - hide navigation bar

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
	[self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    
	[self.navigationController setNavigationBarHidden:NO animated:YES];
}

#pragma mark - compass method
#pragma mark - referene: http://blog.objectgraph.com/index.php/2012/01/10/how-to-create-a-compass-in-iphone/
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
