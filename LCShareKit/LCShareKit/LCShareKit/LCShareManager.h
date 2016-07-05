//
//  LCShareManager.h
//  LCShareKit
//
//  Created by lichao on 16/7/5.
//  Copyright © 2016年 bill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCShareDefine.h"
#import "LCWeiboObject.h"
#import "LCWechatObject.h"
#import "LCQQObject.h"

typedef NS_ENUM(NSUInteger, LCSharePlatformType) {
    LCSharePlatformWechat,  //微信
    LCSharePlatformQQ,      //QQ
    LCSharePlatformWeibo,   //新浪微博
    IFSharePlatformAliPay,  //支付宝
    IFSharePlatformFetion,  //飞信
};

typedef NS_ENUM(NSUInteger, LCPlatformType){
    LCPlatformWechat,
    LCPlatformQQ,
    LCPlatformWeibo,
    LCPlatformAliPay,
    LCPlatformFetion,
};

@interface LCShareManager : NSObject

@property (nonatomic, copy) LoginHandler loginHanlder;
@property (nonatomic, copy) LogoutHandler logoutHandler;

+ (LCShareManager *)defaultConfig;

+ (BOOL)handleOpenURL:(NSURL *)url;

// 微信注册
+ (BOOL)registerWechatApp;

// 微博注册
+ (BOOL)registerWeiboApp;

// 支付宝注册
+ (BOOL)registerAliPayApp;

+ (BOOL)registerApp;

@end
