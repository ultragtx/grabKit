//
//  GRKQQConnectGrabber+usernameAndProfilePicture.h
//  grabKit
//
//  Created by Xinrong Guo on 13-7-28.
//
//

#import "GRKQQConnectGrabber.h"

@interface GRKQQConnectGrabber (usernameAndProfilePicture)

- (void)loadUsernameAndProfilePictureOfCurrentUserWithCompleteBlock:(GRKServiceGrabberCompleteBlock)completeBlock andErrorBlock:(GRKErrorBlock)errorBlock;

@end
