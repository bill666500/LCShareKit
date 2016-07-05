//
//  LCWechatObject.m
//  LCShareKit
//
//  Created by lichao on 16/7/5.
//  Copyright © 2016年 bill. All rights reserved.
//

#import "LCWechatObject.h"
#import "LCLoginInfo.h"

#define kWechatStoreKey @"kWechatStoreKey"
#define WeixinAPPId @""
#define WeixinSecret @""

#define GlobleHeight [[UIScreen mainScreen] bounds].size.height


@interface LCWechatObject()<WXApiDelegate>

@end

@implementation LCWechatObject

static LCWechatObject *wechatObject = nil;

+ (LCWechatObject *)wechatManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (wechatObject == nil) {
            wechatObject = [[LCWechatObject alloc] init];
        }
    });
    return wechatObject;
}

+ (BOOL)registerWechatApp:(NSString *)wxAppId {
    return [WXApi registerApp:wxAppId];
}

+ (BOOL)handleOpenURL:(NSURL *)url {
    return [WXApi handleOpenURL:url delegate:[self wechatManager]];
}

#pragma mark -微信登录

//微信登录
- (void)loginCompletion:(LoginHandler)handler {
    [LCWechatObject wechatManager].loginHandler = handler;
    
    LCLoginInfo *info = (LCLoginInfo *)[self  getLoginInfo];
    if (info) {
        if ([info.expiationDate compare:[NSDate date]] != NSOrderedAscending) {
            [LCWechatObject wechatManager].loginHandler(LCLoginResultHasLogined,@"已登录",nil);
        } else {
            [self refreshWeChatTokenWithRefreshToken:info.refreshToken completion:^(id responseObj, NSError *error) {
                [self parserJsonObj:responseObj];
            }];
        }
    } else {
        SendAuthReq* req = [[SendAuthReq alloc] init];
        req.scope = @"snsapi_userinfo";
        req.state = @"";
        [WXApi sendReq:req];
    }
    
}
//微信退出
- (void)logoutCompletion:(LogoutHandler)handler {
    [LCWechatObject wechatManager].logoutHandler = handler;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kWechatStoreKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [LCWechatObject wechatManager].logoutHandler(LCLogoutResultSuccess,@"退出成功");
}

- (void)getWeChatAccessTokenWithCode:(NSString *)code completion:(void (^)(id responseObj, NSError *error))completion
{
    if (code == nil) {
        completion(nil, [NSError errorWithDomain:@"登录失败" code:999 userInfo:nil]);
        [LCWechatObject wechatManager].loginHandler(LCLoginResultFailure,@"登录失败",nil);
        return;
    }
    NSString *requestUrl = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=authorization_code", WeixinAPPId, WeixinSecret, code];
    
    [self sendRequestUrl:requestUrl completion:completion];
}

- (void)refreshWeChatTokenWithRefreshToken:(NSString *)refreshToken completion:(void (^)(id responseObj, NSError *error))completion
{
    if (refreshToken == nil) {
        completion(nil, [NSError errorWithDomain:@"登录失败" code:999 userInfo:nil]);
        [LCWechatObject wechatManager].loginHandler(LCLoginResultFailure,@"登录失败",nil);
        return;
    }
    NSString *requestUrl = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/refresh_token?appid=%@&grant_type=refresh_token&refresh_token=%@", WeixinAPPId, refreshToken];
    [self sendRequestUrl:requestUrl completion:completion];
}

- (void)getThirdUserInfoWithLoginInfo:(LCLoginInfo *)loginInfo completion:(void (^)(id, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/userinfo?access_token=%@&openid=%@", loginInfo.token, loginInfo.uid];
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
                            loginInfo.province = dict[@"province"];
                            loginInfo.sex = [NSNumber numberWithInteger:[dict[@"sex"] integerValue]];
                            
                            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:loginInfo];
                            [[NSUserDefaults standardUserDefaults] setObject:data forKey:kWechatStoreKey];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                            [LCWechatObject wechatManager].loginHandler(LCLoginResultSuccess,@"登录成功",responseObj);
                            
                        } else {
                            //登录失败
                            [LCWechatObject wechatManager].loginHandler(LCLoginResultFailure,@"登录失败",nil);
                        }
                    } else {
                        //登录失败
                        [LCWechatObject wechatManager].loginHandler(LCLoginResultFailure,@"登录失败",nil);
                    }
                } else {
                    //登录失败
                    [LCWechatObject wechatManager].loginHandler(LCLoginResultFailure,@"登录失败",nil);
                }
            }];
        } else {
            //登录失败
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kWechatStoreKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [LCWechatObject wechatManager].loginHandler(LCLoginResultFailure,@"登录失败",nil);
        }
    } else {
        [LCWechatObject wechatManager].loginHandler(LCLoginResultFailure,@"登录失败",nil);
    }
}

- (LCLoginInfo *)getLoginInfo{
    LCLoginInfo *loginInfo = nil;
    
    NSData  *data =  [[NSUserDefaults standardUserDefaults] objectForKey:kWechatStoreKey];
    loginInfo = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    return loginInfo;
}

#pragma mark - 微信分享
////微信分享
//- (void)shareModel:(ShareModel *)model completionBlock:(CompletionHandler)handler {
//    DDLogInfo(@"model.shareTitle:%@ model.shareUrl:%@",model.shareTitle,model.shareUrl);
//    if (model.shareScene == ShareScene_Session) {
//        [self shareScene:WechatScene_Session Model:model completionBlock:handler];
//    } else if (model.shareScene == ShareScene_Timeline) {
//        [self shareScene:WechatScene_Timeline Model:model completionBlock:handler];
//    } else {
//        // 处理结果
//        [IFWechatObject wechatManager].completionHandler = handler;
//        [IFWechatObject wechatManager].completionHandler(IFShareResultInvalidParameter,@"分享参数不合法");
//        DDLogError(@"分享参数不合法");
//    }
//    
//}
//
//- (void)shareScene:(WechatScene)scene Model:(IFShareModel *)model completionBlock:(CompletionHandler)handler {
//    
//    if (IS_NONNULL_STRING(model.shareTitle) &&  IS_NONNULL_STRING(model.shareDesc) && IS_NONNULL_STRING(model.shareUrl) && model.shareThumbImg != nil){
//        [self shareWithCommon:scene title:model.shareTitle description:model.shareDesc image:model.shareThumbImg contentOfUrl:model.shareUrl completionBlock:handler];
//        return;
//    }
//    
//    if (model.shareOriginalImg != nil){
//        [self sharewithPicture:scene OriginImage:model.shareOriginalImg  completionBlock:handler];
//        return;
//    }
//    
//    if (model.shareOriginalImgData != nil){
//        [self sharewithPicture:scene OriginImageData:model.shareOriginalImgData  completionBlock:handler];
//        return;
//    } else {
//        // 处理结果
//        [IFWechatObject wechatManager].completionHandler = handler;
//        [IFWechatObject wechatManager].completionHandler(IFShareResultInvalidParameter,@"分享参数不合法");
//        DDLogError(@"分享参数不合法");
//    }
//    
//}

/**
 *  分享普通文章页面
 *
 *  @param scene        微信分享场景
 *  @param title        微信分享标题
 *  @param description  微信分享描述
 *  @param image        微信分享图片
 *  @param contentOfUrl 微信分享文章
 */
- (void)shareWithCommon:(WechatScene)scene title:(NSString *)title description:(NSString *)desc image:(UIImage *)img contentOfUrl:(NSString *)pageUrl  completionBlock:(CompletionHandler)handler {
    
    title=[title copy];
    desc=[desc copy];
    img=[img copy];
    pageUrl=[pageUrl copy];

    WXMediaMessage *message = [WXMediaMessage message];
    
    UIImage *thumbImage = img;
    CGSize thumbSize = thumbImage.size;
    message.title = title;
    if(desc.length>80){
        desc=[desc substringWithRange:NSMakeRange(0, 80)];
    }
    
    message.description = desc;
    
    NSData *thumbData = UIImageJPEGRepresentation(thumbImage, 0.0);
    while (thumbData.length > 32 * 1024) {  //不能超过32K
        thumbSize = CGSizeMake(thumbSize.width / 2.0, thumbSize.height / 2.0);
        thumbImage = [self thumbImageWithImage:thumbImage limitSize:CGSizeMake(150, 150)];
        thumbData = UIImageJPEGRepresentation(thumbImage, 0.0);
    }
    [message setThumbData:thumbData];
    
    WXWebpageObject *ext = [WXWebpageObject object];
    ext.webpageUrl = pageUrl;
    message.mediaObject = ext;
    
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = scene;

    [self sendWechatMessage:req completionBlock:handler];
}

/**
 *  分享图片
 *
 *  @param scene        微信分享场景
 *  @param OriginImg    微信原图
 */
- (void)sharewithPicture:(WechatScene)scene OriginImage:(UIImage *)OriginImg completionBlock:(CompletionHandler)handler {
    
    WXMediaMessage *message = [WXMediaMessage message];
    UIImage *thuImg = [self scaleShareThumbImage:OriginImg toScale:(1.0*(GlobleHeight*0.7)/OriginImg.size.height)];
    [message setThumbImage:thuImg];
    
    // 封装的图片对象
    WXImageObject *imgObj = [WXImageObject object];
    NSData *imageData = UIImageJPEGRepresentation(OriginImg, 1.0);
    
    UIImage *img = [UIImage imageWithData:imageData];
    NSUInteger imagelen = [imageData length]/1024.0;
    if (imagelen/31.0>3){
        imageData = UIImageJPEGRepresentation(img, 0.0);
    }
    
    // 原大图
    imgObj.imageData = imageData;
    message.mediaObject = imgObj;
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = scene;
    
    [self sendWechatMessage:req completionBlock:handler];
}


/**
 *  分享图片
 *
 *  @param scene        微信分享场景
 *  @param OriginImg    微信原图
 *  @param thumbImg     微信缩略图
 */
- (void)sharewithPicture:(WechatScene)scene OriginImage:(UIImage *)OriginImg thumbImage:(UIImage *)thumbImg completionBlock:(CompletionHandler)handler {
    WXMediaMessage *message = [WXMediaMessage message];
    UIImage *thuImg = [self scaleShareThumbImage:OriginImg toScale:(1.0*(GlobleHeight*0.7)/OriginImg.size.height)];
    [message setThumbImage:thuImg];
    
    // 封装的图片对象
    WXImageObject *imgObj = [WXImageObject object];
    NSData *imageData = UIImageJPEGRepresentation(OriginImg, 1.0);
    
    UIImage *img = [UIImage imageWithData:imageData];
    NSUInteger imagelen = [imageData length]/1024.0;
    if (imagelen/31.0>3){
        imageData = UIImageJPEGRepresentation(img, 0.0);
    }
    
    // 原大图
    imgObj.imageData = imageData;
    message.mediaObject = imgObj;
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = scene;
    
    [self sendWechatMessage:req completionBlock:handler];
}

/**
 *  分享图片
 *
 *  @param scene            微信分享场景
 *  @param OriginImgData    微信原图
 */
- (void)sharewithPicture:(WechatScene)scene OriginImageData:(NSData *)OriginImgData completionBlock:(CompletionHandler)handler {
    WXMediaMessage *message = [WXMediaMessage message];
    
    UIImage *OriginImg = [UIImage imageWithData:OriginImgData];
    UIImage *thuImg = [self scaleShareThumbImage:OriginImg toScale:(1.0*(GlobleHeight*0.7)/OriginImg.size.height)];
    [message setThumbImage:thuImg];
    
    // 封装的图片对象
    WXImageObject *imgObj = [WXImageObject object];
    NSData *imageData = UIImageJPEGRepresentation(OriginImg, 1.0);
    
    UIImage *img = [UIImage imageWithData:imageData];
    NSUInteger imagelen = [imageData length]/1024.0;
    if (imagelen/31.0>3){
        imageData = UIImageJPEGRepresentation(img, 0.0);
    }
    
    // 原大图
    imgObj.imageData = imageData;
    message.mediaObject = imgObj;
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = scene;
    
    [self sendWechatMessage:req completionBlock:handler];
}

/**
 *  分享图片
 *
 *  @param scene            微信分享场景
 *  @param OriginImgData    微信原图
 *  @param thumbImgData     微信缩略图
 */
- (void)sharewithPicture:(WechatScene)scene OriginImageData:(NSData *)OriginImgData thumbImageData:(NSData *)thumbImgData completionBlock:(CompletionHandler)handler {
    WXMediaMessage *message = [WXMediaMessage message];
    
    UIImage *OriginImg = [UIImage imageWithData:OriginImgData];
    UIImage *thuImg = [self scaleShareThumbImage:OriginImg toScale:(1.0*(GlobleHeight*0.7)/OriginImg.size.height)];
    [message setThumbImage:thuImg];
    
    // 封装的图片对象
    WXImageObject *imgObj = [WXImageObject object];
    NSData *imageData = UIImageJPEGRepresentation(OriginImg, 1.0);
    
    UIImage *img = [UIImage imageWithData:imageData];
    NSUInteger imagelen = [imageData length]/1024.0;
    if (imagelen/31.0>3){
        imageData = UIImageJPEGRepresentation(img, 0.0);
    }
    
    // 原大图
    imgObj.imageData = imageData;
    message.mediaObject = imgObj;
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = scene;
    
    [self sendWechatMessage:req completionBlock:handler];
}

- (void)sendWechatMessage:(SendMessageToWXReq *)message completionBlock:(CompletionHandler)handler {
    // 处理结果
    [LCWechatObject wechatManager].completionHandler = handler;
    // 发送消息
    [WXApi sendReq:message];
}

#pragma mark - UIImage Util
- (UIImage *)thumbImageWithImage:(UIImage *)scImg limitSize:(CGSize)limitSize {
    if (scImg.size.width <= limitSize.width && scImg.size.height <= limitSize.height) {
        return scImg;
    }
    CGSize thumbSize;
    if (scImg.size.width / scImg.size.height > limitSize.width / limitSize.height) {
        thumbSize.width = limitSize.width;
        thumbSize.height = limitSize.width / scImg.size.width * scImg.size.height;
    }
    else {
        thumbSize.height = limitSize.height;
        thumbSize.width = limitSize.height / scImg.size.height * scImg.size.width;
    }
    UIGraphicsBeginImageContext(thumbSize);
    [scImg drawInRect:(CGRect){CGPointZero,thumbSize}];
    UIImage *thumbImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return thumbImg;
}

-(UIImage *)scaleShareThumbImage:(UIImage *)image toScale:(float)scaleSize {
    float scale = 0.8;
    if (scaleSize<scale) {
        scale=scale<0.3?scaleSize:0.3;
    }
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scale, image.size.height * scale));
    [image drawInRect:CGRectMake(0, 0, image.size.width * scale, image.size.height * scale)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
    
}


#pragma mark - WXApiDelegate

-(void) onReq:(BaseReq*)req {
    NSLog(@"req:%@",req);
}

-(void) onResp:(BaseResp*)resp {
    if ([resp isMemberOfClass:[SendAuthResp class]]) {
        NSString *code = [(SendAuthResp *)resp code];
        [self getWeChatAccessTokenWithCode:code completion:^(id responseObj, NSError *error) {
            [self parserJsonObj:responseObj];
        }];
    }
    
    if ([resp isMemberOfClass:[SendMessageToWXResp class]]) { // 微信分享后结果
        BaseResp *response = (BaseResp *)resp;
        if (response.errCode == WXSuccess) { // 分享成功
            self.completionHandler(LCShareResultSuccess,@"分享成功");
        } else if (response.errCode == WXErrCodeUserCancel) { // 用户取消分享
            self.completionHandler(LCShareResultCancel,@"取消分享");
        } else {// 发送失败
            self.completionHandler(LCShareResultFailed,@"分享失败");
        }
    }
}

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
