//
//  GRKQQConnectQueriesQueue.h
//  grabKit
//
//  Created by Xinrong Guo on 13-7-27.
//
//

#import <Foundation/Foundation.h>
#import "GRKQQConnectQuery.h"

@interface GRKQQConnectQueriesQueue : NSObject {
    NSMutableArray * _queries;
    NSMutableArray * _runningQueries;
    
    NSMutableDictionary * _results;
    
    GRKQueryResultBlock _finalHandlingBlock;
}

- (void)addQueryWithMethod:(NSString *)method andRequest:(NSMutableDictionary *)request andName:(NSString *)name andHandlingBlock:(GRKSubqueryResultBlock)handlingBlock;
- (void)performWithFinalBlock:(GRKQueryResultBlock)handlingBlock;
- (void)cancel;

@end
