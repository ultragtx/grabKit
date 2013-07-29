//
//  GRKQQConnectQuery.h
//  grabKit
//
//  Created by Xinrong Guo on 13-7-27.
//
//

#import <Foundation/Foundation.h>
#import "GRKServiceGrabberProtocol.h"
#import "GRKServiceQueryProtocol.h"
#import <TencentOpenAPI/TencentOAuth.h>

@interface GRKQQConnectQuery : NSObject <GRKServiceQueryProtocol, TencentSessionDelegate> {
    TencentOAuth *_tencentOAuth;
    NSString *_method;
    NSMutableDictionary *_request;
    
    GRKQueryResultBlock _handlingBlock;
    GRKErrorBlock _errorBlock;
}

+ (GRKQQConnectQuery *)queryWithMethod:(NSString *)method andRequest:(NSMutableDictionary *)request withHandlingBlock:(GRKQueryResultBlock)handlingBlock andErrorBlock:(GRKErrorBlock)errorBlock;

- (id)initWithMethod:(NSString *)method andRequest:(NSMutableDictionary *)request withHandlingBlock:(GRKQueryResultBlock)handlingBlock andErrorBlock:(GRKErrorBlock)errorBlock;


@end
