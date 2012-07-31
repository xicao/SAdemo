//
//  SAViewController.m
//  SituationalAwareness
//
//  Created by Xi Cao on 26/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SAViewController.h"
#import "GvaView.h"
#import <MobileCoreServices/MobileCoreServices.h>
#include <stdio.h>

@interface SAViewController ()
@property (nonatomic, weak) IBOutlet GvaView *gvaView;
@property BOOL readyToSendText;
@property BOOL readyToSendImage;
@property BOOL startOverlay;

@property (nonatomic, strong) UIPopoverController *imagePopover;
@property (weak, nonatomic) UIActionSheet *actionSheet;
@end

@implementation SAViewController

# pragma mark - properties

@synthesize indicator = _indicator;
@synthesize progressView = _progressView;
@synthesize mode = _mode;
@synthesize textField = _textField;
@synthesize textView = _textView;
@synthesize overlayTextView = _overlayTextView;
@synthesize imageView = _imageView;
@synthesize sendTextButton = _sendTextButton;
@synthesize sendImageButton = _sendImageButton;
@synthesize saveImageButton = _saveImageButton;

@synthesize gvaView = _gvaView;
@synthesize informationBar = _informationBar;
@synthesize locationManager = _locationManager;
@synthesize session = _session;
@synthesize peerID = _peerID;

@synthesize imagePopover = _imagePopover;
@synthesize actionSheet = _actionSheet;

@synthesize captureManager = _captureManager;
@synthesize scanningLabel = _scanningLabel;
@synthesize overlayButton = _overlayButton;
@synthesize overlayImageView = _overlayImageView;

@synthesize videoOutput = _videoOutput;
@synthesize captureSession = _captureSession;

# pragma mark - simple alert utility

/*
 Reference:
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 3.0 Edition
 BSD License
 */
#define showAlert(format, ...) myShowAlert(__LINE__, (char *)__FUNCTION__, format, ##__VA_ARGS__)
void myShowAlert(int line, char *functname, id formatstring,...) {
	va_list arglist;
	if (!formatstring) return;
	va_start(arglist, formatstring);
	id outstring = [[NSString alloc] initWithFormat:formatstring arguments:arglist];
	va_end(arglist);
	
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:outstring message:nil delegate:nil cancelButtonTitle:@"OK"otherButtonTitles:nil];
	[av show];
}

#pragma mark - lazy instantiation

- (UILabel *)scanningLabel {
    if (!_scanningLabel) {
        _scanningLabel = [[UILabel alloc] initWithFrame:self.imageView.frame];
    }
    
    return _scanningLabel;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc]init];
    }
    
    return _imageView;
}

- (UIImageView *)overlayImageView {
    if (!_overlayImageView) {
        _overlayImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"overlaygraphic.png"]];
    }
    
    return _overlayImageView;
}

- (UIButton *)overlayButton {
    if (!_overlayButton) {
        _overlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    
    return _overlayButton;
}

- (AVCaptureVideoDataOutput *)videoOutput {
    if (!_videoOutput) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc]init];
    }
    
    return _videoOutput;
}

- (AVCaptureSession *)captureSession {
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc]init];
    }
    
    return _captureSession;
}

#pragma mark - overlap methods

- (void)scanButtonPressed {
	[self.scanningLabel setHidden:NO];
    [self.captureManager captureStillImage];
}

- (void)saveImageToPhotoAlbum {
    UIImageWriteToSavedPhotosAlbum([self.captureManager stillImage], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error != NULL) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Image couldn't be saved" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
    }
    else {
        [self.scanningLabel setHidden:YES];
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSData *data = [NSData dataWithBytes:&sampleBuffer length:malloc_size(sampleBuffer)];
    
    [self tranferDataToVideo:data];
}

- (void)tranferDataToVideo:(NSData *)data {
    
    CMSampleBufferRef sampleBuffer;
    [data getBytes:&sampleBuffer length:sizeof(sampleBuffer)];
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress,
                                                    width,height,
                                                    8,
                                                    bytesPerRow,
                                                    colorSpace,
                                                    kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image = [UIImage imageWithCGImage:newImage
                                         scale:1.0
                                   orientation:UIImageOrientationUp];
    
    CGImageRelease(newImage);
    
    
    [self.imageView performSelectorOnMainThread:@selector(setImage:)
                                     withObject:image waitUntilDone:YES];
    
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    if ([self.mode.text isEqualToString:@"Controller"] && self.session != nil) {
        
        NSError* error = nil;
        NSData* imageData = UIImageJPEGRepresentation(image, 0.5);
        [self.session sendData:imageData
                       toPeers:[NSArray arrayWithObject:self.peerID]
                  withDataMode:GKSendDataReliable
                         error:&error];
    }
}


#pragma mark - game picker methods

- (void)peerPickerController:(GKPeerPickerController *)picker didSelectConnectionType:(GKPeerPickerConnectionType)type {
    // from Apple - Game Kit Programmiing Guide: Finding Peers with Peer Picker
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
    [self clearInformationBarText];
}

#pragma mark - session methods

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
    
    switch (state) {
		case GKPeerStateAvailable:
			[self setInformationBarText:[NSString stringWithFormat:@"Connecting to %@ ...", [session displayNameForPeer:peerID]]];
			[session connectToPeer:peerID withTimeout:10];
			break;
			
		case GKPeerStateConnected:
			[self setInformationBarText:[NSString stringWithFormat:@"Connected to %@.", [session displayNameForPeer:peerID]]];
			self.peerID = peerID;
			break;
            
		case GKPeerStateDisconnected:
			[self setInformationBarText:[NSString stringWithFormat:@"Disconnected to %@.", [session displayNameForPeer:peerID]]];
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

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context {
	if ([data length] < 1024) {// receive text
        NSLog(@"text received");
        if ([self.mode.text isEqualToString:@"Crew-point"]) {
            
            NSString* text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            if ([text isEqualToString:@"iWantToStopOverlay"]) {
                self.scanningLabel.text = @"";
            } else if ([text isEqualToString:@"iWantToStopVideo"]) {
                self.imageView.image = nil;
            } else {
                self.scanningLabel.text = text;
            }
            
            //[self.textView scrollRangeToVisible:NSMakeRange([text length] -1, 1)];
        }
        //        NSLog(@"text received");
        //		NSString* text = [self.textView.text stringByAppendingFormat:@"%@\n", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        //		self.textView.text = text;
        //
        //		[self.textView scrollRangeToVisible:NSMakeRange([text length] -1, 1)];
	} else {// receive image
		NSLog(@"image received");
		//self.imageView.image = [UIImage imageWithData:data];
        [self.imageView performSelectorOnMainThread:@selector(setImage:)
                                         withObject:[UIImage imageWithData:data] waitUntilDone:YES];
	}
}

- (IBAction)sendText:(UIButton *)sender {
    if (self.session == nil) {
		showAlert(@"You are not connecting to any devices.");
		return;
	}
    
	NSError* error = nil;
	[self.session sendData:[self.textField.text dataUsingEncoding:NSUTF8StringEncoding]
				   toPeers:[NSArray arrayWithObject:self.peerID]
			  withDataMode:GKSendDataReliable
					 error:&error];
    
	if (error) {
		showAlert(@"%@", error);
	}
    
	self.textField.text = @"";//clear text field
}

- (IBAction)sendImage:(id)sender {
    
    if (self.imageView.image == nil) {
		showAlert(@"You are not containing any image to be send.");
		return;
	}
    
	
    //    if (self.actionSheet) {
    //        // do nothing
    //    } else {
    //        UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:nil
    //                                                       delegate:self
    //                                              cancelButtonTitle:@"cancel"
    //                                         destructiveButtonTitle:nil
    //                                              otherButtonTitles:@"choose", nil];
    //
    //        [sheet showFromRect:CGRectMake(0, 0, 1165, 573) inView:self.gvaView animated:YES];
    //        self.actionSheet = sheet;
    //
    //
    //    }
    
    NSError* error = nil;
	NSData* data = UIImageJPEGRepresentation(self.imageView.image, 0.5);
	[self.session sendData:data
				   toPeers:[NSArray arrayWithObject:self.peerID]
			  withDataMode:GKSendDataReliable
					 error:&error];
	if (error) {
		showAlert(@"%@", error);
	} else {
        self.imageView.image = nil;
    }
}

- (IBAction)saveImage:(UIButton *)sender {
    if (self.session == nil) {
		showAlert(@"You are not connecting to any devices.");
		return;
	}
    
    UIImageWriteToSavedPhotosAlbum(self.imageView.image, self, @selector(imageSaved:didFinishSavingWithError:contextInfo:), nil);
    
    self.imageView.image = nil;
}

-(void)imageSaved:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (error == NULL)
        showAlert(@"Image saved successfully.");
    else
        showAlert(@"Image could not be saved.");
}

#pragma mark - action sheet methods

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *choice = [actionSheet buttonTitleAtIndex:buttonIndex];
    
	if (buttonIndex == 1) {// cancel
		return;
	} else if ([choice isEqualToString:@"choose"]) {
        
    }
}

#pragma mark - image picker methods

- (void)dismissImagePicker
{
    [self.imagePopover dismissPopoverAnimated:YES];
    self.imagePopover = nil;
    [self dismissModalViewControllerAnimated:YES];
}

#define MAX_IMAGE_WIDTH 200

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image) image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (image) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        CGRect frame = imageView.frame;
        while (frame.size.width > MAX_IMAGE_WIDTH) {
            frame.size.width /= 2;
            frame.size.height /= 2;
        }
        imageView.frame = frame;
        //        [self setRandomLocationForView:imageView];
        //        [self.gvaView addSubview:imageView];
        self.imageView.image = image;
    }
    [self dismissImagePicker];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissImagePicker];
}

#pragma mark - helper methods

- (void)clearInformationBarText {
    self.informationBar.text = @"";
}

- (void)setInformationBarText:(NSString *)info {
    [self clearInformationBarText];
    self.informationBar.text = [self.informationBar.text stringByAppendingString:info];
}

- (void)setRandomLocationForView:(UIView *)view {
    CGRect sinkBounds = CGRectInset(self.gvaView.bounds, view.frame.size.width/2, view.frame.size.height/2);
    CGFloat x = arc4random() % (int)sinkBounds.size.width + view.frame.size.width/2;
    CGFloat y = arc4random() % (int)sinkBounds.size.height + view.frame.size.height/2;
    view.center = CGPointMake(x, y);
}

#pragma mark - functional area selection buttons methods

- (IBAction)functionalAreaSelectionButtonsPressed:(UIButton *)sender {
    // highlight current functional area label
    [self.gvaView functionalAreaLabelSelected:sender.currentTitle];
}

#pragma mark - reconfigurable buttons methods

#define IMAGE_PICKER_IN_POPOVER YES
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
        } else {
            self.readyToSendText = NO;
        }
        
        self.textView.hidden = !self.readyToSendText;
        self.textField.hidden = !self.readyToSendText;
        self.sendTextButton.hidden = !self.readyToSendText;
        
    } else if ([sender.currentTitle isEqualToString:@"F3"]) {// send image
        if (!self.readyToSendImage) {
            self.readyToSendImage = YES;
        } else {
            self.readyToSendImage = NO;
        }
        
        self.sendImageButton.hidden = !self.readyToSendImage;
        self.saveImageButton.hidden = !self.readyToSendImage;
        
    } else if ([sender.currentTitle isEqualToString:@"F4"]) {//open camera
        if (!self.imagePopover && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
            
            if ([mediaTypes containsObject:(NSString *)kUTTypeImage]) {
                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                picker.delegate = self;
                picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
                picker.allowsEditing = YES;
                if (IMAGE_PICKER_IN_POPOVER) {
                    self.imagePopover = [[UIPopoverController alloc] initWithContentViewController:picker];
                    [self.imagePopover presentPopoverFromRect:CGRectMake(0, 0, 122, 830) inView:self.gvaView permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
                } else {
                    [self presentModalViewController:picker animated:YES];
                }
            }
        }
        
    } else if ([sender.currentTitle isEqualToString:@"F7"]) {//video
        [self setCaptureManager:[[CaptureSessionManager alloc] init]];
        
        [self.captureManager addVideoInputFrontCamera:NO]; // set to YES for Front Camera, No for Back camera
        
        [self.captureManager addStillImageOutput];
        
        [self.captureManager addVideoPreviewLayer];
        CGRect layerRect = CGRectMake(505, 173, 240, 240);
        [self.captureManager.previewLayer setBounds:layerRect];
        [self.captureManager.previewLayer setPosition:CGPointMake(CGRectGetMidX(layerRect),CGRectGetMidY(layerRect))];
        [self.gvaView.layer addSublayer:self.captureManager.previewLayer];
        
        [self.overlayImageView setFrame:CGRectMake(525, 193, 200, 200)];
        [self.gvaView addSubview:self.overlayImageView];
        
        [self.overlayButton setImage:[UIImage imageNamed:@"scanbutton.png"] forState:UIControlStateNormal];
        [self.overlayButton setFrame:CGRectMake(525, 275, 200, 200)];
        [self.overlayButton addTarget:self action:@selector(scanButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.gvaView addSubview:self.overlayButton];
        
        UILabel *tempLabel = [[UILabel alloc] initWithFrame:CGRectMake(585, 175, 400, 200)];
        [self setScanningLabel:tempLabel];
        
        [self.scanningLabel setBackgroundColor:[UIColor clearColor]];
        [self.scanningLabel setFont:[UIFont fontWithName:@"Courier" size: 18.0]];
        [self.scanningLabel setTextColor:[UIColor redColor]];
        [self.scanningLabel setText:@"Saving..."];
        [self.scanningLabel setHidden:YES];
        [self.gvaView addSubview:self.scanningLabel];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(saveImageToPhotoAlbum) name:kImageCapturedSuccessfully object:nil];
        
        self.captureManager.previewLayer.hidden = NO;
        self.overlayImageView.hidden = NO;
        self.overlayButton.hidden = NO;
        [self.captureManager.captureSession startRunning];
        
    } else if ([sender.currentTitle isEqualToString:@"F8"]) {//to be done
        [self.captureManager.captureSession stopRunning];
        self.captureManager.previewLayer.hidden = YES;
        self.scanningLabel.hidden = YES;
        self.overlayImageView.hidden = YES;
        self.overlayButton.hidden = YES;
    }else if ([sender.currentTitle isEqualToString:@"F5"]) {
        
        NSArray *devices = [AVCaptureDevice devices];
        AVCaptureDevice *frontCamera;
        AVCaptureDevice *backCamera;
        
        for (AVCaptureDevice *device in devices) {
            NSLog(@"Device name: %@", [device localizedName]);
            
            if ([device hasMediaType:AVMediaTypeVideo]) {
                if ([device position] == AVCaptureDevicePositionBack) {
                    NSLog(@"Device position : back");
                    backCamera = device;
                } else {
                    NSLog(@"Device position : front");
                    frontCamera = device;
                }
            }
        }
        
        NSError *error = nil;
        AVCaptureDeviceInput *backFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
        
        self.videoOutput.alwaysDiscardsLateVideoFrames = NO;
        
        self.videoOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        
        if (!error) {
            if ([self.captureSession canAddInput:backFacingCameraDeviceInput]) {
                [self.captureSession addInput:backFacingCameraDeviceInput];
            } else {
                NSLog(@"Couldn't add back facing video input.");
            }
            
            if ([self.captureSession canAddOutput:self.videoOutput]) {
                [self.captureSession addOutput:self.videoOutput];
            } else {
                NSLog(@"Couldn't add back facing video output.");
            }
            
            self.captureSession.sessionPreset = AVCaptureSessionPresetMedium;
            
            dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
            [self.videoOutput setSampleBufferDelegate:self queue:queue];
            
            dispatch_release(queue);
            [self.captureSession startRunning];
        }
        
    } else if ([sender.currentTitle isEqualToString:@"F6"]) { // stop video
        self.imageView.image = nil;
        [self.captureSession stopRunning];
        self.imageView.image = nil;
        
        if (self.session != nil) {
            NSError* error = nil;
            [self.session sendData:[@"iWantToStopVideo" dataUsingEncoding:NSUTF8StringEncoding]
                           toPeers:[NSArray arrayWithObject:self.peerID]
                      withDataMode:GKSendDataReliable
                             error:&error];
        }
        
    } else if ([sender.currentTitle isEqualToString:@"F10"]) { // overlay
        self.startOverlay = YES;
        [self.locationManager startUpdatingLocation];
        
    } else if ([sender.currentTitle isEqualToString:@"F11"]) { // close overlay
        self.startOverlay = NO;
        self.scanningLabel.text = @"";
        [self.locationManager stopUpdatingLocation];
        
        if (self.session != nil) {
            NSError* error = nil;
            [self.session sendData:[@"iWantToStopOverlay" dataUsingEncoding:NSUTF8StringEncoding]
                           toPeers:[NSArray arrayWithObject:self.peerID]
                      withDataMode:GKSendDataReliable
                             error:&error];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    //[[UIApplication sharedApplication] setStatusBarHidden:YES];// hide status bar
    return UIInterfaceOrientationIsLandscape(orientation);// only support landscape
}

- (void)setGvaView:(GvaView *)gvaView {
    _gvaView = gvaView;
    [self.gvaView setNeedsDisplay];
    [self.gvaView setNeedsLayout];
}

- (void)viewDidUnload {
    self.compass = nil;
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
    [self setOverlayTextView:nil];
    [super viewDidUnload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.locationManager = [[CLLocationManager alloc] init];
	self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	self.locationManager.headingFilter = 1;
	self.locationManager.delegate = self;
	[self.locationManager startUpdatingHeading];
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    
    self.informationBar.numberOfLines = 3;
    self.informationBar.text = @"";
    self.indicator.hidesWhenStopped = YES;
    self.progressView.hidden = YES;
    
    self.textView.hidden = YES;
    self.textField.hidden = YES;
    self.sendTextButton.hidden = YES;
    
    self.sendImageButton.hidden = YES;
    self.saveImageButton.hidden = YES;
    
    self.scanningLabel.numberOfLines = 6;
    [self.scanningLabel setBackgroundColor:[UIColor clearColor]];
    [self.scanningLabel setFont:[UIFont fontWithName:@"Courier" size: 15.0]];
    [self.scanningLabel setTextColor:[UIColor redColor]];
    //[self.scanningLabel setHidden:YES];
    [self.gvaView addSubview:self.scanningLabel];
    
    self.overlayTextView.opaque = NO;
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
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
	// Convert Degree to Radian and move the needle
	float oldRad = -manager.heading.trueHeading * M_PI / 180.0f;
	float newRad = -newHeading.trueHeading * M_PI / 180.0f;
	CABasicAnimation * theAnimation;
    theAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    theAnimation.fromValue = [NSNumber numberWithFloat:oldRad];
    theAnimation.toValue = [NSNumber numberWithFloat:newRad];
    theAnimation.duration = 0.5f;
    [self.compass.layer addAnimation:theAnimation forKey:@"animateMyRotation"];
    self.compass.transform = CGAffineTransformMakeRotation(newRad);
	//NSLog(@"%f (%f) => %f (%f)", manager.heading.trueHeading, oldRad, newHeading.trueHeading, newRad);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    //NSLog(@"OldLocation %f %f", oldLocation.coordinate.latitude, oldLocation.coordinate.longitude);
    //NSLog(@"NewLocation %f %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    
    if ([self.mode.text isEqualToString:@"Controller"]) {
        if (self.startOverlay) {
            
            if (self.session != nil) {
                //NSLog(@"here");
                NSError* error = nil;
                [self.session sendData:[self.scanningLabel.text dataUsingEncoding:NSUTF8StringEncoding]
                               toPeers:[NSArray arrayWithObject:self.peerID]
                          withDataMode:GKSendDataReliable
                                 error:&error];
                
                [self.scanningLabel setText:[NSString stringWithFormat:@"Sending to %@ ...", [self.session displayNameForPeer:self.peerID]]];
                
            }
            
            [self.scanningLabel setText:[self.scanningLabel.text stringByAppendingFormat:@"OldLocation %d %d =>\nNewLocation %d %d", (int)oldLocation.coordinate.latitude, (int)oldLocation.coordinate.longitude, (int)newLocation.coordinate.latitude, (int)newLocation.coordinate.longitude]];
        }
    }
}


@end
