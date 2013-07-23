//
//  GRKRenrenSingleton.m
//  grabKit
//
//  Created by Xinrong Guo on 13-7-22.
//
//

#import "GRKRenrenSingleton.h"
#import "GRKConstants.h"

static GRKRenrenSingleton * sharedRenren = nil;

@implementation GRKRenrenSingleton

+ (GRKRenrenSingleton *)sharedInstance {
    if (sharedRenren == nil) {
        sharedRenren = [[GRKRenrenSingleton alloc] init];
    }
    return sharedRenren;
}

- (id)init {
    self = [super init];
    if (self) {
        [RennClient initWithAppId:[GRKCONFIG renrenAppId] apiKey:[GRKCONFIG renrenApiKey] secretKey:[GRKCONFIG renrenApiSecret]];
        [RennClient setScope:@"read_user_photo read_user_album"]; // http://wiki.dev.renren.com/wiki/权限列表
    }
    return self;
}

@end
