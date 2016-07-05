//
//  LCQQObject.h
//  LCShareKit
//
//  Created by lichao on 16/7/5.
//  Copyright © 2016年 bill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCShareDefine.h"
#import "LCPlatformObject.h"
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/TencentOAuth.h>

typedef NS_ENUM(NSUInteger, QQScene) {
    QQScene_QQFriend,  //QQ好友
    QQScene_QZone,     //QQ空间
};

@interface LCQQObject : LCPlatformObject

@property (nonatomic, copy) CompletionHandler completionHandler;
@property (nonatomic, copy) LoginHandler loginHandler;
@property (nonatomic, copy) LogoutHandler logoutHandler;

@property (nonatomic, strong) TencentOAuth *OAuth;

+ (LCQQObject *)QQManager;
+ (BOOL)handleOpenURL:(NSURL *)url;

@end
