//
//  CTMainController.m
//  NearChat
//
//  Created by BOREY on 14-3-26.
//  Copyright (c) 2014年 ctrip. All rights reserved.
//

#import "CTMainController.h"
#import "CTMsgProgress.h"
#import "CTMsgImage.h"
#import "CTMsgText.h"
#import "Transcript.h"
#import "SessionContainer.h"
#import "UITableViewCell+CTExtensions.h"
#import "CTMsgTextCell.h"
#import "CTMsgImageCell.h"
#import "CTMsgProgressCell.h"

NSString * const kDisplayName = @"displayName";
NSString * const kServiceType = @"serviceType";

typedef NS_ENUM(NSInteger, CTTextFieldResignType) {
    CTTextFieldResignTypeNone ,
    CTTextFieldResignTypeSend ,
    CTTextFieldResignTypeTakePhoto
};



@interface CTMainController () <SessionContainerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate , MCBrowserViewControllerDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, UIActionSheetDelegate> {
    CTTextFieldResignType resignType ;
}
@property(nonatomic, strong) NSMutableArray* transcripts ;
@property(nonatomic, strong) NSMutableDictionary* imageNameIndex ;
@property (strong, nonatomic) IBOutlet UITableView *mTableView;
@property (strong, nonatomic) IBOutlet UIToolbar *toobar;
@property (retain, nonatomic) SessionContainer *sessionContainer;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *sendMessageButton;
@property (strong, nonatomic) IBOutlet UITextField *messageComposeTextField;

@property(nonatomic, strong) MCPeerID* peerID ;
@property(nonatomic, strong) MCNearbyServiceAdvertiser* advertiser ;
@property(nonatomic, strong) MCNearbyServiceBrowser* browser ;

//
@property(nonatomic, strong) NSMutableArray* mutableBlockedPeers ;
@property (strong, nonatomic) IBOutlet UILabel *labelRoomCnt;

@end

@implementation CTMainController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"附近的人" ;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone ;
    }
    
    _transcripts = [NSMutableArray new];
    _imageNameIndex = [NSMutableDictionary new];
    
    //peerID
    NSString* displayName = [[UIDevice currentDevice] name] ;
    self.peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
    //Session
    [self createSession] ;
    //搜索
    [self createBrowserService] ;
    //广播
    [self createAdvertiserService] ;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"搜索" style:0 target:self action:@selector(onButtonSearch)] ;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Listen for will show/hide notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Stop listening for keyboard notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Table view data source

// Only one section in this example
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1 ;
}
// The numer of rows is based on the count in the transcripts arrays
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.transcripts.count;
}

// Return the height of the row based on the type of transfer and custom view it contains
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Dynamically compute the label size based on cell type (image, image progress, or text message)
    Transcript *transcript = [self.transcripts objectAtIndex:indexPath.row];
    if (nil != transcript.imageUrl) {
        return [CTMsgImage viewHeightForTranscript:transcript];
    }
    else if (nil != transcript.progress) {
        return [CTMsgProgress viewHeightForTranscript:transcript];
    }
    else {
        return [CTMsgText viewHeightForTranscript:transcript];
    }
}

// The individual cells depend on the type of Transcript at a given row.  We have 3 row types (i.e. 3 custom cells) for text string messages, resource transfer progress, and completed image resources
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Get the transcript for this row
    Transcript *transcript = [self.transcripts objectAtIndex:indexPath.row];
    
    if (nil != transcript.imageUrl) {
        CTMsgImageCell* cell = [CTMsgImageCell ctCellForTable:tableView withOwner:nil] ;
        cell.msgImage.transcript = transcript;
        return cell ;
    }
    else if (nil != transcript.progress) {
        CTMsgProgressCell* cell = [CTMsgProgressCell ctCellForTable:tableView withOwner:nil] ;
        cell.msgProgress.transcript = transcript;
        return cell ;
    }
    else {
        CTMsgTextCell* cell = [CTMsgTextCell ctCellForTable:tableView withOwner:nil] ;
        cell.msgText.transcript = transcript;
        return cell ;
    }
    return nil ;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    resignType = CTTextFieldResignTypeNone ;
    [self.messageComposeTextField resignFirstResponder];
}

#pragma mark - MCBrowserViewControllerDelegate methods

// Override this method to filter out peers based on application specific needs
- (BOOL)browserViewController:(MCBrowserViewController *)browserViewController shouldPresentNearbyPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    return YES;
}

// Override this to know when the user has pressed the "done" button in the MCBrowserViewController
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

// Override this to know when the user has pressed the "cancel" button in the MCBrowserViewController
- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - private methods

- (MCSession*) createSession {
    if(_sessionContainer==nil) {
        self.sessionContainer = [[SessionContainer alloc] initWithPeerID:self.peerID serviceType:kServiceType];
        _sessionContainer.delegate = self;
    }
    [self updateRoomPersonCount] ;
    return _sessionContainer.session ;
}
//搜索
- (void) createBrowserService {
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID serviceType:kServiceType] ;
    self.browser.delegate = self ;
    [self.browser startBrowsingForPeers] ;
}
//广播
- (void) createAdvertiserService {
    self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID discoveryInfo:nil serviceType:kServiceType] ;
    self.advertiser.delegate = self ;
    [self.advertiser startAdvertisingPeer] ;
}

// Helper method for inserting a sent/received message into the data source and reload the view.
// Make sure you call this on the main thread
- (void)insertTranscript:(Transcript *)transcript
{
    // Add to the data source
    [_transcripts addObject:transcript];
    
    // If this is a progress transcript add it's index to the map with image name as the key
    if (nil != transcript.progress) {
        NSNumber *transcriptIndex = [NSNumber numberWithUnsignedLong:(_transcripts.count - 1)];
        [_imageNameIndex setObject:transcriptIndex forKey:transcript.imageName];
    }
    
    // Update the table view
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:([self.transcripts count] - 1) inSection:0];
    [self.mTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    // Scroll to the bottom so we focus on the latest message
    NSUInteger numberOfRows = [self.mTableView numberOfRowsInSection:0];
    if (numberOfRows) {
        [self.mTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(numberOfRows - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (void) onButtonSearch {
    
    
    return ;
    MCBrowserViewController *browserViewController = [[MCBrowserViewController alloc] initWithServiceType:kServiceType session:self.createSession];
    browserViewController.delegate = self;
    browserViewController.minimumNumberOfPeers = kMCSessionMinimumNumberOfPeers;
    browserViewController.maximumNumberOfPeers = kMCSessionMaximumNumberOfPeers;
    
    [self.navigationController presentViewController:browserViewController animated:YES completion:nil];
}



- (void) updateRoomPersonCount {
    dispatch_async(dispatch_get_main_queue(), ^{
		int count = self.sessionContainer.session.connectedPeers.count + 1 ;
        self.labelRoomCnt.text = [NSString stringWithFormat:@"共%d人在线", count] ;
    });
}

- (void) sendTextMessage {
    // Check if there is any message to send
    if (self.messageComposeTextField.text.length>0) {
        
        // Send the message
        Transcript *transcript = [self.sessionContainer sendMessage:self.messageComposeTextField.text];
        
        if (transcript) {
            // Add the transcript to the table view data source and reload
            [self insertTranscript:transcript];
        }
        
        // Clear the textField and disable the send button
        self.messageComposeTextField.text = @"";
        self.sendMessageButton.enabled = NO;
    }
}

- (void) takePhoto {
    // Preset an action sheet which enables the user to take a new picture or select and existing one.
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消"  destructiveButtonTitle:nil otherButtonTitles:@"拍照", @"选取现有的", nil];
    // Show the action sheet
    [sheet showFromToolbar:self.toobar] ;
}

#pragma mark - Button Event methods
- (IBAction)sendMessageTapped:(id)sender
{
    if(self.messageComposeTextField.isFirstResponder==NO) {
        [self sendTextMessage] ;
    }
    else {
        resignType = CTTextFieldResignTypeSend ;
        [self.messageComposeTextField resignFirstResponder];
    }
}

- (IBAction)onButtonSelectPhoto:(id)sender {
    if(self.messageComposeTextField.isFirstResponder==NO) {
        [self takePhoto] ;
    }
    else {
        resignType = CTTextFieldResignTypeTakePhoto ;
        [self.messageComposeTextField resignFirstResponder];
    }
}

#pragma mark - Toolbar animation helpers

// Helper method for moving the toolbar frame based on user action
- (void)moveToolBarUp:(BOOL)up forKeyboardNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    
    // Get animation info from userInfo
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
    
    // Animate up or down
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    CGRect rect  =self.toobar.frame ;
    if(up) {
        rect.origin.y = self.view.frame.size.height - self.toobar.frame.size.height - keyboardFrame.size.height ;
    }
    else {
        rect.origin.y = self.view.frame.size.height - self.toobar.frame.size.height ;
    }
    self.toobar.frame = rect  ;
    [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    // move the toolbar frame up as keyboard animates into view
    [self moveToolBarUp:YES forKeyboardNotification:notification];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    // move the toolbar frame down as keyboard animates into view
    [self moveToolBarUp:NO forKeyboardNotification:notification];
}


#pragma mark - UITextFieldDelegate methods

// Override to dynamically enable/disable the send button based on user typing
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger length = self.messageComposeTextField.text.length - range.length + string.length;
    if (length > 0) {
        self.sendMessageButton.enabled = YES;
    }
    else {
        self.sendMessageButton.enabled = NO;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField endEditing:YES];
    return YES;
}

// Delegate method called when the message text field is resigned.
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (resignType==CTTextFieldResignTypeTakePhoto) {
        [self takePhoto] ;
    }
    else if (resignType==CTTextFieldResignTypeSend) {
        [self sendTextMessage] ;
    }
}


#pragma mark - MCNearbyServiceAdvertiserDelegate methods
// Incoming invitation request.  Call the invitationHandler block with YES and a valid session to connect the inviting peer to the session.
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler {
    NSLog(@"%s", __FUNCTION__) ;
    if ([self.mutableBlockedPeers containsObject:peerID]) {
        invitationHandler(NO, nil);
        return;
    }
    if (peerID) {
        [self.mutableBlockedPeers addObject:peerID];
        invitationHandler(YES, self.sessionContainer.session) ;
    }
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    NSLog(@"Advertising did not start due to an error: %@", error.description) ;
}

#pragma mark - MCNearbyServiceBrowserDelegate methods

// Found a nearby advertising peer
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    NSLog(@"%s", __FUNCTION__) ;

    if([self.sessionContainer.session.connectedPeers containsObject:peerID]==NO) {
        [browser invitePeer:peerID toSession:self.sessionContainer.session withContext:nil timeout:30] ;
    }
}

// A nearby peer has stopped advertising
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    [self updateRoomPersonCount] ;
    [browser invitePeer:peerID toSession:self.sessionContainer.session withContext:nil timeout:30] ;
}

// Browsing did not start due to an error
- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    NSLog(@"Browsing did not start due to an error: %@", error.description) ;
}

#pragma mark - SessionContainerDelegate methods
// Method used to signal to UI an initial message, incoming image resource has been received
- (void)receivedTranscript:(Transcript *)transcript {
    dispatch_async(dispatch_get_main_queue(), ^{
		[self insertTranscript:transcript];
    });
}
// Method used to signal to UI an image resource transfer (send or receive) has completed
- (void)updateTranscript:(Transcript *)transcript {
    // Find the data source index of the progress transcript
    NSNumber *index = [_imageNameIndex objectForKey:transcript.imageName];
    NSUInteger idx = [index unsignedLongValue];
    // Replace the progress transcript with the image transcript
    [_transcripts replaceObjectAtIndex:idx withObject:transcript];
    
    // Reload this particular table view row on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:idx inSection:0];
        [self.mTableView reloadRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}
//更新人数
- (void)updateConnectPeers {
    [self updateRoomPersonCount] ;
}

#pragma mark - UIActionSheetDelegate methods

// Override this method to know if user wants to take a new photo or select from the photo library
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex==actionSheet.cancelButtonIndex) {
        return ;
    }
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    if (imagePicker) {
        imagePicker.delegate = self;
        if (0 == buttonIndex) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        }
        else if (1 == buttonIndex) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Camera" message:@"Please use a camera enabled device" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - UIImagePickerViewControllerDelegate

// For responding to the user tapping Cancel.
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

// Override this delegate method to get the image that the user has selected and send it view Multipeer Connectivity to the connected peers.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    // Don't block the UI when writing the image to documents
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // We only handle a still image
        UIImage *imageToSave = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
        
        // Save the new image to the documents directory
        NSData *pngData = UIImageJPEGRepresentation(imageToSave, 1.0);
        
        // Create a unique file name
        NSDateFormatter *inFormat = [NSDateFormatter new];
        [inFormat setDateFormat:@"yyMMdd-HHmmss"];
        NSString *imageName = [NSString stringWithFormat:@"image-%@.JPG", [inFormat stringFromDate:[NSDate date]]];
        // Create a file path to our documents directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:imageName];
        [pngData writeToFile:filePath atomically:YES]; // Write the file
        // Get a URL for this file resource
        NSURL *imageUrl = [NSURL fileURLWithPath:filePath];
        
        // Send the resource to the remote peers and get the resulting progress transcript
        Transcript *transcript = [self.sessionContainer sendImage:imageUrl];
        
        // Add the transcript to the data source and reload
        dispatch_async(dispatch_get_main_queue(), ^{
            [self insertTranscript:transcript];
        });
    });
}



@end
