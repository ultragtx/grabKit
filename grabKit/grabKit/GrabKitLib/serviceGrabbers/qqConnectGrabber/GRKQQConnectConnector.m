//
//  GRKQQConnectConnector.m
//  grabKit
//
//  Created by Xinrong Guo on 13-7-27.
//
//

#import "GRKQQConnectConnector.h"
#import "GRKConstants.h"
#import "GRKConnectorsDispatcher.h"
#import "GRKAlbum.h"
#import "GRKQQConnectQuery.h"
#import "GRKQQConnectSingleton.h"
#import "GRKTokenStore.h"
#import "ISO8601DateFormatter.h"

static NSString * qqConnectAccessTokenKey = @"AccessTokenKey";
static NSString * qqConnectOpenIdKey = @"OpenIdKey";
static NSString * qqConnectExpirationDateKey = @"ExpirationDateKey";

static NSString * kGRKQQConnectError = @"com.grabkit.qqconnect.GRKQQConnectConnector";

@implementation GRKQQConnectConnector

- (id)initWithGrabberType:(NSString *)type {
    self = [super initWithGrabberType:type];
    if (self) {
        _tencentOAuth = nil;
        _connectionIsCompleteBlock = nil;
        _connectionDidFailBlock = nil;
        _disconnecctionIsCompleteBlock = nil;
        _queries = [NSMutableArray array];
    }
    return self;
}

- (void)loadStoredTokenForTencentOAuth:(TencentOAuth *)tencentOAuth {
    NSString *accessToken = [GRKTokenStore tokenWithName:qqConnectAccessTokenKey forGrabberType:grabberType];
    NSString *openId = [GRKTokenStore tokenWithName:qqConnectOpenIdKey forGrabberType:grabberType];
    NSString *expirationDateStr = [GRKTokenStore tokenWithName:qqConnectExpirationDateKey forGrabberType:grabberType];
    
    NSDate *expirationDate = nil;
    if (expirationDateStr) {
        ISO8601DateFormatter *formatter = [[ISO8601DateFormatter alloc] init];
        expirationDate = [formatter dateFromString:expirationDateStr];
    }
    
    [_tencentOAuth setAccessToken:accessToken];
    [_tencentOAuth setOpenId:openId];
    [_tencentOAuth setExpirationDate:expirationDate];
    
    [GRKQQConnectSingleton sharedInstance].accessToken =  accessToken;
    [GRKQQConnectSingleton sharedInstance].openId =  openId;
    [GRKQQConnectSingleton sharedInstance].expirationDate =  expirationDate;
}

- (void)storeTokenWithTencentOAuth:(TencentOAuth *)tencentOAuth {
    NSString *accessToken = [tencentOAuth accessToken];
    NSString *openId = [tencentOAuth openId];
    NSDate *expirationDate = [tencentOAuth expirationDate];
    
    ISO8601DateFormatter *formatter = [[ISO8601DateFormatter alloc] init];
    NSString *expirationDateStr = [formatter stringFromDate:expirationDate];
    
    [GRKTokenStore storeToken:accessToken withName:qqConnectAccessTokenKey forGrabberType:grabberType];
    [GRKTokenStore storeToken:openId withName:qqConnectOpenIdKey forGrabberType:grabberType];
    [GRKTokenStore storeToken:expirationDateStr withName:qqConnectExpirationDateKey forGrabberType:grabberType];
    
    [GRKQQConnectSingleton sharedInstance].accessToken =  accessToken;
    [GRKQQConnectSingleton sharedInstance].openId =  openId;
    [GRKQQConnectSingleton sharedInstance].expirationDate =  expirationDate;
    [GRKQQConnectSingleton sharedInstance].lastStoredTencentOAuth = tencentOAuth;
}

- (void)removeAccessToken {
    [GRKTokenStore removeTokenWithName:qqConnectAccessTokenKey forGrabberType:grabberType];
    [GRKTokenStore removeTokenWithName:qqConnectOpenIdKey forGrabberType:grabberType];
    [GRKTokenStore removeTokenWithName:qqConnectExpirationDateKey forGrabberType:grabberType];
    
    [GRKQQConnectSingleton sharedInstance].accessToken =  nil;
    [GRKQQConnectSingleton sharedInstance].openId =  nil;
    [GRKQQConnectSingleton sharedInstance].expirationDate =  nil;
    
    if (_tencentOAuth != nil) {
        _tencentOAuth.accessToken = nil;
        _tencentOAuth.openId = nil;
        _tencentOAuth.expirationDate = nil;
    }
}

- (void)connectWithConnectionIsCompleteBlock:(GRKGrabberConnectionIsCompleteBlock)connectionIsCompleteBlock andErrorBlock:(GRKErrorBlock)errorBlock {
    if ( connectionIsCompleteBlock == nil ) @throw NSInvalidArgumentException;
    
    if (_tencentOAuth) {
        [_tencentOAuth cancel:nil];
        _tencentOAuth.sessionDelegate = nil;
        _tencentOAuth = nil;
    }
    
    _tencentOAuth = [[GRKQQConnectSingleton sharedInstance] newTencentOAuthWithDelegate:self];
    
    [self loadStoredTokenForTencentOAuth:_tencentOAuth];
    if ([_tencentOAuth isSessionValid]) {
        __block GRKQQConnectQuery *testLoginQuery = nil;
        
        testLoginQuery = [GRKQQConnectQuery queryWithMethod:@"getUserInfo" andRequest:nil withHandlingBlock:^(id query, id result) {
            if (result != nil && [result isKindOfClass:[NSDictionary class]] && [result objectForKey:@"nickname"] != nil) {
                connectionIsCompleteBlock(YES);
            }
            else {
                connectionIsCompleteBlock(NO);
            }
            [_queries removeObject:testLoginQuery];
            testLoginQuery = nil;
        } andErrorBlock:^(NSError *error) {
            [self removeAccessToken];
            
            [self connectWithConnectionIsCompleteBlock:connectionIsCompleteBlock andErrorBlock:errorBlock];
            
            [_queries removeObject:testLoginQuery];
            testLoginQuery = nil;
        }];
        
        [_queries addObject:testLoginQuery];
        [testLoginQuery perform];
    }
    else {
        _connectionIsCompleteBlock = connectionIsCompleteBlock;
        _connectionDidFailBlock = errorBlock;
        
        [[GRKConnectorsDispatcher sharedInstance] registerServiceConnectorAsConnecting:self];
        // TODO: make this async ?
        [_tencentOAuth authorize:[GRKQQConnectSingleton permissions] inSafari:YES];
    }
}

- (void)disconnectWithDisconnectionIsCompleteBlock:(GRKGrabberDisconnectionIsCompleteBlock)disconnectionIsCompleteBlock andErrorBlock:(GRKErrorBlock)errorBlock {
    _disconnecctionIsCompleteBlock = disconnectionIsCompleteBlock;
    _connectionDidFailBlock = errorBlock;
    
    if (_tencentOAuth == nil) {
        _tencentOAuth = [[GRKQQConnectSingleton sharedInstance] newTencentOAuthWithDelegate:self];
        [self loadStoredTokenForTencentOAuth:_tencentOAuth];
    }
    else {
        [_tencentOAuth cancel:nil];
        _tencentOAuth.sessionDelegate = nil;
    }
    
    [_tencentOAuth logout:self];
}

- (void)isConnected:(GRKGrabberConnectionIsCompleteBlock)connectedBlock errorBlock:(GRKErrorBlock)errorBlock {
    if ( connectedBlock == nil ) @throw NSInvalidArgumentException;
    
    if (_tencentOAuth) {
        [_tencentOAuth cancel:nil];
        _tencentOAuth.sessionDelegate = nil;
        _tencentOAuth = nil;
    }
    
    _tencentOAuth = [[GRKQQConnectSingleton sharedInstance] newTencentOAuthWithDelegate:self];
    
    [self loadStoredTokenForTencentOAuth:_tencentOAuth];
    
    BOOL connected = [_tencentOAuth isSessionValid];
    if (!connected) {
        dispatch_async_on_main_queue(connectedBlock, connected);
        return;
    }
    
    __block GRKQQConnectQuery *testLoginQuery = nil;
    testLoginQuery = [GRKQQConnectQuery queryWithMethod:@"getUserInfo" andRequest:nil withHandlingBlock:^(id query, id result) {
        if (result != nil && [result isKindOfClass:[NSDictionary class]] && [result objectForKey:@"nickname"] != nil) {
            connectedBlock(YES);
        }
        else {
            connectedBlock(NO);
        }
        
        [_queries removeObject:testLoginQuery];
        testLoginQuery = nil;
    } andErrorBlock:^(NSError *error) {
        [self removeAccessToken];
        
        if (errorBlock) {
            errorBlock(error);
        }
        
        [_queries removeObject:testLoginQuery];
        testLoginQuery = nil;
    }];
    
    [_queries addObject:testLoginQuery];
    [testLoginQuery perform];
}

- (void)cancelAll {
    for (GRKQQConnectQuery *query in _queries) {
        [query cancel];
    }
    [_queries removeAllObjects];
}

- (void)didNotCompleteConnection {
    if (_connectionIsCompleteBlock != nil ){
        dispatch_async(dispatch_get_main_queue(), ^{
            _connectionIsCompleteBlock(NO);
            _connectionIsCompleteBlock = nil;
            _connectionDidFailBlock = nil;
        });
    }
}

- (BOOL)canHandleURL:(NSURL *)url {
    return ([[NSString stringWithFormat:@"%@://", [url scheme]] isEqualToString:[GRKCONFIG qqConnectRedirectUri]]);
}

- (void)handleOpenURL:(NSURL *)url {
    [TencentOAuth HandleOpenURL:url];
}

#pragma mark - Tencent Delegate

- (void)tencentDidLogin {
    [self storeTokenWithTencentOAuth:_tencentOAuth];
    if (_connectionIsCompleteBlock != nil) {
        _connectionIsCompleteBlock(YES);
        _connectionIsCompleteBlock = nil;
        _connectionDidFailBlock = nil;
    }
}


- (void)tencentDidNotLogin:(BOOL)cancelled {
    if (_connectionIsCompleteBlock != nil) {
        _connectionIsCompleteBlock(NO);
        _connectionIsCompleteBlock = nil;
        _connectionDidFailBlock = nil;
    }
}


- (void)tencentDidNotNetWork {
    if (_connectionDidFailBlock != nil) {
        NSDictionary *infoDict = [NSDictionary dictionaryWithObject:@"Method not implemented yet" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:kGRKQQConnectError code:-1 userInfo:infoDict];
        _connectionDidFailBlock(error);
        
        _connectionDidFailBlock = nil;
        _connectionIsCompleteBlock = nil;
        _disconnecctionIsCompleteBlock = nil;
    }
}

- (void)tencentDidLogout {
    [self removeAccessToken];
    if (_disconnecctionIsCompleteBlock != nil) {
        _disconnecctionIsCompleteBlock(YES);
        _disconnecctionIsCompleteBlock = nil;
        _connectionDidFailBlock = nil;
    }
}

@end
