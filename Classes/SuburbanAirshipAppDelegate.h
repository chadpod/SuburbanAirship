//
//  SuburbanAirshipAppDelegate.h
//  SuburbanAirship
//
//  Created by Chad Podoski on 1/12/10.
//  Copyright Shacked Software 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SuburbanAirship.h"

@class SuburbanAirshipViewController;

@interface SuburbanAirshipAppDelegate : NSObject <UIApplicationDelegate, SuburbanAirshipDelegate> {
    UIWindow *window;
    SuburbanAirshipViewController *viewController;
	
	SuburbanAirship *suburbanAirship;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet SuburbanAirshipViewController *viewController;
@property (nonatomic, retain) SuburbanAirship *suburbanAirship;

- (void)pushMessage:(NSString *)message sound:(NSString *)sound badge:(NSNumber *)badge date:(NSDate *)date;
@end

