//
//  GRKRenrenQueriesQueue.h
//  grabKit
//
//  Created by Xinrong Guo on 13-7-22.
//
//

#import <Foundation/Foundation.h>
#import "GRKRenrenQuery.h"

@interface GRKRenrenQueriesQueue : NSObject {
    NSMutableArray * _queries;
    NSMutableArray * _runningQueries;
    
    NSMutableDictionary * _results;
    
    GRKQueryResultBlock _finalHandlingBlock;
}

- (void)addQueryWithParam:(RennParam *)param withName:(NSString *)name andHandlingBlock:(GRKSubqueryResultBlock)handlingBlock;

- (void)performWithFinalBlock:(GRKQueryResultBlock)handlingBlock;
- (void)cancel;

@end
