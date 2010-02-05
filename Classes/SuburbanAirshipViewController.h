//
//  SuburbanAirshipViewController.h
//  SuburbanAirship
//
//  Created by Chad Podoski on 1/12/10.
//  Copyright Shacked Software 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SuburbanAirshipViewController : UIViewController {

	IBOutlet UITextField *message;
	IBOutlet UITextField *seconds;
	IBOutlet UITextField *badge;
	IBOutlet UITextField *soundFile;
	
}

@property (retain, nonatomic) IBOutlet UITextField *message;
@property (retain, nonatomic) IBOutlet UITextField *seconds;
@property (retain, nonatomic) IBOutlet UITextField *badge;
@property (retain, nonatomic) IBOutlet UITextField *soundFile;

- (IBAction)send:(id)sender; 
- (IBAction)clear:(id)sender;

@end

