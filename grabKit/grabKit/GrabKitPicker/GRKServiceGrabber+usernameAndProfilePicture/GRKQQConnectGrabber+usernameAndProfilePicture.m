//
//  GRKQQConnectGrabber+usernameAndProfilePicture.m
//  grabKit
//
//  Created by Xinrong Guo on 13-7-28.
//
//

#import "GRKQQConnectGrabber+usernameAndProfilePicture.h"
#import "GRKQQConnectQuery.h"
#import "GRKServiceGrabber+usernameAndProfilePicture.h"
#import "GRKConstants.h"

@implementation GRKQQConnectGrabber (usernameAndProfilePicture)

- (void)loadUsernameAndProfilePictureOfCurrentUserWithCompleteBlock:(GRKServiceGrabberCompleteBlock)completeBlock andErrorBlock:(GRKErrorBlock)errorBlock {
    __block GRKQQConnectQuery *getUserInfoQuery = nil;
    getUserInfoQuery = [GRKQQConnectQuery queryWithMethod:@"getUserInfo" andRequest:nil withHandlingBlock:^(id query, id result) {
        // TODO: check result
        if (result != nil && [result isKindOfClass:[NSDictionary class]] && [result objectForKey:@"nickname"] != nil) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
            NSString *username = [(NSDictionary *)result objectForKey:@"nickname"];
            [dict setObject:username forKey:kGRKUsernameKey];
            
            NSArray *headAvatar = [(NSDictionary *)result objectForKey:@"figureurl_qq_2"];
            if (headAvatar != nil && [headAvatar isKindOfClass:[NSString class]]) {
                [dict setObject:headAvatar forKey:kGRKProfilePictureKey];
            }
            
            dispatch_async_on_main_queue(completeBlock, dict);
        }
        
        [self unregisterQueryAsLoading:getUserInfoQuery];
        getUserInfoQuery = nil;
    } andErrorBlock:^(NSError *error) {
        if (errorBlock) {
            errorBlock(error);
        }
        
        [self unregisterQueryAsLoading:getUserInfoQuery];
        getUserInfoQuery = nil;
    }];
    
    [self registerQueryAsLoading:getUserInfoQuery];
    [getUserInfoQuery perform];
}

@end
