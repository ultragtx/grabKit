//
//  GRKQQConnectQueriesQueue.m
//  grabKit
//
//  Created by Xinrong Guo on 13-7-27.
//
//

#import "GRKQQConnectQueriesQueue.h"
#import "GRKConstants.h"

@implementation GRKQQConnectQueriesQueue

- (id)init {
    self = [super init];
    if (self) {
        _queries = [NSMutableArray array];
        _runningQueries = [NSMutableArray array];
        
        _results = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addQueryWithMethod:(NSString *)method andRequest:(NSMutableDictionary *)request andName:(NSString *)name andHandlingBlock:(GRKSubqueryResultBlock)handlingBlock {
    if (name == nil || [name length] == 0) {
        name = [NSString stringWithFormat:@"%@%p", method, request];
    }
    
    GRKQQConnectQuery *queryToAdd;
    
    GRKQueryResultBlock queryHandlingBlock = ^(id query, id result) {
        if (handlingBlock != nil) {
            id handledResult = handlingBlock(self, result, nil);
            
            if (handledResult != nil) {
                [_results setObject:handledResult forKey:name];
            }
        }
        
        [_runningQueries removeObject:query];
        [self performNextQuery];
    };
    
    GRKErrorBlock errorBlock = ^(NSError *error) {
        if (handlingBlock != nil) {
            id handledResult = handlingBlock(self, nil, error);
            if (handledResult != nil) {
                [_results setObject:handledResult forKey:name];
            }
        }
        
        [_runningQueries removeObject:queryToAdd];
        [self performNextQuery];
    };

    queryToAdd = [GRKQQConnectQuery queryWithMethod:method andRequest:request withHandlingBlock:queryHandlingBlock andErrorBlock:errorBlock];

    [_queries addObject:queryToAdd];
}

- (void)performWithFinalBlock:(GRKQueryResultBlock)handlingBlock {
    _finalHandlingBlock = handlingBlock;
    [self performNextQuery];
}

- (void)performNextQuery {
    if ([_runningQueries count] >= kMaximumSimultaneousQueriesForPicasaQueriesQueue) {
        return;
    }
    
    if ([_queries count] == 0) {
        if ([_runningQueries count] == 0) {
            dispatch_async_on_main_queue(_finalHandlingBlock, self, _results);
        }
        return;
    }
    
    GRKQQConnectQuery * nextQueryToRun = [_queries objectAtIndex:0];
    
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
        if ([obj respondsToSelector:@selector(cancel)]) {
            [obj cancel];
        }
    }];
    
    [_queries removeAllObjects];
    [_runningQueries removeAllObjects];
}

@end
