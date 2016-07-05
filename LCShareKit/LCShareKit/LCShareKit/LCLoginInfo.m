//
//  LCLoginInfo.m
//  LCShareKit
//
//  Created by lichao on 16/7/5.
//  Copyright © 2016年 bill. All rights reserved.
//

#import "LCLoginInfo.h"

@implementation LCLoginInfo

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.uid forKey:@"uid"];
    [aCoder encodeObject:self.token forKey:@"token"];
    [aCoder encodeObject:self.refreshToken forKey:@"refreshToken"];
    [aCoder encodeObject:self.expiationDate forKey:@"expiationDate"];
    [aCoder encodeObject:self.nick forKey:@"nick"];
    [aCoder encodeObject:self.headImageUrl forKey:@"headImageUrl"];
    [aCoder encodeObject:self.unionID forKey:@"unionID"];
    [aCoder encodeObject:self.province forKey:@"province"];
    [aCoder encodeObject:self.sex forKey:@"sex"];
    [aCoder encodeObject:[NSNumber numberWithInteger:self.isWeibo] forKey:@"isWeibo"];
    [aCoder encodeObject:[NSNumber numberWithInteger:self.isWeiboSession] forKey:@"isWeiboSession"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.uid = [aDecoder decodeObjectForKey:@"uid"];
        self.token = [aDecoder decodeObjectForKey:@"token"];
        self.refreshToken = [aDecoder decodeObjectForKey:@"refreshToken"];
        self.expiationDate = [aDecoder decodeObjectForKey:@"expiationDate"];
        self.nick = [aDecoder decodeObjectForKey:@"nick"];
        self.headImageUrl = [aDecoder decodeObjectForKey:@"headImageUrl"];
        self.unionID = [aDecoder decodeObjectForKey:@"unionID"];
        self.province = [aDecoder decodeObjectForKey:@"province"];
        self.sex = [aDecoder decodeObjectForKey:@"sex"];
        self.isWeibo = [[aDecoder decodeObjectForKey:@"isWeibo"] integerValue];
        self.isWeiboSession = [[aDecoder decodeObjectForKey:@"isWeiboSession"] integerValue];
    }
    return self;
}

@end
