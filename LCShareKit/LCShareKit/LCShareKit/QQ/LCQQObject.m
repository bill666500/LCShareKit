//
//  LCQQObject.m
//  LCShareKit
//
//  Created by lichao on 16/7/5.
//  Copyright © 2016年 bill. All rights reserved.
//

#import "LCQQObject.h"
#define TencentAppId @"101053114"
#define kQQAuthDic @"QQAuthDic"
#define kQQAccessTokenKey @"QQAccessTokenKey"
#define kQQExpirationDateKey @"QQExpirationDateKey"
#define kQQUserIDKey @"QQUserIDKey"

@interface LCQQObject() <QQApiInterfaceDelegate,TencentSessionDelegate>

@end

@implementation LCQQObject

static LCQQObject *qqObject = nil;

+ (LCQQObject *)QQManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (qqObject == nil) {
            qqObject = [[LCQQObject alloc] init];
        }
    });
    return qqObject;
    
}

+ (BOOL)handleOpenURL:(NSURL *)url {
    if ([url.description hasPrefix:[NSString stringWithFormat:@"tencent%@://qzapp/",TencentAppId]]){
        return [TencentOAuth HandleOpenURL:url];
    } else {
        return [QQApiInterface handleOpenURL:url delegate:[self QQManager]];
    }
    
    return [TencentOAuth HandleOpenURL:url];
}


#pragma  mark - QQ登录退出
- (TencentOAuth *)OAuth
{
    if (!_OAuth) {
        _OAuth = [[TencentOAuth alloc] initWithAppId:TencentAppId andDelegate:self];
    }
    return _OAuth;
}


//QQ登录
- (void)loginCompletion:(LoginHandler)handler {
    [LCQQObject QQManager].loginHandler = handler;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *qqInfo = [defaults objectForKey:kQQAuthDic];
    if ([qqInfo objectForKey:kQQAccessTokenKey] &&
        [qqInfo objectForKey:kQQExpirationDateKey] &&
        [qqInfo objectForKey:kQQUserIDKey]){
        
        [LCQQObject QQManager].OAuth.accessToken = [qqInfo objectForKey:kQQAccessTokenKey];
        [LCQQObject QQManager].OAuth.expirationDate = [qqInfo objectForKey:kQQExpirationDateKey];
        [LCQQObject QQManager].OAuth.openId = [qqInfo objectForKey:kQQUserIDKey];
    }
    
    NSArray *permissions = [NSArray arrayWithObjects:@"get_user_info",@"get_simple_userinfo", @"add_t", nil];
    [[LCQQObject QQManager].OAuth authorize:permissions inSafari:NO];
}
//QQ退出
- (void)logoutCompletion:(LogoutHandler)handler {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kQQAuthDic];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

#pragma  mark - QQ分享
//- (void)shareModel:(IFShareModel *)model completionBlock:(CompletionHandler)handler {
//    if (model.shareScene == ShareScene_QQFriend) {
//        [self shareScene:QQScene_QQFriend Model:model completionBlock:handler];
//    } else if (model.shareScene == ShareScene_QZone) {
//        [self shareScene:QQScene_QZone Model:model completionBlock:handler];
//    } else {
//        // 处理结果
//        [IFQQObject QQManager].completionHandler = handler;
//        [IFQQObject QQManager].completionHandler(IFShareResultInvalidParameter,@"分享参数不合法");
//    }
//}
//
//- (void)shareScene:(QQScene)scene Model:(IFShareModel *)model completionBlock:(CompletionHandler)handler {
//    
//    if (IS_NONNULL_STRING(model.shareTitle) && IS_NONNULL_STRING(model.shareDesc) && IS_NONNULL_STRING(model.shareUrl)&& model.shareThumbImgData != nil) {
//        [self shareWithCommon:scene title:model.shareTitle description:model.shareDesc image:model.shareThumbImgData contentOfUrl:model.shareUrl completionBlock:handler];
//        return;
//    }
//    
//    if (IS_NONNULL_STRING(model.shareTitle) && IS_NONNULL_STRING(model.shareDesc) && IS_NONNULL_STRING(model.shareUrl)&& IS_NONNULL_STRING(model.shareThumbImgUrl)) {
//        [self shareWithCommon:scene title:model.shareTitle description:model.shareDesc imageUrl:model.shareThumbImgUrl contentOfUrl:model.shareUrl completionBlock:handler];
//        return;
//    }
//    
//    if (model.shareOriginalImgData != nil && model.shareThumbImgData != nil && IS_NONNULL_STRING(model.shareTitle) && IS_NONNULL_STRING(model.shareDesc)){
//        [self shareWithPicture:scene image:model.shareOriginalImgData thumbImage:model.shareThumbImgData title:model.shareTitle description:model.shareDesc responseBlock:handler];
//        return;
//    }
//    // 处理结果
//    [IFQQObject QQManager].completionHandler = handler;
//    [IFQQObject QQManager].completionHandler(IFShareResultInvalidParameter,@"分享参数不合法");
//    
//}

/**
 *  分享普通文章页面
 *
 *  @param scene        QQ分享场景
 *  @param title        QQ分享标题
 *  @param description  QQ分享描述
 *  @param image        QQ分享图片
 *  @param contentOfUrl QQ分享文章
 */
- (void)shareWithCommon:(QQScene)scene title:(NSString *)title description:(NSString *)desc imageUrl:(NSString *)imgUrl contentOfUrl:(NSString *)pageUrl completionBlock:(CompletionHandler)handler{
    
    
    QQApiNewsObject *newsObj = [QQApiNewsObject
                                objectWithURL:[NSURL URLWithString:pageUrl] title:title description:desc previewImageURL:[NSURL URLWithString:imgUrl]];
    
    
    SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:newsObj];
    [self sendTencentMessage:req Scene:scene responseBlock:handler];
}

/**
 *  分享普通文章页面
 *
 *  @param scene        QQ分享场景
 *  @param title        QQ分享标题
 *  @param description  QQ分享描述
 *  @param image        QQ分享图片
 *  @param contentOfUrl QQ分享文章
 */
- (void)shareWithCommon:(QQScene)scene title:(NSString *)title description:(NSString *)desc image:(NSData *)imgData contentOfUrl:(NSString *)pageUrl completionBlock:(CompletionHandler)handler{
    
    
    QQApiNewsObject *newsObj = [QQApiNewsObject
                                objectWithURL:[NSURL URLWithString:pageUrl]
                                title:title
                                description:desc
                                previewImageData:imgData];
    
    
    SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:newsObj];
    [self sendTencentMessage:req Scene:scene responseBlock:handler];
}

/**
 *  分享图片
 *
 *  @param sharedImage 分享的图片
 *  @param thumbImage  预览图片
 *  @param title       标题
 *  @param description 描述
 */
- (void)shareWithPicture:(QQScene)scene image:(NSData *)sharedImage thumbImage:(NSData *)thumbImage title:(NSString *)title description:(NSString *)description responseBlock:(CompletionHandler)handler{
    
    QQApiImageObject* img = [QQApiImageObject objectWithData:sharedImage previewImageData:thumbImage title:title description:description];
    SendMessageToQQReq* req = [SendMessageToQQReq reqWithContent:img];
    
    [self sendTencentMessage:req Scene:scene responseBlock:handler];
    
}

- (void)sendTencentMessage:(QQBaseReq *)req Scene:(QQScene)scene responseBlock:(CompletionHandler)handler {
    [LCQQObject QQManager].completionHandler = handler;
    _OAuth = [[TencentOAuth alloc] initWithAppId:TencentAppId  andDelegate:self];
    
    QQApiSendResultCode sent;
    if (scene == QQScene_QQFriend){
        sent = [QQApiInterface sendReq:req];
    } else {
        sent = [QQApiInterface SendReqToQZone:req];
    }
    
    [self handleSendResult:sent];
}

//分类处理
-  (void)handleSendResult:(QQApiSendResultCode)sendResult
{
    NSLog(@"sendResult:%d",sendResult);
    switch (sendResult)
    {
        case EQQAPIAPPNOTREGISTED:
        {
            [LCQQObject QQManager].completionHandler(LCShareResultFailed,@"App未注册");
            break;
        }
        case EQQAPIMESSAGECONTENTINVALID:
        case EQQAPIMESSAGECONTENTNULL:
        case EQQAPIMESSAGETYPEINVALID:
        {
            [LCQQObject QQManager].completionHandler(LCShareResultFailed,@"发送参数错误");
            break;
        }
        case EQQAPIQQNOTINSTALLED:
        {
            [LCQQObject QQManager].completionHandler(LCShareResultFailed,@"未安装手Q");
            break;
        }
        case EQQAPIQQNOTSUPPORTAPI:
        {
            [LCQQObject QQManager].completionHandler(LCShareResultFailed,@"API接口不支持");
            break;
        }
        case EQQAPISENDFAILD:
        {
            [LCQQObject QQManager].completionHandler(LCShareResultFailed,@"发送失败");
            break;
        }
        default:
        {
            break;
        }
    }
}

#pragma mark - QQApiInterfaceDelegate
/**
 处理来至QQ的请求
 */
- (void)onReq:(QQBaseReq *)req {
    
}

/**
 处理来至QQ的响应
 */
- (void)onResp:(id)resp {
    if ([resp isMemberOfClass:[SendMessageToQQResp class]]){
        if (self.completionHandler != NULL) {
            QQBaseResp *response = (QQBaseResp *)resp;
            if([response.result isEqualToString:@"0"]) { // 发送成功
                self.completionHandler(LCShareResultSuccess,@"分享成功");
            } else if ([response.result isEqualToString:@"-4"]) { // 用户取消发送
                self.completionHandler(LCShareResultCancel,@"取消分享");
            } else {// 发送失败
                self.completionHandler(LCShareResultFailed,@"分享失败");
            }
        }
    }
}
/**
 处理QQ在线状态的回调
 */
- (void)isOnlineResponse:(NSDictionary *)response{
    
}


#pragma mark - TencentSessionDelegate
/**
 * 登录成功后的回调
 */
- (void)tencentDidLogin{
    if (_OAuth.accessToken && 0 != [_OAuth.accessToken length]) {
        [self storeAuthData];
        [_OAuth getUserInfo];
    }
    else {
        [LCQQObject QQManager].loginHandler(LCLoginResultFailure,@"登录失败",nil);
    }
}

/**
 * 登录失败后的回调
 * param cancelled 代表用户是否主动退出登录
 */
- (void)tencentDidNotLogin:(BOOL)cancelled{
    [LCQQObject QQManager].loginHandler(LCLoginResultFailure,@"登录失败",nil);
}

/**
 * 登录时网络有问题的回调
 */
- (void)tencentDidNotNetWork{
    [LCQQObject QQManager].loginHandler(LCLoginResultFailure,@"登录失败",nil);
}

- (void)getUserInfoResponse:(APIResponse*) response{
    NSLog(@"response:%@",response.jsonResponse);
    [LCQQObject QQManager].loginHandler(LCLoginResultSuccess,@"登录成功",response.jsonResponse);
}

#pragma mark - 管理存储
- (void)storeAuthData{
    NSDictionary *authDic = [NSDictionary dictionaryWithObjectsAndKeys:
                             _OAuth.accessToken, kQQAccessTokenKey,
                             _OAuth.expirationDate , kQQExpirationDateKey,
                             _OAuth.openId, kQQUserIDKey,nil];
    [[NSUserDefaults standardUserDefaults] setObject:authDic forKey:kQQAuthDic];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)removeAuthData{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kQQAuthDic];
    [[NSUserDefaults standardUserDefaults] synchronize];
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



@end
