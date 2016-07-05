//
//  LCWeiboObject.m
//  LCShareKit
//
//  Created by lichao on 16/7/5.
//  Copyright © 2016年 bill. All rights reserved.
//

#import "LCWeiboObject.h"

#import "WeiboSDK.h"
#import "LCLoginInfo.h"

#define kRedirectURI    @"http://m.ifeng.com"
#define kWeiboStoreKey  @"kWeiboStoreKey"
#define kWeiboAPPId @"wb2639294266"
#define kWeiboSecret @"0746d8a294d7933100ce34aab3d50899"

@interface LCWeiboObject()<WeiboSDKDelegate,WBHttpRequestDelegate>

@end

@implementation LCWeiboObject

static LCWeiboObject *weiboObject = nil;

+ (LCWeiboObject *)weiboManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (weiboObject == nil) {
            weiboObject = [[LCWeiboObject alloc] init];
        }
    });
    return weiboObject;
}

+ (BOOL)handleOpenURL:(NSURL *)url {
    return [WeiboSDK handleOpenURL:url delegate:[self weiboManager]];
}

+ (BOOL)registerWeiboApp:(NSString *)wbAppId {
    return [WeiboSDK registerApp:wbAppId];
}

+ (BOOL)isInstalledWeibo {
    return [WeiboSDK isWeiboAppInstalled];
}

+ (void)logout {
    NSData  *data =  [[NSUserDefaults standardUserDefaults] objectForKey:kWeiboStoreKey];
    LCLoginInfo *loginInfo = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    //微博登出，取消授权
    [WeiboSDK logOutWithToken:loginInfo.token delegate:[self weiboManager] withTag:@"1"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kWeiboStoreKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - 登录退出
//微博登录
- (void)loginCompletion:(LoginHandler)handler {
    [LCWeiboObject weiboManager].loginHandler = handler;
    LCLoginInfo *info = (LCLoginInfo *)[self  getLoginInfo];
    NSLog(@"info:%@",info);
    if (info) {
        if ([info.expiationDate compare:[NSDate date]] != NSOrderedAscending) {
            [LCWeiboObject weiboManager].loginHandler(LCLoginResultHasLogined,@"已登录",nil);
        } else {
            [self refreshWeiboTokenWithRefreshToken:info.refreshToken completion:^(id responseObj, NSError *error) {
                [self parserJsonObj:responseObj];
            }];
        }
    } else {
        WBAuthorizeRequest *request = [WBAuthorizeRequest request];
        request.redirectURI = kRedirectURI;
        request.scope = @"all";
        [WeiboSDK sendRequest:request];
    }
}

- (LCLoginInfo *)getLoginInfo {
    LCLoginInfo *loginInfo = nil;
    
    NSData  *data =  [[NSUserDefaults standardUserDefaults] objectForKey:kWeiboStoreKey];
    loginInfo = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    return loginInfo;
}


//微博退出
- (void)logoutCompletion:(LogoutHandler)handler{
    [LCWeiboObject weiboManager].logoutHandler = handler;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kWeiboStoreKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [LCWeiboObject weiboManager].logoutHandler(LCLogoutResultSuccess,@"退出成功");
}

+ (void)removeAuthData {
    
    NSData  *data =  [[NSUserDefaults standardUserDefaults] objectForKey:kWeiboStoreKey];
    LCLoginInfo *loginInfo = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    loginInfo.uid = nil;
    loginInfo.token = nil;
    loginInfo.refreshToken = nil;
    loginInfo.expiationDate = nil;
    NSData *removeData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    [[NSUserDefaults standardUserDefaults] setObject:removeData forKey:kWeiboStoreKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}


- (void)getThirdUserInfoWithLoginInfo:(LCLoginInfo *)loginInfo completion:(void (^)(id, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"https://api.weibo.com/2/users/show.json?access_token=%@&uid=%@", loginInfo.token, loginInfo.uid];
    [self sendRequestUrl:requestUrl completion:completion];
}

- (void)refreshWeiboTokenWithRefreshToken:(NSString *)refreshToken completion:(void (^)(id responseObj, NSError *error))completion
{
    if (refreshToken == nil) {
        completion(nil, [NSError errorWithDomain:@"登录失败" code:999 userInfo:nil]);
        [LCWeiboObject weiboManager].loginHandler(LCLoginResultFailure,@"登录失败",nil);
        return;
    }
    NSString *requestUrl = [NSString stringWithFormat:@"https://api.weibo.com/oauth2/access_token?client_id=%@&client_secret=%@&grant_type=refresh_token&redirect_uri=%@&refresh_token=", kWeiboAPPId, kWeiboSecret,kRedirectURI];
    [self sendRequestUrl:requestUrl completion:completion];
}

- (void)parserJsonObj:(id)responseObj
{
    //获取鉴权结果
    //错误码返回值不一致，需做处理
    if ([responseObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)responseObj;
        NSString *code = dict[@"errcode"];
        if (code == nil) {
            LCLoginInfo *loginInfo = [[LCLoginInfo alloc] init];
            loginInfo.uid = dict[@"openid"];
            loginInfo.token = dict[@"access_token"];
            loginInfo.refreshToken = dict[@"refresh_token"];
            loginInfo.expiationDate = [NSDate dateWithTimeIntervalSinceNow:[dict[@"expires_in"] integerValue]];
            loginInfo.isWeiboSession = YES;
            loginInfo.isWeibo = YES;
            
            [self getThirdUserInfoWithLoginInfo:loginInfo completion:^(id responseObj, NSError *error) {
                //错误码返回值不一致，需做处理
                if (!error) {
                    if ([responseObj isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *dict = (NSDictionary *)responseObj;
                        NSString *code = dict[@"errcode"];
                        if (code == nil) {
                            loginInfo.nick = dict[@"nickname"];
                            loginInfo.headImageUrl = dict[@"headimgurl"];
                            loginInfo.unionID = dict[@"unionid"];
                            loginInfo.isWeiboSession = YES;
                            loginInfo.isWeibo = YES;
                            
                            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:loginInfo];
                            [[NSUserDefaults standardUserDefaults] setObject:data forKey:kWeiboStoreKey];
                            [LCWeiboObject weiboManager].loginHandler(LCLoginResultSuccess,@"登录成功",responseObj);
                        } else {
                            //登录失败
                            [LCWeiboObject weiboManager].loginHandler(LCLoginResultFailure,@"登录失败",nil);
                        }
                    } else {
                        //登录失败
                        [LCWeiboObject weiboManager].loginHandler(LCLoginResultFailure,@"登录失败",nil);
                    }
                } else {
                    //登录失败
                    [LCWeiboObject weiboManager].loginHandler(LCLoginResultFailure,@"登录失败",nil);
                }
            }];
        } else {
            //登录失败
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kWeiboStoreKey];
            [LCWeiboObject weiboManager].loginHandler(LCLoginResultFailure,@"登录失败",nil);
            
        }
    } else {
        //登录失败
        [LCWeiboObject weiboManager].loginHandler(LCLoginResultFailure,@"登录失败",nil);
    }
}


#pragma mark - 微博分享
//- (void)shareModel:(IFShareModel *)model completionBlock:(CompletionHandler)handler {
//    if (model.shareScene == ShareScene_Weibo){
//        if (IS_NONNULL_STRING(model.shareContent) && model.shareOriginalImgData == nil) {
//            [self shareWeiboMessageText:model.shareContent responseBlock:handler];
//            return;
//        }
//        
//        if (IS_NONNULL_STRING(model.shareContent) && model.shareOriginalImgData != nil) {
//            [self shareWeiboMessageText:model.shareContent image:model.shareOriginalImgData responseBlock:handler];
//            return;
//        }
//        
//        // 处理结果
//        [IFWeiboObject weiboManager].completionHandler = handler;
//        [IFWeiboObject weiboManager].completionHandler(IFShareResultInvalidParameter,@"分享参数不合法");
//    }
//    else {
//        // 处理结果
//        [IFWeiboObject weiboManager].completionHandler = handler;
//        [IFWeiboObject weiboManager].completionHandler(IFShareResultInvalidParameter,@"分享参数不合法");
//    }
//    
//}

- (void)shareWeiboMessageText:(NSString *)text responseBlock:(CompletionHandler)handler {
    WBMessageObject *message = [WBMessageObject message];
    message.text = text;
    // 处理结果
    [LCWeiboObject weiboManager].completionHandler = handler;
    // 发送消息
    [self sendWeiboMessage:message responseBlock:handler];
}

- (void)shareWeiboMessageText:(NSString *)text image:(NSData *)image responseBlock:(CompletionHandler)handler {
    WBMessageObject *message = [WBMessageObject message];
    // 设置文字
    if (text && text.length > 0) {
        message.text = text;
    }
    // 设置图片
    if (image) {
        WBImageObject *shareImage = [WBImageObject object];
        shareImage.imageData = image;
        message.imageObject = shareImage;
    }
    // 处理结果
    [LCWeiboObject weiboManager].completionHandler = handler;
    // 发送消息
    [self sendWeiboMessage:message responseBlock:handler];
}

- (void)shareWeiboMessageText:(NSString *)text mediaId:(NSString *)mediaId mediaTitle:(NSString *)title mediaDescription:(NSString *)description thumbImage:(UIImage *)thumbImage mediaURL:(NSString *)url responseBlock:(CompletionHandler)handler {
    
    WBMessageObject *message = [WBMessageObject message];
    // 设置文字
    if (text && text.length > 0) {
        message.text = text;
    }
    // 媒体信息
    WBWebpageObject *webpage = [WBWebpageObject object];
    webpage.objectID = mediaId;
    webpage.title = title;
    webpage.description = description;
    
    
    webpage.thumbnailData = UIImageJPEGRepresentation(thumbImage, 1.0);
    webpage.webpageUrl = url;
    message.mediaObject = webpage;
    
    // 处理结果
    [LCWeiboObject weiboManager].completionHandler = handler;
    [self sendWeiboMessage:message responseBlock:handler];
}

- (void)sendWeiboMessage:(WBMessageObject *)message responseBlock:(CompletionHandler)handler {
    WBAuthorizeRequest *authRequest = [WBAuthorizeRequest request];
    authRequest.scope = @"all";
    
    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:message authInfo:authRequest access_token:nil];
    request.userInfo = @{@"ShareMessageFrom": @"IFWeiboObject",
                         @"Other_Info_1": [NSNumber numberWithInt:123],
                         @"Other_Info_2": @[@"obj1", @"obj2"],
                         @"Other_Info_3": @{@"key1": @"obj1", @"key2": @"obj2"}};
    request.shouldOpenWeiboAppInstallPageIfNotInstalled = NO; // 不显示未安装提示
    
    [LCWeiboObject weiboManager].completionHandler = handler;
    [WeiboSDK sendRequest:request];
    
}

#pragma mark - WeiboSDKDelegate
/**
 收到一个来自微博客户端程序的请求
 
 收到微博的请求后，第三方应用应该按照请求类型进行处理，处理完后必须通过 [WeiboSDK sendResponse:] 将结果回传给微博
 @param request 具体的请求对象
 */
- (void)didReceiveWeiboRequest:(WBBaseRequest *)request {
    
}

/**
 收到一个来自微博客户端程序的响应
 
 收到微博的响应后，第三方应用可以通过响应类型、响应的数据和 WBBaseResponse.userInfo 中的数据完成自己的功能
 @param response 具体的响应对象
 */
- (void)didReceiveWeiboResponse:(WBBaseResponse *)response {
    if ([response isKindOfClass:WBAuthorizeResponse.class]) {
        WBAuthorizeResponse *resp = (WBAuthorizeResponse *)response;
        LCLoginInfo *loginInfo = [[LCLoginInfo alloc] init];
        loginInfo.uid = resp.userID;
        loginInfo.token = resp.accessToken;
        loginInfo.expiationDate = resp.expirationDate;
        
        if (resp.accessToken) {
            [self getThirdUserInfoWithLoginInfo:loginInfo completion:^(id responseObj, NSError *error) {
                if (!error) {
                    if ([responseObj isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *dict = (NSDictionary *)responseObj;
                        NSLog(@"dict:%@",dict);
                        NSString *code = dict[@"error_code"];
                        if (code == nil) {
                            loginInfo.nick = dict[@"name"];
                            loginInfo.headImageUrl = dict[@"profile_image_url"];
                            loginInfo.isWeiboSession = YES;
                            loginInfo.isWeibo = YES;
                            
                            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:loginInfo];
                            [[NSUserDefaults standardUserDefaults] setObject:data forKey:kWeiboStoreKey];
                            [LCWeiboObject weiboManager].loginHandler(LCLoginResultSuccess,@"登录成功",responseObj);
                            
                        } else {
                            [LCWeiboObject weiboManager].loginHandler(LCLoginResultFailure,@"登录失败",nil);
                        }
                    } else {
                        [LCWeiboObject weiboManager].loginHandler(LCLoginResultFailure,@"登录失败",nil);
                    }
                } else {
                    [LCWeiboObject weiboManager].loginHandler(LCLoginResultFailure,@"登录失败",nil);
                }
            }];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kWeiboStoreKey];
            //[IFWeiboObject weiboManager].loginHandler(IFLoginResultFailure,@"登录失败",nil);
        }
    }
    
    
    if ([response isKindOfClass:WBSendMessageToWeiboResponse.class]) {
        if (self.completionHandler != NULL) {
            switch (response.statusCode) {
                case WeiboSDKResponseStatusCodeSuccess: // 发送成功
                    self.completionHandler(LCShareResultSuccess,@"分享成功");
                    break;
                    
                case WeiboSDKResponseStatusCodeUserCancel: // 用户取消发送
                    self.completionHandler(LCShareResultCancel,@"取消分享");
                    break;
                    
                default: // 失败
                    self.completionHandler(LCShareResultFailed,@"分享失败");
                    break;
            }
        }
    }
}


#pragma mark - setter方法
- (void)setRespResultBlock:(CompletionHandler)completionHandler {
    if (_completionHandler != completionHandler) {
        _completionHandler = nil;
        _completionHandler = [completionHandler copy];
    }
}

- (void)setLoginHandler:(LoginHandler)loginHandler{
    if (_loginHandler != loginHandler){
        _loginHandler = nil;
        _loginHandler = [loginHandler copy];
    }
}

- (void)setLogoutHandler:(LogoutHandler)logoutHandler{
    if (_logoutHandler != logoutHandler){
        _logoutHandler = nil;
        _logoutHandler = [logoutHandler copy];
    }
}

#pragma mark - NSURLConnection
- (void)sendRequestUrl:(NSString *)url completion:(void (^)(id responseObj, NSError *error))completion
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15.];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (data) {
            id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            completion(obj, connectionError);
        } else {
            completion(nil, connectionError);
        }
    }];
}



@end
