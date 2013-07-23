//
//  GRKRenrenConnector.h
//  grabKit
//
//  Created by Xinrong Guo on 13-7-22.
//
//

#import <Foundation/Foundation.h>
#import "GRKServiceConnectorProtocol.h"
#import "GRKServiceConnector.h"
#import <RennSDK/RennSDK.h>

@interface GRKRenrenConnector : GRKServiceConnector <GRKServiceConnectorProtocol, RennLoginDelegate> {
    GRKGrabberConnectionIsCompleteBlock connectionIsCompleteBlock;
    GRKErrorBlock connectionDidFailBlock;
    
    GRKGrabberDisconnectionIsCompleteBlock disconnecctionIsCompleteBlock;
    
    NSMutableArray * _queries; // mutable array containing the queries loading
}

@end
