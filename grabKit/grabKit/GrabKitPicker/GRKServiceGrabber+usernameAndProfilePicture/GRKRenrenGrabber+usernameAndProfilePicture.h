//
//  GRKRenrenGrabber+usernameAndProfilePicture.h
//  grabKit
//
//  Created by Xinrong Guo on 13-7-23.
//
//

#import "GRKRenrenGrabber.h"

@interface GRKRenrenGrabber (usernameAndProfilePicture)

- (void)loadUsernameAndProfilePictureOfCurrentUserWithCompleteBlock:(GRKServiceGrabberCompleteBlock)completeBlock andErrorBlock:(GRKErrorBlock)errorBlock;

@end
