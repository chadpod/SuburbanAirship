//
//  SuburbanAirshipViewController.m
//  SuburbanAirship
//
//  Created by Chad Podoski on 1/12/10.
//  Copyright Shacked Software 2010. All rights reserved.
//

#import "SuburbanAirshipViewController.h"
#import "SuburbanAirshipAppDelegate.h"

@implementation SuburbanAirshipViewController

@synthesize message;
@synthesize seconds;
@synthesize badge;
@synthesize soundFile;


#pragma mark - IBAction Methods
- (IBAction)send:(id)sender; {
	SuburbanAirshipAppDelegate *delegate = (SuburbanAirshipAppDelegate*)[UIApplication sharedApplication].delegate;
	
	NSNumber *badgeNum = nil;
	NSDate *date = nil;
	
	if (badge.text != nil && [badge.text length] != 0) {
		badgeNum = [NSNumber numberWithInteger:[badge.text integerValue]];
	}
	
	if (seconds.text != nil && [seconds.text length] != 0) {
		date = [NSDate dateWithTimeIntervalSinceNow:[seconds.text integerValue]];
	}
	
	[delegate pushMessage:message.text sound:soundFile.text badge:badgeNum date:date];
}

- (IBAction)clear:(id)sender; {
	message.text = nil;
	seconds.text = nil;
	badge = nil;
	soundFile = nil;
}

@end
