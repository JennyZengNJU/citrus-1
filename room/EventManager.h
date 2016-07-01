//
//  EventManager.h
//  room
//
//  Created by lcm_ios on 16/6/24.
//  Copyright © 2016年 lcm_ios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface EventManager : NSObject
@property (strong, nonatomic) NSString *resultText;
@property (strong, nonatomic) NSMutableArray *resultArray;
@property (weak, nonatomic) IBOutlet UITextField *roomName;
@property (nonatomic ,strong) NSArray *attender;
@property (nonatomic ,strong) NSArray *time;

#define DataAvailableNotification @"DataAvailableNotification"
#define DataAvailableContext @"Context"

- (NSArray *)fetchEvents;
@end
