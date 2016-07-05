//
//  LCShareManager.m
//  LCShareKit
//
//  Created by lichao on 16/7/5.
//  Copyright © 2016年 bill. All rights reserved.
//

#import "LCShareManager.h"

#define WXAppKey @""
#define TencentAppId @""
#define SinaWeiboKey @""

#define kAppKeySina @""
#define kAppSecretSina @""
#define kAppRedirectURISina @""


@implementation LCShareManager

static LCShareManager *shareManager = nil;

+ (LCShareManager *)defaultConfig {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (shareManager == nil) {
            shareManager = [[LCShareManager alloc] init];
        }
    });
    return shareManager;
}

+ (id)initPlatformManager:(LCSharePlatformType)type {
    id platformTypeManager = nil;
    switch (type) {
        case LCSharePlatformWechat:
            platformTypeManager = [[LCWechatObject alloc] init];
            break;
        case LCSharePlatformQQ:
            platformTypeManager = [[LCQQObject alloc] init];
            break;
        case LCSharePlatformWeibo:
            platformTypeManager = [[LCWeiboObject alloc] init];
            break;
        default:
            break;
    }
    return platformTypeManager;
}

// 微信注册
+ (BOOL)registerWechatApp {
    return [LCWechatObject registerWechatApp:WXAppKey];
}

// 微博注册
+ (BOOL)registerWeiboApp {
    return [LCWeiboObject registerWeiboApp:SinaWeiboKey];
}

+ (BOOL)handleOpenURL:(NSURL *)url {
    if ([url.description hasPrefix:WXAppKey]) {
        // 从微信打开
        [LCWechatObject handleOpenURL:url];
    } else if ([url.description hasPrefix:[NSString stringWithFormat:@"tencent%@",TencentAppId]]) {
        // 从腾讯QQ打开
        [LCQQObject handleOpenURL:url];
    } else if ([url.description hasPrefix:[NSString stringWithFormat:@"wb%@",SinaWeiboKey]]) {
        // 从新浪微博打开
        [LCWeiboObject handleOpenURL:url];
    }
    return YES;
}

- (void)login:(LCPlatformType)type completion:(LoginHandler)handler {
    if (type == LCPlatformWechat){
        LCWechatObject *wechat = [[LCWechatObject alloc] init];
        [wechat loginCompletion:handler];
    } else if (type == LCPlatformWeibo){
        LCWeiboObject *weibo = [[LCWeiboObject alloc] init];
        [weibo loginCompletion:handler];
    } else if (type == LCPlatformQQ){
        LCQQObject *qq = [[LCQQObject alloc] init];
        [qq loginCompletion:handler];
    }
}

- (void)logout:(LCPlatformType)type completion:(LogoutHandler)handler {
    if (type == LCPlatformWechat){
        LCWechatObject *wechat = [[LCWechatObject alloc] init];
        [wechat logoutCompletion:handler];
    } else if (type == LCPlatformWeibo){
        LCWeiboObject *weibo = [[LCWeiboObject alloc] init];
        [weibo logoutCompletion:handler];
    } else if (type == LCPlatformQQ){
        LCQQObject *qq = [[LCQQObject alloc] init];
        [qq logoutCompletion:handler];
    }
    
}



@end
