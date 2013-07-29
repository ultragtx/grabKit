//
//  GRKRenrenConnector.m
//  grabKit
//
//  Created by Xinrong Guo on 13-7-22.
//
//

#import "GRKRenrenConnector.h"
#import "GRKRenrenSingleton.h"
#import "GRKTokenStore.h"
#import "GRKRenrenQuery.h"
#import "GRKConstants.h"

static NSString * const kTokenType = @"TokenType";
static NSString * const kAccessToken = @"AccessToken";
static NSString * const kRefreshToken = @"RefreshToken";
static NSString * const kAccessScope = @"AccessScope";
static NSString * const kMacKey = @"MacKey";
static NSString * const kMacAlgorithm = @"MacAlgorithm";
static NSString * const kExpiresIn = @"ExpiresIn";
static NSString * const kRequestTime = @"RequestTime";

@implementation GRKRenrenConnector

- (id)initWithGrabberType:(NSString *)type {
    self = [super initWithGrabberType:type];
    if (self) {
        connectionIsCompleteBlock = nil;
        connectionDidFailBlock = nil;
        
        _queries = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Token storage

- (void)storeAccessToken:(RennAccessToken *)accessToken {
    if (accessToken.tokenType) [GRKTokenStore storeToken:accessToken.tokenType withName:kTokenType forGrabberType:grabberType];
    if (accessToken.accessToken) [GRKTokenStore storeToken:accessToken.accessToken withName:kAccessToken forGrabberType:grabberType];
    if (accessToken.refreshToken) [GRKTokenStore storeToken:accessToken.refreshToken withName:kRefreshToken forGrabberType:grabberType];
    if (accessToken.accessScope) [GRKTokenStore storeToken:accessToken.accessScope withName:kAccessScope forGrabberType:grabberType];
    if (accessToken.macKey) [GRKTokenStore storeToken:accessToken.macKey withName:kMacKey forGrabberType:grabberType];
    if (accessToken.macAlgorithm) [GRKTokenStore storeToken:accessToken.macAlgorithm withName:kMacAlgorithm forGrabberType:grabberType];
    
    NSString *strExpiresInt = [NSString stringWithFormat:@"%d", accessToken.expiresIn];
    [GRKTokenStore storeToken:strExpiresInt withName:kExpiresIn forGrabberType:grabberType];
    
    NSString *strRequestTime = [NSString stringWithFormat:@"%lf", accessToken.requestTime];
    [GRKTokenStore storeToken:strRequestTime withName:kRequestTime forGrabberType:grabberType];
    
//    [self removeUserDefaultsAccessToken];
}

- (RennAccessToken *)loadAccessToken {
    RennAccessToken *accessToken = [[RennAccessToken alloc] init];
    
    NSString * tokenType = [GRKTokenStore tokenWithName:kTokenType forGrabberType:grabberType];
    NSString * token = [GRKTokenStore tokenWithName:kAccessToken forGrabberType:grabberType];
    NSString * refreshToken = [GRKTokenStore tokenWithName:kRefreshToken forGrabberType:grabberType];
    NSString * accessScope = [GRKTokenStore tokenWithName:kAccessScope forGrabberType:grabberType];
    NSString * macKey = [GRKTokenStore tokenWithName:kMacKey forGrabberType:grabberType];
    NSString * macAlgorithm = [GRKTokenStore tokenWithName:kMacAlgorithm forGrabberType:grabberType];
    NSString * strExpiresIn = [GRKTokenStore tokenWithName:kExpiresIn forGrabberType:grabberType];
    NSString * strRequestTime = [GRKTokenStore tokenWithName:kRequestTime forGrabberType:grabberType];
    
    NSInteger expiresIn = 0;
    if (strExpiresIn) expiresIn = [strExpiresIn integerValue];
    
    NSTimeInterval requestTime = 0;
    if (strRequestTime) requestTime = [strRequestTime doubleValue];
    
    accessToken.tokenType = tokenType;
    accessToken.accessToken = token;
    accessToken.refreshToken = refreshToken;
    accessToken.accessScope = accessScope;
    accessToken.macKey = macKey;
    accessToken.macAlgorithm = macAlgorithm;
    accessToken.expiresIn = expiresIn;
    accessToken.requestTime = requestTime;
    
    return accessToken;
}

- (void)removeAccessToken {
    [GRKTokenStore removeTokenWithName:kTokenType forGrabberType:grabberType];
    [GRKTokenStore removeTokenWithName:kAccessToken forGrabberType:grabberType];
    [GRKTokenStore removeTokenWithName:kRefreshToken forGrabberType:grabberType];
    [GRKTokenStore removeTokenWithName:kAccessScope forGrabberType:grabberType];
    [GRKTokenStore removeTokenWithName:kMacKey forGrabberType:grabberType];
    [GRKTokenStore removeTokenWithName:kMacAlgorithm forGrabberType:grabberType];
    [GRKTokenStore removeTokenWithName:kExpiresIn forGrabberType:grabberType];
    [GRKTokenStore removeTokenWithName:kRequestTime forGrabberType:grabberType];
    
    [self removeUserDefaultsAccessToken];
}

- (void)removeUserDefaultsAccessToken {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:@"rr_renn_access_token"];
    [userDefaults removeObjectForKey:@"rr_renn_uid"];
    [userDefaults synchronize];
}

- (void)connectWithConnectionIsCompleteBlock:(GRKGrabberConnectionIsCompleteBlock)completeBlock andErrorBlock:(GRKErrorBlock)errorBlock {
    if ( completeBlock == nil ) @throw NSInvalidArgumentException;
    [GRKRenrenSingleton sharedInstance]; // Set apikey secret etc. to RennClient
    [RennClient setAccessToken:[self loadAccessToken]];
    
    if ([RennClient isAuthorizeValid]) {
        // Session is supposed to be valid, test to make sure it's valid
        
        __block GRKRenrenQuery *testLoginQuery = nil;
        GetUserLoginParam *param = [[GetUserLoginParam alloc] init];
        
        testLoginQuery = [GRKRenrenQuery queryWithParam:param withHandlingBlock:^(id query, id result) {
            if ([self isValidUserInfo:result]) {
                completeBlock(YES);
            }
            else {
                [self removeAccessToken];
                [self connectWithConnectionIsCompleteBlock:completeBlock andErrorBlock:errorBlock];
            }
            [_queries removeObject:testLoginQuery];
            testLoginQuery = nil;
        } andErrorBlock:^(NSError *error) {
            [self removeUserDefaultsAccessToken];
            [self connectWithConnectionIsCompleteBlock:completeBlock andErrorBlock:errorBlock];
            
            [_queries removeObject:testLoginQuery];
            testLoginQuery = nil;
        }];
        
        [_queries addObject:testLoginQuery];
        [testLoginQuery perform];
    }
    else {
        connectionIsCompleteBlock = [completeBlock copy];
        connectionDidFailBlock = [errorBlock copy];
        
        [RennClient loginWithDelegate:self];
    }
    
}

-(void)disconnectWithDisconnectionIsCompleteBlock:(GRKGrabberDisconnectionIsCompleteBlock)completeBlock andErrorBlock:(GRKErrorBlock)errorBlock {
    [GRKRenrenSingleton sharedInstance];
    
    disconnecctionIsCompleteBlock = [completeBlock copy];
    connectionDidFailBlock = [errorBlock copy];
    
    [RennClient logoutWithDelegate:self];
}

-(void) isConnected:(GRKGrabberConnectionIsCompleteBlock)connectedBlock errorBlock:(GRKErrorBlock)errorBlock {
    if ( connectedBlock == nil ) @throw NSInvalidArgumentException;
    
    [GRKRenrenSingleton sharedInstance];
    [RennClient setAccessToken:[self loadAccessToken]];
    
    BOOL connected = [RennClient isAuthorizeValid];
    if (!connected) {
        dispatch_async_on_main_queue(connectedBlock, connected);
        return;
    }
    
    __block GRKRenrenQuery *testLoginQuery = nil;
    GetUserLoginParam *param = [[GetUserLoginParam alloc] init];
    
    testLoginQuery = [GRKRenrenQuery queryWithParam:param withHandlingBlock:^(id query, id result) {
        if ([self isValidUserInfo:result]) {
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

-(void) cancelAll {
    for (GRKRenrenQuery *query in _queries) {
        [query cancel];
    }
    [_queries removeAllObjects];
}

-(void) didNotCompleteConnection {
    if (connectionIsCompleteBlock != nil ){
        dispatch_async(dispatch_get_main_queue(), ^{
            connectionIsCompleteBlock(NO);
            connectionIsCompleteBlock = nil;
            connectionDidFailBlock = nil;
        });
    }
}

-(BOOL) canHandleURL:(NSURL*)url {
    return NO;
}

-(void) handleOpenURL:(NSURL*)url {
    
}

- (BOOL)isValidUserInfo:(id)result {
    if ([result isKindOfClass:[NSDictionary class]]) {
        id userId = [(NSDictionary *)result objectForKey:@"id"];
        if (userId != nil &&
            (
             (
              [userId isKindOfClass:[NSNumber class]] &&
              [(NSNumber *)userId compare:[NSNumber numberWithInt:0]] > 0
              )
             ||
             (
              [userId isKindOfClass:[NSString class]] &&
              [userId length] > 0 &&
              ![userId isEqualToString:@"<null>"]
              )
             )) {
                return YES;
            }
    }
    return NO;
}

#pragma mark -

#pragma mark - RennLoginDelegate

- (void)rennLoginSuccess {
    [self storeAccessToken:[RennClient accessToken]];
    if (connectionIsCompleteBlock != nil) {
        connectionIsCompleteBlock(YES);
        connectionIsCompleteBlock = nil;
        connectionDidFailBlock = nil;
    }
}

- (void)rennLogoutSuccess {
    [self removeAccessToken];
    if (disconnecctionIsCompleteBlock != nil) {
        disconnecctionIsCompleteBlock(YES);
        disconnecctionIsCompleteBlock = nil;
        connectionDidFailBlock = nil;
    }
}

- (void)rennLoginCancelded {
    if (connectionIsCompleteBlock != nil) {
        connectionIsCompleteBlock(NO);
        connectionIsCompleteBlock = nil;
        connectionDidFailBlock = nil;
    }
}

- (void)rennLoginDidFailWithError:(NSError *)error {
    if (connectionDidFailBlock != nil) {
        connectionDidFailBlock(error);
        connectionIsCompleteBlock = nil;
        connectionDidFailBlock = nil;
    }
}

- (void)rennLoginAccessTokenInvalidOrExpired:(NSError *)error {
    if (connectionDidFailBlock != nil) {
        connectionDidFailBlock(error);
        connectionIsCompleteBlock = nil;
        connectionDidFailBlock = nil;
    }
}

@end
