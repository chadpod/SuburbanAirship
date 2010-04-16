//
//  SSUrbanAirship.m
//  The Now
//
//  Created by Chad Podoski on 1/4/10.
//  Copyright 2010 Shacked Software. All rights reserved.
//
/*
 Copyright (c) 2010, Shacked Software (dev@shackedsoftware.com)
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, 
 are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, 
 this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright notice, 
 this list of conditions and the following disclaimer in the documentation 
 and/or other materials provided with the distribution.
 
 - Neither the name of the copyright holder nor the names of its contributors 
 may be used to endorse or promote products derived from this software without 
 specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE.
 */

// TODO: Persist notifDict so user does not have to track aliases if they don't want to

#import <SystemConfiguration/SystemConfiguration.h>
#import "SuburbanAirship.h"
#import "ASIHTTPRequest.h"
#import "CJSONSerializer.h"
#import "CJSONDeserializer.h"
#import "Reachability.h"

@implementation SuburbanAirshipNotification

@synthesize alert;
@synthesize sound;
@synthesize badge;
@synthesize date;
@synthesize alias;
@synthesize queued;

+ (id)alert:(NSString *)theAlert sound:(NSString *)theSound	badge:(NSNumber *)theBadge date:(NSDate *)theDate  alias:(NSString *)theAlias queued:(BOOL)theQueued; {
	
	SuburbanAirshipNotification *notif = [[[SuburbanAirshipNotification alloc] init] autorelease];

	notif.alert = theAlert;
	notif.sound = theSound;
	notif.badge = theBadge;
	notif.date = theDate;
	notif.alias = theAlias;
	notif.queued = theQueued;

	return notif;	
}

- (BOOL)validNotification; {
	if ((self.alert != nil && [self.alert length] != 0) ||
		(self.sound != nil && [self.sound length] != 0) ||
		(self.badge != nil)) {
		return YES;
	}
	else {
		return NO;
	}

}

@end

@interface SuburbanAirship ()

@property (nonatomic, readwrite, retain) NSString *_deviceToken;
@property (nonatomic, readwrite, retain) NSString *deviceToken;
@property (nonatomic, readwrite, retain) NSString *deviceAlias;
@property (nonatomic, readwrite, retain) NSMutableArray *deviceTags;
@property (nonatomic, retain) NSMutableArray *requestQueue;
@property (nonatomic, retain) NSMutableDictionary *notifDict;
@property (nonatomic, retain) NSOperationQueue *operationQueue;


- (NSString *)guid;
- (ASIHTTPRequest *)requestForNotification:(SuburbanAirshipNotification *)notif;
- (NSDictionary *)jsonForNotification:(SuburbanAirshipNotification *)notif;

- (void)saTokenSucceeded:(ASIHTTPRequest *)request;
- (void)saTokenFailed:(ASIHTTPRequest *)request;
- (void)saPushSucceeded:(ASIHTTPRequest *)request;
- (void)saPushFailed:(ASIHTTPRequest *)request;
- (void)saCancelSucceeded:(ASIHTTPRequest *)request;
- (void)saCancelFailed:(ASIHTTPRequest *)request;

@end


@implementation SuburbanAirship

@synthesize delegate;
@synthesize batchModePush;
@synthesize batchModeCancel;
@synthesize _deviceToken;
@synthesize deviceToken;
@synthesize deviceAlias;
@synthesize deviceTags;
@synthesize appKey;
@synthesize appSecret;
@synthesize appMaster;
@synthesize requestQueue;
@synthesize notifDict;
@synthesize operationQueue;

static NSString *SABaseURL = @"go.urbanairship.com";
static NSString *SADeviceTokenURL = @"https://go.urbanairship.com/api/device_tokens/";
static NSString *SAPushURL = @"https://go.urbanairship.com/api/push/";
static NSString *SAScheduledAliasURL = @"https://go.urbanairship.com/api/push/scheduled/alias/";
//static NSString *SABatchURL = @"https://go.urbanairship.com/api/push/batch/";
static NSString *SACancelURL = @"https://go.urbanairship.com/api/push/scheduled/";

static NSString *SAUserInfoScheduledAliasKey = @"SAUserInfoScheduledAlias";

static NSString *SAJSONDeviceTokenKey = @"device_tokens";
static NSString *SAJSONScheduleForKey = @"schedule_for";
static NSString *SAJSONScheduledAliasKey = @"alias";
static NSString *SAJSONScheduledTimeKey = @"scheduled_time";
static NSString *SAJSONAPSKey = @"aps";
static NSString *SAJSONBadgeKey = @"badge";
static NSString *SAJSONAlertKey = @"alert";
static NSString *SAJSONSoundKey = @"sound";
static NSString *SAJSONAliasKey = @"alias";
static NSString *SAJSONCancelAliasesKey = @"cancel_aliases";
static NSString *SAJSONTagsKey = @"tags";
//static NSString *SAJSONScheduledURLKey = @"scheduled_notifications";
//static NSString *SAJSONCancelURLKey = @"cancel";
//static NSString *SAJSONTokenAliasesKey = @"aliases";
//static NSString *SAJSONExcludeTokensKey = @"exclude_tokens";


- (id)init {
	return [self initWithDelegate:nil key:nil secret:nil master:nil];
}

- (id)initWithDelegate:(id)theDelegate key:(NSString*)key secret:(NSString *)secret master:(NSString *)master; {
	
	if ((self = [super init]) != nil) {
		delegate = [theDelegate retain];
		batchModePush = NO;
		batchModeCancel = YES;
		
		appKey = [key retain];
		appSecret = [secret retain];
		appMaster = [master retain];
		
		requestQueue = [[NSMutableArray alloc] init];
		operationQueue = [[NSOperationQueue alloc] init];
		
	}
	return self;
}

- (void)dealloc {
	self.delegate = nil;
	self.deviceToken = nil;
	self.deviceAlias = nil;
	self.deviceTags = nil;
	self.appKey = nil;
	self.appSecret = nil;
	self.appMaster = nil;
	self.requestQueue = nil;
	self.operationQueue = nil;
	[super dealloc];
}

- (NSString *)guid; {
	
	CFUUIDRef guid = NULL;
	
	@try {
		guid = CFUUIDCreate(NULL);
		return [(NSString *)CFUUIDCreateString(NULL, guid) autorelease];
	}@finally {		
		if(guid) {
			CFRelease(guid);
		}
	}
	
	return nil;
}


#pragma Registration Methods
- (void)putDeviceToken:(NSData *)token; {
	[self putDeviceToken:token withDeviceAlias:nil withDeviceTags:nil];
}

- (void)putDeviceToken:(NSData *)token withDeviceAlias:(NSString *)alias;  {
	[self putDeviceToken:token withDeviceAlias:alias withDeviceTags:nil];
}

- (void)putDeviceToken:(NSData *)token withDeviceAlias:(NSString *)alias withDeviceTags:(NSArray *)tags; {
	
	/* Get a hex string from the device token with no spaces or < > */
	self._deviceToken = [[[[token description] stringByReplacingOccurrencesOfString:@"<"withString:@""] 
						  stringByReplacingOccurrencesOfString:@">" withString:@""] 
						 stringByReplacingOccurrencesOfString: @" " withString: @""];
	
	/* Build the ASIHTTPRequest */
	NSString *urlString = [NSString stringWithFormat:@"%@%@/", SADeviceTokenURL, self._deviceToken];
	NSURL *url = [NSURL URLWithString:urlString];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	request.requestMethod = @"PUT";
	request.username = self.appKey;
	request.password = self.appSecret;
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(saTokenSucceeded:)];
	[request setDidFailSelector:@selector(saTokenFailed:)];
	
	/* Append JSON Payload if alias or tags specified */
	if ((alias != nil && [alias	length] != 0) ||
		(tags != nil && [tags count] != 0)) {
		
		NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithCapacity:2];
		
		if (alias != nil && [alias	length] != 0) {
			[jsonDict setObject:alias forKey:SAJSONAliasKey];
		}
		
		if (tags != nil && [tags count] != 0) {
			[jsonDict setObject:tags forKey:SAJSONTagsKey];
		}
		
		DLog(@"Token %@", [[CJSONSerializer serializer] serializeDictionary:jsonDict]);
		[request addRequestHeader: @"Content-Type" value: @"application/json"];
		[request appendPostData:
		 [[[CJSONSerializer serializer] serializeDictionary:jsonDict] dataUsingEncoding:NSUTF8StringEncoding]];
		
	}
	
	/* Process request using an NSOperationQueue */
	[operationQueue addOperation:request];

}

- (void)deleteDeviceToken; {
	DLog(@"Delete device token");
	/* Build the ASIHTTPRequest */
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/", SADeviceTokenURL, self.deviceToken]];
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
	request.requestMethod = @"DELETE";
	request.username = self.appKey;
	request.password = self.appSecret;
		
	/* Process request using an NSOperationQueue */
	[operationQueue addOperation:request];

}

- (void)saTokenSucceeded:(ASIHTTPRequest *)request; {
	DLog(@"Token Succeeded");
	self.deviceToken = _deviceToken;
	[delegate tokenSucceeded];
}

- (void)saTokenFailed:(ASIHTTPRequest *)request; {
	if ([[request error] code] == ASIRequestCancelledErrorType) {
		DLog(@"Token Canceled");	
		[delegate tokenCanceled];
	}
	else {
		DLog(@"Token Failed");	
		[delegate tokenFailed];
	}	
}


#pragma Push Notifications Methods
- (NSString *)pushAlert:(NSString *)alert; {
	return [self pushSuburbanAirshipNotification:[SuburbanAirshipNotification alert:alert sound:nil badge:nil date:nil alias:nil queued:NO]];
}

- (NSString *)pushAlert:(NSString *)alert sound:(NSString *)sound; {
	return [self pushSuburbanAirshipNotification:[SuburbanAirshipNotification alert:alert sound:sound badge:nil date:nil alias:nil queued:NO]];
}

- (NSString *)pushAlert:(NSString *)alert sound:(NSString *)sound badge:(NSNumber *)badge; {
	return [self pushSuburbanAirshipNotification:[SuburbanAirshipNotification alert:alert sound:sound badge:badge date:nil alias:nil queued:NO]];
}

- (NSString *)pushScheduledAlert:(NSString *)alert date:(NSDate *)date; {
	return [self pushSuburbanAirshipNotification:[SuburbanAirshipNotification alert:alert sound:nil badge:nil date:date alias:nil queued:NO]];
}

- (NSString *)pushScheduledAlert:(NSString *)alert sound:(NSString *)sound date:(NSDate *)date; {
	return [self pushSuburbanAirshipNotification:[SuburbanAirshipNotification alert:alert sound:sound badge:nil date:date alias:nil queued:NO]];
}

- (NSString *)pushScheduledAlert:(NSString *)alert sound:(NSString *)sound badge:(NSNumber *)badge date:(NSDate *)date; {
	return [self pushSuburbanAirshipNotification:[SuburbanAirshipNotification alert:alert sound:sound badge:badge date:date alias:nil queued:NO]];
}

- (NSString *)queueAlert:(NSString *)alert; {
	return [self pushSuburbanAirshipNotification:[SuburbanAirshipNotification alert:alert sound:nil badge:nil date:nil alias:nil queued:YES]];
}

- (NSString *)queueAlert:(NSString *)alert sound:(NSString *)sound; {
	return [self pushSuburbanAirshipNotification:[SuburbanAirshipNotification alert:alert sound:sound badge:nil date:nil alias:nil queued:YES]];
}

- (NSString *)queueAlert:(NSString *)alert sound:(NSString *)sound badge:(NSNumber *)badge; {
	return [self pushSuburbanAirshipNotification:[SuburbanAirshipNotification alert:alert sound:sound badge:badge date:nil alias:nil queued:YES]];
}

- (NSString *)queueScheduledAlert:(NSString *)alert date:(NSDate *)date; {
	return [self pushSuburbanAirshipNotification:[SuburbanAirshipNotification alert:alert sound:nil badge:nil date:date alias:nil queued:YES]];
}

- (NSString *)queueScheduledAlert:(NSString *)alert sound:(NSString *)sound date:(NSDate *)date; {
	return [self pushSuburbanAirshipNotification:[SuburbanAirshipNotification alert:alert sound:sound badge:nil date:date alias:nil queued:YES]];
}		
	
- (NSString *)queueScheduledAlert:(NSString *)alert sound:(NSString *)sound badge:(NSNumber *)badge date:(NSDate *)date; {
	return [self pushSuburbanAirshipNotification:[SuburbanAirshipNotification alert:alert sound:sound badge:badge date:date alias:nil queued:YES]];
}
	
- (NSString *)pushSuburbanAirshipNotification:(SuburbanAirshipNotification *)notif {
	
	NSString *alias = nil;
	
	/* Only create if one or more of parameters is valid */
	if ([notif validNotification]) {
		
		/* If user didn't specified an alias, make one up */
		if (notif.alias == nil || [notif.alias length] == 0) {
			notif.alias = [self guid];
		}
		
		/* Store guid for reference */
		alias = notif.alias;
		[notifDict setObject:notif forKey:alias];
		
		/* Notification type is either queued or send immediately */
		if (notif.queued) {
			[requestQueue addObject:notif];
		}
		else {
			[operationQueue addOperation:[self requestForNotification:notif]];
		}
	}
	
	return alias;
}

- (void)saPushSucceeded:(ASIHTTPRequest *)request; {
	DLog(@"Push Succeeded with Alias = %@", [[request userInfo] objectForKey:SAUserInfoScheduledAliasKey]);
	[delegate pushSucceeded:[[request userInfo] objectForKey:SAUserInfoScheduledAliasKey]];
}

- (void)saPushFailed:(ASIHTTPRequest *) request; {
	if ([[request error] code] == ASIRequestCancelledErrorType) {
		DLog(@"Push Cancelled with Alias = %@", [[request userInfo] objectForKey:SAUserInfoScheduledAliasKey]);	
		[delegate pushCanceled:[[request userInfo] objectForKey:SAUserInfoScheduledAliasKey]];
	}
	else {
		DLog(@"Push Failed with Alias = %@", [[request userInfo] objectForKey:SAUserInfoScheduledAliasKey]);	
		[delegate pushFailed:[[request userInfo] objectForKey:SAUserInfoScheduledAliasKey]];
	}
}


#pragma Delete Scheduled Push Notifications Methods
- (void)cancelAllNotifications; {
	[self cancelNotificationsWithAliases:[self.notifDict allKeys]];
}

- (void)cancelNotificationWithAlias:(NSString *)alias; {
	[self cancelNotificationsWithAliases:[NSArray arrayWithObject:alias]];
}

- (void)cancelNotificationsWithAliases:(NSArray *)aliases; {
	
	if (aliases != nil && [aliases count] != 0) {
		
		if (batchModeCancel) {
			ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] 
								initWithURL:[NSURL URLWithString:SACancelURL]] autorelease];
			request.requestMethod = @"POST";
			request.username = self.appKey;
			request.password = self.appSecret;
			request.userInfo = [NSDictionary dictionaryWithObject:aliases forKey:SAUserInfoScheduledAliasKey];
			[request setDelegate:self];
			[request setDidFinishSelector: @selector(saCancelSucceeded:)];
			[request setDidFailSelector: @selector(saCancelFailed:)];
			
			NSDictionary *jsonDict = [NSDictionary dictionaryWithObject:aliases forKey:SAJSONCancelAliasesKey];
			[request addRequestHeader: @"Content-Type" value: @"application/json"];			
			[request appendPostData:
			 [[[CJSONSerializer serializer] serializeDictionary:jsonDict] dataUsingEncoding:NSUTF8StringEncoding]];
			
			DLog(@"Cancel Aliases %@", [[CJSONSerializer serializer] serializeDictionary:jsonDict]);
			
			/* Process request using an NSOperationQueue */
			[operationQueue addOperation:request];				
		}
		else {
			for (NSString *alias in aliases) {
				ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] 
								initWithURL:[NSURL URLWithString:[SAScheduledAliasURL stringByAppendingString:alias]]] autorelease];
				request.requestMethod = @"DELETE";
				request.username = self.appKey;
				request.password = self.appSecret;
				request.userInfo = [NSDictionary dictionaryWithObject:[NSArray arrayWithObject:alias] forKey:SAUserInfoScheduledAliasKey];
				[request setDelegate:self];
				[request setDidFinishSelector: @selector(saCancelSucceeded:)];
				[request setDidFailSelector: @selector(saCancelFailed:)];
				
				DLog(@"Cancel %@", alias);
				
				/* Process request using an NSOperationQueue */
				[operationQueue addOperation:request];		
			}
		}

	}
}

- (void)saCancelSucceeded:(ASIHTTPRequest *) request; {
	DLog(@"Cancel Succeeded with Alias = %@", [[request userInfo] objectForKey:SAUserInfoScheduledAliasKey]);
	[delegate cancelSucceeded:[[request userInfo] objectForKey:SAUserInfoScheduledAliasKey]];
}

- (void)saCancelFailed:(ASIHTTPRequest *) request; {
	if ([[request error] code] == ASIRequestCancelledErrorType) {
		DLog(@"Cancel Canceled with Alias = %@", [[request userInfo] objectForKey:SAUserInfoScheduledAliasKey]);	
		[delegate cancelCanceled:[[request userInfo] objectForKey:SAUserInfoScheduledAliasKey]];
	}
	else {
		DLog(@"Cancel Failed with Alias = %@", [[request userInfo] objectForKey:SAUserInfoScheduledAliasKey]);	
		[delegate cancelFailed:[[request userInfo] objectForKey:SAUserInfoScheduledAliasKey]];
	}
}


#pragma Notifications Helper Method
- (void)sendNotificationsInQueue; {
	
	if (self.requestQueue != nil && [self.requestQueue count] != 0) {		
		NSArray *cache = [NSArray arrayWithArray:self.requestQueue];
		self.requestQueue = [NSMutableArray array];

		//
		// Removed batch mode for sending because json payload does not support passing in 
		// scheduled notif aliases yet.  When UA adds alias to this payload, this should be an easy addition
		//
//		if (batchModePush) {
//			/* Create a bulk Push request and configure its properties */
//			ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] 
//										initWithURL:[NSURL URLWithString:SABatchURL]] autorelease];
//			request.requestMethod = @"POST";
//			request.username = self.appKey;
//			request.password = self.appMaster;
//			[request setDelegate:self];
//			[request setDidFinishSelector: @selector(saPushSucceeded:)];
//			[request setDidFailSelector: @selector(saPushFailed:)];
//			
//			NSMutableArray *jsonArray = [NSMutableArray arrayWithCapacity:[cache count]];
//			for (SuburbanAirshipNotification *notif in cache) {
//				[jsonArray addObject:[self jsonForNotification:notif]];
//			}
//			
//			[request addRequestHeader:@"Content-Type" value:@"application/json"];
//			[request appendPostData:[[[CJSONSerializer serializer] serializeArray:jsonArray] dataUsingEncoding:NSUTF8StringEncoding]];
//	
//			DLog(@"Push %@", [[CJSONSerializer serializer] serializeArray:jsonArray]);
//			
//			/* Process request using an NSOperationQueue */
//			[operationQueue addOperation:request];
//			
//		}
//		else {
			for (SuburbanAirshipNotification *notif in cache) {
				[operationQueue addOperation:[self requestForNotification:notif]];
			}
//		}
	}
}

- (ASIHTTPRequest *)requestForNotification:(SuburbanAirshipNotification *)notif {
	
	/* Create a single notification Push request and configure its properties */
	ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] 
								initWithURL:[NSURL URLWithString:SAPushURL]] autorelease];
	request.requestMethod = @"POST";
	request.username = self.appKey;
	request.password = self.appSecret;
	request.userInfo = [NSDictionary dictionaryWithObject:[NSArray arrayWithObject:notif.alias] forKey:SAUserInfoScheduledAliasKey];
	[request setDelegate:self];
	[request setDidFinishSelector: @selector(saPushSucceeded:)];
	[request setDidFailSelector: @selector(saPushFailed:)];
	
	/* Build JSON Payload */
	NSDictionary *jsonDict = [self jsonForNotification:notif];
	[request addRequestHeader:@"Content-Type" value:@"application/json"];
	[request appendPostData:[[[CJSONSerializer serializer] serializeDictionary:jsonDict] dataUsingEncoding:NSUTF8StringEncoding]];
	
	DLog(@"Push %@", [[CJSONSerializer serializer] serializeDictionary:jsonDict]);
			
	return request;
}

- (NSDictionary *)jsonForNotification:(SuburbanAirshipNotification *)notif; {
	
	NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithCapacity:6];
	NSMutableDictionary *apsDict = [NSMutableDictionary dictionaryWithCapacity:3];
	
	if (notif.alert != nil && [notif.alert	length] != 0) {
		[apsDict setObject:notif.alert forKey:SAJSONAlertKey];
	}
	
	if (notif.sound != nil && [notif.sound	length] != 0) {
		[apsDict setObject:notif.sound forKey:SAJSONSoundKey];
	}
	
	if (notif.badge != nil) {
		[apsDict setObject:notif.badge forKey:SAJSONBadgeKey];
	}
	
	[jsonDict setObject:[NSArray arrayWithObject:self.deviceToken] forKey:SAJSONDeviceTokenKey];
	[jsonDict setObject:apsDict forKey:SAJSONAPSKey];
	
	if (notif.date != nil) {
		/* Set up a dateformater for ISO 8601 Format in UTC */
		NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
		[df setLocale:[[[NSLocale alloc] initWithLocaleIdentifier: @"en_US"] autorelease]]; 
		[df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
		[df setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];

		NSDictionary *scheduleDict = [NSDictionary dictionaryWithObjectsAndKeys:
									  [df stringFromDate:notif.date], SAJSONScheduledTimeKey,
									  notif.alias, SAJSONScheduledAliasKey, nil];
		[jsonDict setObject:[NSArray arrayWithObject:scheduleDict] forKey:SAJSONScheduleForKey];	
	}
	
	return jsonDict;
}


#pragma mark Misc Methods
- (SuburbanAirshipNotification *)suburbanAirshipNotifForGUID:(NSString *)guid; {
	return [notifDict objectForKey:guid];
}

- (BOOL)isUrbanAirshipReachable;
{
	return ([[Reachability reachabilityWithHostName:SABaseURL] currentReachabilityStatus] != NotReachable);
}


@end
