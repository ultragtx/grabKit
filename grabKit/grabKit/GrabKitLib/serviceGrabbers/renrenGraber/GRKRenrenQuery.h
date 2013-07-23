//
//  GRKRenrenQuery.h
//  grabKit
//
//  Created by Xinrong Guo on 13-7-22.
//
//

#import <Foundation/Foundation.h>
#import "GRKServiceQueryProtocol.h"
#import "GRKServiceGrabberProtocol.h"
#import <RennSDK/RennSDK.h>

@interface GRKRenrenQuery : NSObject <GRKServiceQueryProtocol, RennServiveDelegate> {
    RennParam *param;
    RennService *service;
    
    GRKQueryResultBlock handlingBlock;
    GRKErrorBlock errorBlock;
}

+ (GRKRenrenQuery *)queryWithParam:(RennParam *)_param withHandlingBlock:(GRKQueryResultBlock)_handlingBlock andErrorBlock:(GRKErrorBlock)_errorBlock;

- (id)initWithParam:(RennParam *)_param withHandlingBlock:(GRKQueryResultBlock)_handlingBlock andErrorBlock:(GRKErrorBlock)_errorBlock;

- (void) perform;
- (void) cancel;

@end
