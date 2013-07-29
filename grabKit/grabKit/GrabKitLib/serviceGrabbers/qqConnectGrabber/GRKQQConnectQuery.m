//
//  GRKQQConnectQuery.m
//  grabKit
//
//  Created by Xinrong Guo on 13-7-27.
//
//

#import "GRKQQConnectQuery.h"
#import "GRKQQConnectSingleton.h"

static NSString * const kGRKQQConnectError = @"com.grabkit.qqconnect.GRKQQConnectQuery";

@implementation GRKQQConnectQuery

+ (GRKQQConnectQuery *)queryWithMethod:(NSString *)method andRequest:(NSMutableDictionary *)request withHandlingBlock:(GRKQueryResultBlock)handlingBlock andErrorBlock:(GRKErrorBlock)errorBlock {
    GRKQQConnectQuery *query = [[self alloc] initWithMethod:method andRequest:request withHandlingBlock:handlingBlock andErrorBlock:errorBlock];
    return query;
}

- (id)initWithMethod:(NSString *)method andRequest:(NSMutableDictionary *)request withHandlingBlock:(GRKQueryResultBlock)handlingBlock andErrorBlock:(GRKErrorBlock)errorBlock {
    self = [super init];
    if (self) {
        _request = request;
        _method = method;
        
        _handlingBlock = handlingBlock;
        _errorBlock = errorBlock;
    }
    return self;
}

- (void)perform {
    _tencentOAuth = [[GRKQQConnectSingleton sharedInstance] newTencentOAuthWithDelegate:self];
    BOOL success = YES;
    if ([_method isEqualToString:@"getUserInfo"]) {
        success = [_tencentOAuth getUserInfo];
    }
    else if ([_method isEqualToString:@"getListAlbum"]) {
        success = [_tencentOAuth getListAlbum];
    }
    else if ([_method isEqualToString:@"getListPhotoWithParams:"]) {
        success = [_tencentOAuth getListPhotoWithParams:_request];
    }
    else {
        NSDictionary *infoDict = [NSDictionary dictionaryWithObject:@"Method not implemented yet" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:kGRKQQConnectError code:-1 userInfo:infoDict];
        _errorBlock(error);
        return;
    }
    
    if (!success) {
        NSDictionary *infoDict = [NSDictionary dictionaryWithObject:@"Login status fail" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:kGRKQQConnectError code:-1 userInfo:infoDict];
        _errorBlock(error);
    }
}

- (void)cancel {
    _handlingBlock = nil;
    _errorBlock = nil;
    [_tencentOAuth cancel:nil];
}

- (void)sendResponseToBlock:(APIResponse *)response {
    if (response.retCode == URLREQUEST_FAILED && _errorBlock != nil) {
        NSDictionary *infoDict = [NSDictionary dictionaryWithObject:response.errorMsg forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:kGRKQQConnectError code:response.detailRetCode userInfo:infoDict];
        
//        _errorBlock(error);
        if ( _errorBlock != nil ){
            @synchronized(self) {
                _errorBlock(error);
            }
        }
    }
    else if (response.retCode == URLREQUEST_SUCCEED && _handlingBlock != nil) {
//        _handlingBlock(self, response.jsonResponse);
        
        if (_handlingBlock != nil ){
            @synchronized(self) {
                _handlingBlock(self, response.jsonResponse);
            }
        }
    }
}

#pragma mark - QQ Connect Delegate

- (void)getUserInfoResponse:(APIResponse*) response {
    [self sendResponseToBlock:response];
}

- (void)getListAlbumResponse:(APIResponse*) response {
    [self sendResponseToBlock:response];
}

- (void)getListPhotoResponse:(APIResponse*) response {
    [self sendResponseToBlock:response];
}

- (void)tencentDidLogin {
    ;
}


- (void)tencentDidNotLogin:(BOOL)cancelled {
    ;
}


- (void)tencentDidNotNetWork {
    if (_errorBlock != nil) {
        NSDictionary *infoDict = [NSDictionary dictionaryWithObject:@"tencentDidNotNetWork" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:kGRKQQConnectError code:-1 userInfo:infoDict];
        _errorBlock(error);
    }
}
@end
