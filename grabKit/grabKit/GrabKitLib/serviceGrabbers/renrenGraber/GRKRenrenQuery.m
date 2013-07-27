//
//  GRKRenrenQuery.m
//  grabKit
//
//  Created by Xinrong Guo on 13-7-22.
//
//

#import "GRKRenrenQuery.h"
#import "GRKConstants.h"
#import "GRKRenrenSingleton.h"

@implementation GRKRenrenQuery

+ (GRKRenrenQuery *)queryWithParam:(RennParam *)_param withHandlingBlock:(GRKQueryResultBlock)_handlingBlock andErrorBlock:(GRKErrorBlock)_errorBlock {
    GRKRenrenQuery *query = [[GRKRenrenQuery alloc] initWithParam:_param withHandlingBlock:_handlingBlock andErrorBlock:_errorBlock];
    return query;
}

- (id)initWithParam:(RennParam *)_param withHandlingBlock:(GRKQueryResultBlock)_handlingBlock andErrorBlock:(GRKErrorBlock)_errorBlock {
    self = [super init];
    if (self) {
        param = _param;
        handlingBlock = _handlingBlock;
        errorBlock = _errorBlock;
    }
    return self;
}

- (void)perform {
    [GRKRenrenSingleton sharedInstance];
    service = [RennClient sendAsynRequest:param delegate:self];
}

- (void)cancel {
    [service clearDelegateAndCancel];
}

#pragma mark - Renren query delegate

- (void)rennService:(RennService *)service requestSuccessWithResponse:(id)response{
//    NSError *jsonDecodingError = nil;
//    id result = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingAllowFragments error:&jsonDecodingError];
    
//    if (jsonDecodingError != nil) {
//        dispatch_async_on_main_queue(errorBlock, jsonDecodingError);
//        return;
//    }
    // response is already a dictionary 
    
    dispatch_async_on_main_queue(handlingBlock, self, response);
}

- (void)rennService:(RennService *)service requestFailWithError:(NSError*)error {
    dispatch_async_on_main_queue(errorBlock, error);
}


@end
