//
//  SSUrbanAirship.h
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
 
#import <Foundation/Foundation.h>

@class ASIHTTPRequest;

@protocol SuburbanAirshipDelegate

- (void)tokenSucceeded;
- (void)tokenCanceled;
- (void)tokenFailed;
- (void)pushSucceeded:(NSArray *)aliases;
- (void)pushCanceled:(NSArray *)aliases;
- (void)pushFailed:(NSArray *)aliases;
- (void)cancelSucceeded:(NSArray *)aliases;
- (void)cancelCanceled:(NSArray *)aliases;
- (void)cancelFailed:(NSArray *)aliases;

@end

@interface SuburbanAirshipNotification : NSObject {
	
	NSString *alert;
	NSString *sound;
	NSNumber *badge;
	NSDate   *date;
	NSString *alias;	
	BOOL	 queued;
    NSArray  *userAliases;
    NSDictionary *customData;
}

@property (nonatomic, retain) NSString *alert;
@property (nonatomic, retain) NSString *sound;
@property (nonatomic, retain) NSNumber *badge;
@property (nonatomic, retain) NSDate  *date;
@property (nonatomic, retain) NSString *alias;
@property BOOL queued;
@property (nonatomic, retain) NSArray *userAliases;
@property (nonatomic, retain) NSDictionary *customData;

+ (id)alert:(NSString *)theAlert sound:(NSString *)theSound	badge:(NSNumber *)theBadge date:(NSDate *)theDate  alias:(NSString *)theAlias queued:(BOOL)theQueued;

- (BOOL)validNotification;

@end

@interface SuburbanAirship : NSObject {

	id delegate;
	BOOL batchModePush;					// Defaults to NO
	BOOL batchModeCancel;				// Defaults to YES
	
	NSString *deviceToken;
	NSString *_deviceToken;
	NSString *deviceAlias;
	NSMutableArray  *deviceTags;
	
	NSString *appKey;
	NSString *appSecret;
	NSString *appMaster;
	
	NSMutableArray *requestQueue;		// Staging area for batch process of ASIHTTPRequest
	NSMutableDictionary *notifDict;		// Saves {guid, SuburanAirshipNotif} key, value pairs (Easy retry)
	
	NSOperationQueue *operationQueue;
}

@property (nonatomic, retain) id delegate;
@property (nonatomic, readonly, retain) NSString *deviceToken;
@property (nonatomic, readonly, retain) NSString *deviceAlias;
@property (nonatomic, readonly, retain) NSMutableArray *deviceTags;
@property (nonatomic, retain) NSString *appKey;
@property (nonatomic, retain) NSString *appSecret;
@property (nonatomic, retain) NSString *appMaster;
@property BOOL batchModePush;
@property BOOL batchModeCancel;

- (id)initWithDelegate:(id)theDelegate key:(NSString*)key secret:(NSString *)secret master:(NSString *)master;

#pragma mark Registration Method
- (void)putDeviceToken:(NSData *)token;
- (void)putDeviceToken:(NSData *)token withDeviceAlias:(NSString *)alias;
- (void)putDeviceToken:(NSData *)token withDeviceAlias:(NSString *)alias withDeviceTags:(NSArray *)tags;
- (void)deleteDeviceToken;

#pragma mark Push Notifications Method
- (NSString *)pushAlert:(NSString *)alert;
- (NSString *)pushAlert:(NSString *)alert sound:(NSString *)sound;
- (NSString *)pushAlert:(NSString *)alert sound:(NSString *)sound badge:(NSNumber *)badge;
- (NSString *)pushScheduledAlert:(NSString *)alert date:(NSDate *)date;
- (NSString *)pushScheduledAlert:(NSString *)alert sound:(NSString *)sound date:(NSDate *)date;
- (NSString *)pushScheduledAlert:(NSString *)alert sound:(NSString *)sound badge:(NSNumber *)badge date:(NSDate *)date;

- (NSString *)queueAlert:(NSString *)alert;
- (NSString *)queueAlert:(NSString *)alert sound:(NSString *)sound;
- (NSString *)queueAlert:(NSString *)alert sound:(NSString *)sound badge:(NSNumber *)badge;
- (NSString *)queueScheduledAlert:(NSString *)alert date:(NSDate *)date;
- (NSString *)queueScheduledAlert:(NSString *)alert sound:(NSString *)sound date:(NSDate *)date;
- (NSString *)queueScheduledAlert:(NSString *)alert sound:(NSString *)sound badge:(NSNumber *)badge date:(NSDate *)date;

- (NSString *)pushSuburbanAirshipNotification:(SuburbanAirshipNotification *)notif;

#pragma mark Delete Scheduled Push Notifications Methods
- (void)cancelAllNotifications;
- (void)cancelNotificationWithAlias:(NSString *)alias;
- (void)cancelNotificationsWithAliases:(NSArray *)aliases;

#pragma mark Process Pending Notifications Method
- (void)sendNotificationsInQueue;

#pragma mark Misc Methods
- (SuburbanAirshipNotification *)suburbanAirshipNotifForGUID:(NSString *)guid;
- (BOOL)isUrbanAirshipReachable;

@end

