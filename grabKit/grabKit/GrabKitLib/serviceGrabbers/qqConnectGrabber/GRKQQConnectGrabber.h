//
//  GRKQQConnectGrabber.h
//  grabKit
//
//  Created by Xinrong Guo on 13-7-27.
//
//

#import "GRKServiceConnector.h"
#import "GRKServiceGrabber.h"
#import "GRKServiceGrabberProtocol.h"
#import "GRKServiceGrabberConnectionProtocol.h"
#import "GRKQQConnectConnector.h"

@interface GRKQQConnectGrabber : GRKServiceGrabber <GRKServiceGrabberProtocol, GRKServiceConnectorProtocol> {
    __block GRKQQConnectConnector * qqConnectConnector;
}

@end
