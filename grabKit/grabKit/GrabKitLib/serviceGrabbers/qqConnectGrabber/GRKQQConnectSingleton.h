//
//  GRKQQConnectSingleton.h
//  grabKit
//
//  Created by Xinrong Guo on 13-7-27.
//
//

#import <Foundation/Foundation.h>
#import <TencentOpenAPI/TencentOAuth.h>

@interface GRKQQConnectSingleton : NSObject

@property (strong, nonatomic) NSString *accessToken;
@property (strong, nonatomic) NSString *openId;
@property (strong, nonatomic) NSDate *expirationDate;

+ (GRKQQConnectSingleton *)sharedInstance;

- (TencentOAuth *)newTencentOAuthWithDelegate:(id)delegate;

+ (NSArray *)permissions;

@end
