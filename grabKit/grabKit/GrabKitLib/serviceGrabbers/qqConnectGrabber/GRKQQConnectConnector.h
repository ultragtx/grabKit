//
//  GRKQQConnectConnector.h
//  grabKit
//
//  Created by Xinrong Guo on 13-7-27.
//
//

#import "GRKServiceGrabberProtocol.h"
#import "GRKServiceConnectorProtocol.h"
#import "GRKServiceConnector.h"
#import <TencentOpenAPI/TencentOAuth.h>

@interface GRKQQConnectConnector : GRKServiceConnector <TencentSessionDelegate, GRKServiceConnectorProtocol> {
    TencentOAuth *_tencentOAuth;
    
    GRKGrabberConnectionIsCompleteBlock _connectionIsCompleteBlock;
    GRKErrorBlock _connectionDidFailBlock;
    
    GRKGrabberDisconnectionIsCompleteBlock _disconnecctionIsCompleteBlock;
    
    NSMutableArray * _queries; // mutable array containing the queries loading
}

@end
