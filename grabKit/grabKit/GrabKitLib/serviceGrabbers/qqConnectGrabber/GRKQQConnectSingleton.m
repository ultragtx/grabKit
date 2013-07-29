//
//  GRKQQConnectSingleton.m
//  grabKit
//
//  Created by Xinrong Guo on 13-7-27.
//
//

#import "GRKQQConnectSingleton.h"
#import "GRKConstants.h"

static GRKQQConnectSingleton * sharedQQConnect = nil;

@implementation GRKQQConnectSingleton

+ (GRKQQConnectSingleton *)sharedInstance {
    if (sharedQQConnect == nil) {
        sharedQQConnect = [[GRKQQConnectSingleton alloc] init];
    }
    return sharedQQConnect;
}

- (id)init {
    self = [super init];
    if (self) {
        // TODO: Load token
        
    }
    return self;
}

- (TencentOAuth *)newTencentOAuthWithDelegate:(id)delegate {
    TencentOAuth *tencentOAuth = [[TencentOAuth alloc] initWithAppId:[GRKCONFIG qqConnectAppId] andDelegate:delegate];
    [tencentOAuth setAccessToken:_accessToken];
    [tencentOAuth setOpenId:_openId];
    [tencentOAuth setExpirationDate:_expirationDate];
    return tencentOAuth;
}

+ (NSArray *)permissions {
    NSArray *permissions = [NSArray arrayWithObjects:
                            kOPEN_PERMISSION_GET_USER_INFO,
                            kOPEN_PERMISSION_GET_SIMPLE_USER_INFO,
                            kOPEN_PERMISSION_ADD_ALBUM,
                            kOPEN_PERMISSION_ADD_IDOL,
                            kOPEN_PERMISSION_ADD_ONE_BLOG,
                            kOPEN_PERMISSION_ADD_PIC_T,
                            kOPEN_PERMISSION_ADD_SHARE,
                            kOPEN_PERMISSION_ADD_TOPIC,
                            kOPEN_PERMISSION_CHECK_PAGE_FANS,
                            kOPEN_PERMISSION_DEL_IDOL,
                            kOPEN_PERMISSION_DEL_T,
                            kOPEN_PERMISSION_GET_FANSLIST,
                            kOPEN_PERMISSION_GET_IDOLLIST,
                            kOPEN_PERMISSION_GET_INFO,
                            kOPEN_PERMISSION_GET_OTHER_INFO,
                            kOPEN_PERMISSION_GET_REPOST_LIST,
                            kOPEN_PERMISSION_LIST_ALBUM,
                            kOPEN_PERMISSION_UPLOAD_PIC,
                            kOPEN_PERMISSION_GET_VIP_INFO,
                            kOPEN_PERMISSION_GET_VIP_RICH_INFO,
                            kOPEN_PERMISSION_GET_INTIMATE_FRIENDS_WEIBO,
                            kOPEN_PERMISSION_MATCH_NICK_TIPS_WEIBO,
                            nil];

    return permissions;
}

@end
