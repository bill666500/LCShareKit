//
//  LCPlatformObject.h
//  LCShareKit
//
//  Created by lichao on 16/7/5.
//  Copyright © 2016年 bill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCShareDefine.h"

@interface LCPlatformObject : NSObject

- (void)loginCompletion:(LoginHandler)handler;

- (void)logoutCompletion:(LogoutHandler)handler;

//- (void)shareModel:(LCShareModel *)model completionBlock:(CompletionHandler)handler;


@end
