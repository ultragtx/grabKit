//
//  GRKRenrenGrabber.h
//  grabKit
//
//  Created by Xinrong Guo on 13-7-22.
//
//

#import <Foundation/Foundation.h>

#import "GRKServiceGrabber.h"
#import "GRKServiceGrabberProtocol.h"
#import "GRKServiceGrabberConnectionProtocol.h"
#import "GRKRenrenConnector.h"

@interface GRKRenrenGrabber : GRKServiceGrabber <GRKServiceGrabberProtocol, GRKServiceConnectorProtocol> {
    __block GRKRenrenConnector * renrenConnector;
}

@end
