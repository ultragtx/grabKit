//
//  GRKRenrenGrabber.m
//  grabKit
//
//  Created by Xinrong Guo on 13-7-22.
//
//

#import "GRKRenrenGrabber.h"
#import "GRKAlbum.h"
#import "ISO8601DateFormatter.h"
#import "GRKConstants.h"
#import "GRKAlbum+modify.h"
#import "GRKConnectorsDispatcher.h"
#import "GRKRenrenQueriesQueue.h"
#import "GRKConstants.h"
#import "GRKRenrenSingleton.h"

static NSString *kGRKServiceNameRenren = @"Renren";

@implementation GRKRenrenGrabber

- (id)init {
    self = [super initWithServiceName:kGRKServiceNameRenren];
    if (self) {
        renrenConnector = nil;
    }
    return self;
}

- (void)connectWithConnectionIsCompleteBlock:(GRKGrabberConnectionIsCompleteBlock)connectionIsCompleteBlock andErrorBlock:(GRKErrorBlock)errorBlock {
    [renrenConnector cancelAll];
    
    renrenConnector = [[GRKRenrenConnector alloc] initWithGrabberType:_serviceName];
    
    [renrenConnector connectWithConnectionIsCompleteBlock:^(BOOL connected) {
        dispatch_async_on_main_queue(connectionIsCompleteBlock, connected);
        renrenConnector = nil;
    } andErrorBlock:^(NSError *error) {
        dispatch_async_on_main_queue(errorBlock, error);
        renrenConnector = nil;
    }];
}

- (void)disconnectWithDisconnectionIsCompleteBlock:(GRKGrabberDisconnectionIsCompleteBlock)disconnectionIsCompleteBlock andErrorBlock:(GRKErrorBlock)errorBlock {
    [renrenConnector cancelAll];
    
    renrenConnector = [[GRKRenrenConnector alloc] initWithGrabberType:_serviceName];
    
    [renrenConnector disconnectWithDisconnectionIsCompleteBlock:^(BOOL disconnected) {
        dispatch_async_on_main_queue(disconnectionIsCompleteBlock, disconnected);
        renrenConnector = nil;
    } andErrorBlock:^(NSError *error) {
        dispatch_async_on_main_queue(errorBlock, error);
        renrenConnector = nil;
    }];
}

- (void)isConnected:(GRKGrabberConnectionIsCompleteBlock)connectedBlock {
    @throw NSInvalidArgumentException;
}

- (void)isConnected:(GRKGrabberConnectionIsCompleteBlock)connectedBlock errorBlock:(GRKErrorBlock)errorBlock {
    if ( connectedBlock == nil ) @throw NSInvalidArgumentException;
    
    [renrenConnector cancelAll];
    
    renrenConnector = [[GRKRenrenConnector alloc] initWithGrabberType:_serviceName];
    
    [renrenConnector isConnected:^(BOOL connected) {
        dispatch_async_on_main_queue(connectedBlock, connected);
        renrenConnector = nil;
    } errorBlock:^(NSError *error) {
        dispatch_async_on_main_queue(errorBlock, error);
        renrenConnector = nil;
    }];
}

- (void)albumsOfCurrentUserAtPageIndex:(NSUInteger)pageIndex
             withNumberOfAlbumsPerPage:(NSUInteger)numberOfAlbumsPerPage
                      andCompleteBlock:(GRKServiceGrabberCompleteBlock)completeBlock
                         andErrorBlock:(GRKErrorBlock)errorBlock {
    
    if ( numberOfAlbumsPerPage > 100 ) {
        
        NSException* exception = [NSException
                                  exceptionWithName:@"numberOfAlbumsPerPageTooHigh"
                                  reason:[NSString stringWithFormat:@"The number of albums per page you asked (%d) is too high", numberOfAlbumsPerPage]
                                  userInfo:nil];
        @throw exception;
    }
    
    [GRKRenrenSingleton sharedInstance];
    ListAlbumParam *param = [[ListAlbumParam alloc] init];
    param.ownerId = [RennClient uid];
    param.pageNumber = pageIndex + 1; // the api start at 1, in grabkit we start at 0
    param.pageSize = numberOfAlbumsPerPage;
    
    __block GRKRenrenQuery *albumsQuery = nil;
    
    albumsQuery = [GRKRenrenQuery queryWithParam:param withHandlingBlock:^(id query, id result) {
        if ([self isResultForAlbumsInTheExpectedFormat:result]) {
            NSMutableArray * albums = [NSMutableArray arrayWithCapacity:[(NSArray *)result count]];
            
            for (NSDictionary *rawAlbum in (NSArray *)result) {
                GRKAlbum *album = [self albumWithRawAlbum:rawAlbum];
                [albums addObject:album];
            }
            
            dispatch_async_on_main_queue(completeBlock, albums);
        }
        else {
            dispatch_async_on_main_queue(errorBlock, [self errorForBadFormatResultForAlbumsOperation]);
        }
        
        [self unregisterQueryAsLoading:albumsQuery];
        albumsQuery = nil;
    } andErrorBlock:^(NSError *error) {
        dispatch_async_on_main_queue(errorBlock, [self errorForAlbumsOperationWithOriginalError:error]);
        [self unregisterQueryAsLoading:albumsQuery];
        albumsQuery = nil;
    }];
    
    [self registerQueryAsLoading:albumsQuery];
    [albumsQuery perform];
}

- (void)fillAlbum:(GRKAlbum *)album
withPhotosAtPageIndex:(NSUInteger)pageIndex
withNumberOfPhotosPerPage:(NSUInteger)numberOfPhotosPerPage
 andCompleteBlock:(GRKServiceGrabberCompleteBlock)completeBlock
    andErrorBlock:(GRKErrorBlock)errorBlock {
    if ( numberOfPhotosPerPage > 100 ) {
        
        NSException* exception = [NSException
                                  exceptionWithName:@"numberOfPhotosPerPageTooHigh"
                                  reason:[NSString stringWithFormat:@"The number of photos per page you asked (%d) is too high", numberOfPhotosPerPage]
                                  userInfo:nil];
        @throw exception;
    }
    
    [GRKRenrenSingleton sharedInstance];
    ListPhotoParam *param = [[ListPhotoParam alloc] init];
    param.albumId = album.albumId;
    param.ownerId = [RennClient uid];
    param.pageSize = numberOfPhotosPerPage;
    param.pageNumber = pageIndex + 1; // the api start at 1, in grabkit we start at 0
    
    __block GRKRenrenQuery *albumQuery = nil;
    
    albumQuery = [GRKRenrenQuery queryWithParam:param withHandlingBlock:^(id query, id result) {
        if (result != nil && [result isKindOfClass:[NSArray class]]) {
            NSMutableArray *photos = [NSMutableArray array];
            
            for (NSDictionary *dict in result) {
                GRKPhoto *photo = [self photoWithRawPhoto:dict];
                [photos addObject:photo];
            }
            
            [album addPhotos:photos forPageIndex:pageIndex withNumberOfPhotosPerPage:numberOfPhotosPerPage];
            
            dispatch_async_on_main_queue(completeBlock, photos);
        }
        else {
            dispatch_async_on_main_queue(errorBlock, [self errorForBadFormatResultForFillAlbumOperationWithOriginalAlbum:album]);
        }
        
        [self unregisterQueryAsLoading:albumQuery];
        albumQuery = nil;
    } andErrorBlock:^(NSError *error) {
        dispatch_async_on_main_queue(errorBlock, [self errorForAlbumsOperationWithOriginalError:error]);
        [self unregisterQueryAsLoading:albumQuery];
        albumQuery = nil;
    }];
    
    [self registerQueryAsLoading:albumQuery];
    [albumQuery perform];
}

- (void)fillCoverPhotoOfAlbums:(NSArray *)albums
             withCompleteBlock:(GRKServiceGrabberCompleteBlock)completeBlock
                 andErrorBlock:(GRKErrorBlock)errorBlock {
    
    [GRKRenrenSingleton sharedInstance];
    __block GRKRenrenQueriesQueue * queriesQueue = [[GRKRenrenQueriesQueue alloc] init];
    
    for (GRKAlbum *album in albums) {
        GetAlbumParam *param = [[GetAlbumParam alloc] init];
        param.albumId = album.albumId;
        param.ownerId = [RennClient uid];
        
        [queriesQueue addQueryWithParam:param withName:album.albumId andHandlingBlock:^id(id queueOrBatchObject, id resultOrNil, NSError *errorOrNil) {
            if (errorOrNil != nil || resultOrNil == nil || ![resultOrNil isKindOfClass:[NSDictionary class]]) {
                return nil;
            }
            
            GRKPhoto *coverPhoto = [self coverPhotoWithRawAlbum:resultOrNil];
            [album setCoverPhoto:coverPhoto];
            
            return album;
        }];
    }
    
    [self registerQueryAsLoading:queriesQueue];
    
    [queriesQueue performWithFinalBlock:^(id query, id results) {
        dispatch_async_on_main_queue(completeBlock, [results allObjects]);
        
        [self unregisterQueryAsLoading:queriesQueue];
        queriesQueue = nil;
    }];
}

- (void)fillCoverPhotoOfAlbum:(GRKAlbum *)album
             andCompleteBlock:(GRKServiceGrabberCompleteBlock)completeBlock
                andErrorBlock:(GRKErrorBlock)errorBlock {
    [self fillCoverPhotoOfAlbums:[NSArray arrayWithObject:album]
               withCompleteBlock:completeBlock
                   andErrorBlock:errorBlock];
}

- (void)cancelAll {
    [renrenConnector cancelAll];
    
    NSArray *queriesToCancle = [NSArray arrayWithArray:_queries];
    
    for (GRKRenrenQuery *query in queriesToCancle) {
        [query cancel];
        [self unregisterQueryAsLoading:query];
    }
}


- (void)cancelAllWithCompleteBlock:(GRKServiceGrabberCompleteBlock)completeBlock {
    [self cancelAll];
    
    dispatch_async_on_main_queue(completeBlock, nil);
}

#pragma mark - Helper

- (BOOL)isResultForAlbumsInTheExpectedFormat:(id)result {
    if ([result isKindOfClass:[NSArray class]]) {
        return YES;
    }
    return NO;
}

- (GRKAlbum *)albumWithRawAlbum:(NSDictionary *)rawAlbum {
    NSString *albumId = [[rawAlbum objectForKey:@"id"] description];
    NSString *name = [rawAlbum objectForKey:@"name"];
    NSInteger count = [[rawAlbum objectForKey:@"photoCount"] intValue];
    
    NSString * dateCreatedDatetimeISO8601String = [rawAlbum objectForKey:@"createTime"];
    NSString * dateUpdatedDatetimeISO8601String = [rawAlbum objectForKey:@"lastModifyTime"];
    
    ISO8601DateFormatter *formatter = [[ISO8601DateFormatter alloc] init];
    NSDate * dateCreated = [formatter dateFromString:dateCreatedDatetimeISO8601String];
    NSDate * dateUpdated = [formatter dateFromString:dateUpdatedDatetimeISO8601String];
    
    NSMutableDictionary * dates = [NSMutableDictionary dictionary];
    if (dateCreated != nil) [dates setObject:dateCreated forKey:kGRKAlbumDatePropertyDateCreated];
    if (dateUpdated != nil) [dates setObject:dateUpdated forKey:kGRKAlbumDatePropertyDateUpdated];
    
    GRKAlbum * album = [GRKAlbum albumWithId:albumId andName:name andCount:count andDates:dates];
    
    // TODO: Fill cover here ?
    GRKPhoto *coverPhoto = [self coverPhotoWithRawAlbum:rawAlbum];
    album.coverPhoto = coverPhoto;
    
    return album;
}

- (GRKPhoto *)coverPhotoWithRawAlbum:(NSDictionary*)rawAlbum {
    GRKPhoto *photo = nil;
    
    NSArray *covers = [rawAlbum objectForKey:@"cover"];

    if (covers) {
        NSMutableArray *images = [NSMutableArray arrayWithCapacity:[covers count]];
        for (NSDictionary *dict in covers) {
            GRKImage *image = [self imageWithRawImage:dict];
            [images addObject:image];
        }
        photo = [GRKPhoto photoWithId:@"fake_cover_photo_id" andCaption:@"" andName:@"" andImages:images andDates:nil];
    }
    
    
    return photo;
}

- (GRKPhoto *)photoWithRawPhoto:(NSDictionary *)rawPhoto {
    NSString *photoId = [[rawPhoto objectForKey:@"id"] description];
    NSString *caption = [rawPhoto objectForKey:@"description"];
    
    NSMutableDictionary * dates = [NSMutableDictionary dictionary];
    
    NSString * dateCreatedDatetimeISO8601String = [rawPhoto objectForKey:@"createTime"];
    ISO8601DateFormatter *formatter = [[ISO8601DateFormatter alloc] init];
    NSDate * dateCreated = [formatter dateFromString:dateCreatedDatetimeISO8601String];
    [dates setObject:dateCreated forKey:kGRKPhotoDatePropertyDateCreated];
    
    NSMutableArray *images = [NSMutableArray array];
    
    for (NSDictionary *dict in [rawPhoto objectForKey:@"images"]) {
        GRKImage *image = [self imageWithRawImage:dict];
        [images addObject:image];
    }
    
    GRKPhoto *photo = [GRKPhoto photoWithId:photoId andCaption:caption andName:nil andImages:images andDates:dates];
    return photo;
}

- (GRKImage *)imageWithRawImage:(NSDictionary *)rawImage {
    NSString *url = [rawImage objectForKey:@"url"];
    
    NSString *size = [rawImage objectForKey:@"size"];
    NSUInteger imageWidth = 0;
    NSUInteger imageHeight = 0;
    
    BOOL isOriginal = NO;
    
    if ([size isEqualToString:@"LARGE"]) {
        imageWidth = 720;
        imageHeight = 720;
        isOriginal = YES;
    }
    else if ([size isEqualToString:@"MAIN"]) {
        imageWidth = 200;
        imageHeight = 600;
    }
    else if ([size isEqualToString:@"HEAD"]) {
        imageWidth = 100;
        imageHeight = 300;
    }
    else if ([size isEqualToString:@"TINY"]) {
        imageWidth = 50;
        imageHeight = 50;
    }
    GRKImage *image = [GRKImage imageWithURLString:url andWidth:imageWidth andHeight:imageHeight isOriginal:isOriginal];
    
    return image;
}

@end
