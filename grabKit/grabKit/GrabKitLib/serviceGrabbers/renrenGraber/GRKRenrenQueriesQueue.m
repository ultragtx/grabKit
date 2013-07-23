//
//  GRKRenrenQueriesQueue.m
//  grabKit
//
//  Created by Xinrong Guo on 13-7-22.
//
//

#import "GRKRenrenQueriesQueue.h"
#import "GRKConstants.h"

@implementation GRKRenrenQueriesQueue

- (id)init {
    self = [super init];
    if (self) {
        _queries = [NSMutableArray array];
        _runningQueries = [NSMutableArray array] ;
        
        _results = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addQueryWithParam:(RennParam *)param withName:(NSString *)name andHandlingBlock:(GRKSubqueryResultBlock)handlingBlock {
    if ( name == nil || [name length] == 0 ) {
        name = [NSString stringWithFormat:@"%p",param];
    }
    
    GRKRenrenQuery *queryToAdd = nil;
    
    GRKQueryResultBlock queryHandlingBlock = ^(id query, id result) {
        if ( handlingBlock != nil ){
            id handledResult = handlingBlock(self, result, nil);
            
            if ( handledResult != nil ){
                [_results setObject:handledResult forKey:name];
            }
        }
        
        [_runningQueries removeObject:query];
        [self performNextQuery];
    };
    
    GRKErrorBlock errorBlock = ^(NSError *error) {
        
        if ( handlingBlock != nil ){
            id handledResult = handlingBlock(self, nil, error);
            
            if ( handledResult != nil ){
                [_results setObject:handledResult forKey:name];
            }
        }
        
        [_runningQueries removeObject:queryToAdd];
        [self performNextQuery];
    };
    
    queryToAdd = [GRKRenrenQuery queryWithParam:param withHandlingBlock:queryHandlingBlock andErrorBlock:errorBlock];
    [_queries addObject:queryToAdd];
}

- (void)performWithFinalBlock:(GRKQueryResultBlock)handlingBlock  {
    _finalHandlingBlock = [handlingBlock copy];
    
    [self performNextQuery];
}


- (void)performNextQuery {
    if ( [_runningQueries count] >= kMaximumSimultaneousQueriesForPicasaQueriesQueue ){
        return;
    }
    
    if ( [_queries count] == 0 ){
        // If all the running queries have finished
        if ( [_runningQueries count] == 0 ){
            
            // perform final blocks
            dispatch_async_on_main_queue(_finalHandlingBlock, self, _results);
            
        }
        return;
    }
    
    GRKRenrenQuery * nextQueryToRun = [_queries objectAtIndex:0];
    
    [nextQueryToRun perform];
    
    [_runningQueries addObject:nextQueryToRun];
    [_queries removeObject:nextQueryToRun];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performNextQuery];
    });
}

- (void)cancel {
    _finalHandlingBlock = nil;
    [_results removeAllObjects];
    
    [_runningQueries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ( [obj respondsToSelector:@selector(cancel)] ){
            [obj cancel];
        }
        
    }];
    
    [_queries removeAllObjects];
    [_runningQueries removeAllObjects];
}

@end
