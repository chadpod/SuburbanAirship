//
//  SuburbanAirshipAppDelegate.m
//  SuburbanAirship
//
//  Created by Chad Podoski on 1/12/10.
//  Copyright Shacked Software 2010. All rights reserved.
//

#import "SuburbanAirshipAppDelegate.h"
#import "SuburbanAirshipViewController.h"

/* Urban Airship Constants */
#ifdef DEBUG
//Dev
#define kApplicationKey @"xmTd7LAYRSqEJ83lAYwXyQ"
#define kApplicationSecret @"PLGH3mrmTxyWiPebp5xYpQ"
#define kApplicationMasterSecret @"<Dev Master Secret Needed for Batch Mode"
#else
//Prod
#define kApplicationKey @"<Prod Key>"
#define kApplicationSecret @"<Prod Secret>"
#define kApplicationMasterSecret @"<Prod Master Secret Needed for Batch Mode>"
#endif

@implementation SuburbanAirshipAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize suburbanAirship;


- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
	self.suburbanAirship = [[SuburbanAirship alloc] initWithDelegate:self 
																 key:kApplicationKey 
															  secret:kApplicationSecret 
															  master:kApplicationMasterSecret];
	
	/* Register for push notifications */
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | 
																		   UIRemoteNotificationTypeSound | 
																		   UIRemoteNotificationTypeBadge)];
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}

#pragma mark -
#pragma mark Remote Notification Registration
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)_deviceToken {
	DLog(@"Apple Registration Succeeded");	
	[suburbanAirship putDeviceToken:_deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *) error {
	DLog(@"Apple Registration Failed %@", [error description]);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	DLog(@"Application Received Notification");
}

#pragma mark Push Method

#define NONQUEUED 1
#define QUEUED 0
#define MANUAL 0

- (void)pushMessage:(NSString *)message sound:(NSString *)sound badge:(NSNumber *)badge date:(NSDate *)date; {
	
	NSString *alias;
	
	if ( NONQUEUED) {

		/* Non queued version ... request are sent immediately */
		if (date == nil) {
			alias = [suburbanAirship pushAlert:message sound:sound badge:badge];
		}
		else {
			alias = [suburbanAirship pushScheduledAlert:message sound:sound badge:badge date:date];
		}
	}
	else if (QUEUED) {

		/* Queued version ... request are only sent after 'sendNotificationsInQueue' is called */
		if (date == nil) {
			alias = [suburbanAirship queueAlert:message sound:sound badge:badge];
		}
		else {
			alias = [suburbanAirship queueScheduledAlert:message sound:sound badge:badge date:date];
		}

		[suburbanAirship sendNotificationsInQueue];
	}
	else if (MANUAL) {

		/* Manually created notification ... allows for user to specify there own alias for a notification  */
		alias = @"SampleAlias12345";
		
		SuburbanAirshipNotification *saNotif = [SuburbanAirshipNotification alert:message
																			sound:sound 
																			badge:badge 
																			 date:date 
																			alias:alias
																		   queued:NO];
		[suburbanAirship pushSuburbanAirshipNotification:saNotif];
	} 
	
	/* Persist your aliases so you can cancel notification 
	 * if applicable, or to check responses */
}


#pragma mark -
#pragma mark Device Token Responses
- (void)tokenSucceeded; {
	DLog(@"Token Succeeded");
}

- (void)tokenFailed; {
	DLog(@"Token Failed");
}


#pragma mark -
#pragma mark Push Responses
- (void)pushSucceeded:(NSString *)alias; {
	DLog(@"Push Succeeded for alias %@", alias);
}

- (void)pushFailed:(NSString *)alias {
	DLog(@"Push Failed for alias %@", alias);
}


#pragma mark -
#pragma mark Cancel Responses
- (void)cancelSucceeded:(NSString *)alias; {	
	DLog(@"Cancel Succeeded for alias %@", alias);
}
	
- (void)cancelFailed:(NSString *)alias; {
	DLog(@"Cancel Failed for alias %@", alias);
}

@end
