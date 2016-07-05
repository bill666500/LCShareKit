//
//  LCWeiboObject.h
//  LCShareKit
//
//  Created by lichao on 16/7/5.
//  Copyright © 2016年 bill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCShareDefine.h"
#import "LCPlatformObject.h"

@interface LCWeiboObject : LCPlatformObject

@property (nonatomic, copy) CompletionHandler completionHandler;
@property (nonatomic, copy) LoginHandler loginHandler;
@property (nonatomic, copy) LogoutHandler logoutHandler;

+ (LCWeiboObject *)weiboManager;

+ (BOOL)handleOpenURL:(NSURL *)url;

+ (BOOL)registerWeiboApp:(NSString *)wbAppId;

+ (void)removeAuthData;

+ (void)logout;

+ (BOOL)isInstalledWeibo;

@end
