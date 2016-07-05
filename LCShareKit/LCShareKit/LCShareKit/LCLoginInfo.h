//
//  LCLoginInfo.h
//  LCShareKit
//
//  Created by lichao on 16/7/5.
//  Copyright © 2016年 bill. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LCLoginInfo : NSObject<NSCoding>

@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *refreshToken;
@property (nonatomic, copy) NSDate *expiationDate;

@property (nonatomic, copy) NSString *nick;
@property (nonatomic, copy) NSString *headImageUrl;
@property (nonatomic, copy) NSString *unionID;
@property (nonatomic, copy) NSString *province;
@property (nonatomic, strong) NSNumber *sex;

@property (nonatomic, assign) BOOL isWeibo;
@property (nonatomic, assign) BOOL isWeiboSession;

@end
