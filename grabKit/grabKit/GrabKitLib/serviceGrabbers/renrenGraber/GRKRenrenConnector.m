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

- (void)saveAccessToken {
    RennAccessToken *accessToken = [RennClient accessToken];
    [GRKTokenStore storeToken:accessToken.accessToken withName:kTokenType forGrabberType:grabberType];
}

- (void)loadAccessToken {
    
}

- (void)connectWithConnectionIsCompleteBlock:(GRKGrabberConnectionIsCompleteBlock)completeBlock andErrorBlock:(GRKErrorBlock)errorBlock {
    if ( completeBlock == nil ) @throw NSInvalidArgumentException;
    // TODO: Load and set Token
    [GRKRenrenSingleton sharedInstance]; // Set apikey secret etc. to RennClient
    
    if ([RennClient isAuthorizeValid]) {
        // Session is supposed to be valid, test to make sure it's valid
        
        GRKRenrenQuery *query = nil;
        GetUserLoginParam *param = [[GetUserLoginParam alloc] init];
        
        query = [GRKRenrenQuery queryWithParam:param withHandlingBlock:^(id query, id result) {
            if ([self isValidUserInfo:result]) {
                completeBlock(YES);
            }
            else {
                // TODO: Remove stored token
                [self connectWithConnectionIsCompleteBlock:completeBlock andErrorBlock:errorBlock];
            }
            [_queries removeObject:query];
        } andErrorBlock:^(NSError *error) {
            // TODO: Remove stored token
            [self connectWithConnectionIsCompleteBlock:completeBlock andErrorBlock:errorBlock];
            
            [_queries removeObject:query];
        }];
        
        [_queries addObject:query];
        [query perform];
    }
    else {
        connectionIsCompleteBlock = [completeBlock copy];
        connectionDidFailBlock = [errorBlock copy];
        
        [RennClient loginWithDelegate:self];
    }
    
}

-(void)disconnectWithDisconnectionIsCompleteBlock:(GRKGrabberDisconnectionIsCompleteBlock)completeBlock andErrorBlock:(GRKErrorBlock)errorBlock {
    [GRKRenrenSingleton sharedInstance];
    
    connectionIsCompleteBlock = [completeBlock copy];
    connectionDidFailBlock = [errorBlock copy];
    
    [RennClient logoutWithDelegate:self];
}

-(void) isConnected:(GRKGrabberConnectionIsCompleteBlock)connectedBlock errorBlock:(GRKErrorBlock)errorBlock {
    if ( connectedBlock == nil ) @throw NSInvalidArgumentException;
    
    [GRKRenrenSingleton sharedInstance];
    // TODO: Load token
    
    BOOL connected = [RennClient isAuthorizeValid];
    if (!connected) {
        dispatch_async_on_main_queue(connectedBlock, connected);
        return;
    }
    
    GRKRenrenQuery *query = nil;
    GetUserLoginParam *param = [[GetUserLoginParam alloc] init];
    
    query = [GRKRenrenQuery queryWithParam:param withHandlingBlock:^(id query, id result) {
        if ([self isValidUserInfo:result]) {
            connectedBlock(YES);
        }
        else {
            connectedBlock(NO);
        }
        
        
        [_queries removeObject:query];
    } andErrorBlock:^(NSError *error) {
        // TODO: Remove stored token
        if (errorBlock) {
            errorBlock(error);
        }
        [_queries removeObject:query];
    }];
    
    [_queries addObject:query];
    [query perform];
}

-(void) cancelAll {
    for (GRKRenrenQuery *query in _queries) {
        [query cancel];
    }
    [_queries removeAllObjects];
}

-(void) didNotCompleteConnection {
    
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
    // TODO: Store token
    if (connectionIsCompleteBlock != nil) {
        connectionIsCompleteBlock(YES);
        connectionIsCompleteBlock = nil;
        connectionDidFailBlock = nil;
    }
}

- (void)rennLogoutSuccess {
    // TODO: Remove toen
    if (connectionIsCompleteBlock != nil) {
        connectionIsCompleteBlock(YES);
        connectionIsCompleteBlock = nil;
        connectionDidFailBlock = nil;
    }
}

- (void)rennLoginCancelded {
    ;
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
