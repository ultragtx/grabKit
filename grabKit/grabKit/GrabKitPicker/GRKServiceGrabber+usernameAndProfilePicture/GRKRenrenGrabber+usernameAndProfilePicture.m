//
//  GRKRenrenGrabber+usernameAndProfilePicture.m
//  grabKit
//
//  Created by Xinrong Guo on 13-7-23.
//
//

#import "GRKRenrenGrabber+usernameAndProfilePicture.h"
#import <RennSDK/RennSDK.h>
#import "GRKConstants.h"
#import "GRKRenrenQuery.h"
#import "GRKRenrenSingleton.h"
#import "GRKServiceGrabber+usernameAndProfilePicture.h"

@implementation GRKRenrenGrabber (usernameAndProfilePicture)

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

- (void)loadUsernameAndProfilePictureOfCurrentUserWithCompleteBlock:(GRKServiceGrabberCompleteBlock)completeBlock andErrorBlock:(GRKErrorBlock)errorBlock {
    
    [GRKRenrenSingleton sharedInstance];
    NSString *userId = [RennClient uid];
    if ( userId == nil || [userId isEqualToString:@""]) {
        
        NSString * errorDomain = [NSString stringWithFormat:@"com.grabKit.%@.usernameAndProfilePicture", _serviceName];
        NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"invalid User ID", NSLocalizedDescriptionKey,
                                   nil];
        NSError * error = [NSError errorWithDomain:errorDomain code:0 userInfo:userInfo];
        
        dispatch_async_on_main_queue(errorBlock, error);
        
        return;
    }
    
    __block GRKRenrenQuery *query = nil;
    
    GetUserLoginParam *param = [[GetUserLoginParam alloc] init];
    
    query = [GRKRenrenQuery queryWithParam:param withHandlingBlock:^(id query, id result) {
        if ([self isValidUserInfo:result]) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
            NSString *username = [(NSDictionary *)result objectForKey:@"name"];
            [dict setObject:username forKey:kGRKUsernameKey];
            
            NSArray *headAvatar = [(NSDictionary *)result objectForKey:@"avatar"];
            if ([headAvatar isKindOfClass:[NSArray class]] && [headAvatar count] >= 4) {
                NSString *profilePictureURLString = [(NSDictionary *)[headAvatar objectAtIndex:1] objectForKey:@"url"];
                [dict setObject:profilePictureURLString forKey:kGRKProfilePictureKey];
            }
            
            dispatch_async_on_main_queue(completeBlock, dict);
        }
        else {
            dispatch_async_on_main_queue(errorBlock, [self errorForBadFormatResultForUsernameAndProfilePictureOperation]);
        }
        [self unregisterQueryAsLoading:query];
        query = nil;
    } andErrorBlock:^(NSError *error) {
        dispatch_async_on_main_queue(errorBlock, error);
        
        [self unregisterQueryAsLoading:query];
        query = nil;
    }];
    
    [self registerQueryAsLoading:query];
    [query perform];
}

@end
