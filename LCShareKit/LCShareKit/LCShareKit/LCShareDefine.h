//
//  LCShareDefine.h
//  LCShareKit
//
//  Created by lichao on 16/7/5.
//  Copyright © 2016年 bill. All rights reserved.
//

#ifndef LCShareDefine_h
#define LCShareDefine_h

typedef NS_ENUM(NSUInteger, LCShareResult) {
    LCShareResultSuccess, // 分享成功
    LCShareResultCancel, // 取消分享
    LCShareResultFailed, // 分享失败
    LCShareResultInvalidParameter, //分享参数不合法
};

typedef void(^CompletionHandler)(LCShareResult result, NSString *message);


typedef NS_ENUM(NSUInteger, LCLoginResult){
    LCLoginResultSuccess, //登录成功
    LCLoginResultFailure, //登录失败
    LCLoginResultHasLogined, //已登录
};

typedef void(^LoginHandler)(LCLoginResult result, NSString *message,id responseObj);

typedef NS_ENUM(NSUInteger,LCLogoutResult){
    LCLogoutResultSuccess, //退出成功
    LCLogoutResultFailure, //退出失败
};

typedef void(^LogoutHandler)(LCLogoutResult result, NSString *message);


#endif /* LCShareDefine_h */
