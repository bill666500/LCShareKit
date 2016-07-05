//
//  LCWechatObject.h
//  LCShareKit
//
//  Created by lichao on 16/7/5.
//  Copyright © 2016年 bill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCShareDefine.h"
#import "LCPlatformObject.h"
#import "WXApi.h"

typedef NS_ENUM(NSUInteger, WechatScene) {
    WechatScene_Session,  //微信好友
    WechatScene_Timeline, //微信朋友圈
};

@interface LCWechatObject : LCPlatformObject

@property (nonatomic, copy) CompletionHandler completionHandler;
@property (nonatomic, copy) LoginHandler loginHandler;
@property (nonatomic, copy) LogoutHandler logoutHandler;

+ (LCWechatObject *)wechatManager;

+ (BOOL)registerWechatApp:(NSString *)wxAppId;
+ (BOOL)handleOpenURL:(NSURL *)url;

@end
