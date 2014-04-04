//
//  AppDelegate.m
//  NearChat
//
//  Created by BOREY on 14-3-26.
//  Copyright (c) 2014年 ctrip. All rights reserved.
//

#import "AppDelegate.h"
#import "CTMainController.h"

@import CoreLocation;
@import MultipeerConnectivity ;

@interface AppDelegate() <CLLocationManagerDelegate, MCBrowserViewControllerDelegate>
@property CLLocationManager *locationManager;

@property(nonatomic, strong) MCPeerID* peerID ;
@property(nonatomic, strong) MCSession* session ;

@property(nonatomic, strong) CTMainController* mainController ;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.mainController = [[CTMainController alloc] initWithNibName:@"CTMainController" bundle:nil] ;
    UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:self.mainController] ;
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    
    // This location manager will be used to notify the user of region state transitions.
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    [self installedApp] ;UIBackgroundTaskIdentifier
    
    return YES;
}

#pragma mark - Init
-(NSMutableArray *)desktopAppsFromDictionary:(NSDictionary *)dictionary
{
    NSMutableArray *desktopApps = [NSMutableArray array];
    
    for (NSString *appKey in dictionary)
    {
        [desktopApps addObject:appKey];
    }
    return desktopApps;
}

-(NSArray *)installedApp
{
    static NSString* const installedAppListPath = @"/private/var/mobile/Library/Caches/com.apple.mobile.installation.plist";

    BOOL isDir = NO;
    if([[NSFileManager defaultManager] fileExistsAtPath: installedAppListPath isDirectory: &isDir] && !isDir)
    {
        NSMutableDictionary *cacheDict = [NSDictionary dictionaryWithContentsOfFile: installedAppListPath];
        NSDictionary *system = [cacheDict objectForKey: @"System"];
        NSMutableArray *installedApp = [NSMutableArray arrayWithArray:[self desktopAppsFromDictionary:system]];
        
        NSDictionary *user = [cacheDict objectForKey: @"User"];
        [installedApp addObjectsFromArray:[self desktopAppsFromDictionary:user]];
        
        return installedApp;
    }
    
    //DLOG(@"can not find installed app plist");
    return nil;
}

							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = @"进入进入进入进入进入进入进入进入进入进入" ;
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark iBeacon
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    
    if(state == CLRegionStateInside)
    {
        notification.alertBody = @"进入" ;
    }
    else if(state == CLRegionStateOutside)
    {
        notification.alertBody = @"离开" ;
    }
    else
    {
        return;
    }
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    if (notification.alertBody.length>0 && [notification.alertBody isEqualToString:@"进入"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"进入" message:@"即将搜索周围设备。" delegate:self cancelButtonTitle:nil otherButtonTitles:@"好", nil];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex!=alertView.cancelButtonIndex) {
        [self browseForPeers] ;
    }
}

- (void)browseForPeers {
    MCBrowserViewController *browserViewController = [[MCBrowserViewController alloc] initWithServiceType:@"displayName" session:self.mainController.createSession];
	browserViewController.delegate = self;
    browserViewController.minimumNumberOfPeers = kMCSessionMinimumNumberOfPeers;
    browserViewController.maximumNumberOfPeers = kMCSessionMaximumNumberOfPeers;
    
    [self.window.rootViewController presentViewController:browserViewController animated:YES completion:nil];
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


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandle{
    
}


@end
