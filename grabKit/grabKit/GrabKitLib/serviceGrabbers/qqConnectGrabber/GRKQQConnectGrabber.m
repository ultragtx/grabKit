//
//  GRKQQConnectGrabber.m
//  grabKit
//
//  Created by Xinrong Guo on 13-7-27.
//
//

#import "GRKQQConnectGrabber.h"
#import "GRKAlbum.h"
#import "ISO8601DateFormatter.h"
#import "GRKConstants.h"
#import "GRKAlbum+modify.h"
#import "GRKConnectorsDispatcher.h"
#import "GRKConstants.h"
#import "GRKQQConnectQueriesQueue.h"
#import "GRKQQConnectSingleton.h"

static NSString *kGRKServiceNameQQConnect = @"QQConnect";

@implementation GRKQQConnectGrabber

- (id)init {
    self = [super initWithServiceName:kGRKServiceNameQQConnect];
    if (self) {
        qqConnectConnector = nil;
    }
    return self;
}

- (void)connectWithConnectionIsCompleteBlock:(GRKGrabberConnectionIsCompleteBlock)connectionIsCompleteBlock andErrorBlock:(GRKErrorBlock)errorBlock {
    [qqConnectConnector cancelAll];
    
    qqConnectConnector = [[GRKQQConnectConnector alloc] initWithGrabberType:_serviceName];
    
    [qqConnectConnector connectWithConnectionIsCompleteBlock:^(BOOL connected) {
        dispatch_async_on_main_queue(connectionIsCompleteBlock, connected);
        qqConnectConnector = nil;
    } andErrorBlock:^(NSError *error) {
        dispatch_async_on_main_queue(errorBlock, error);
        qqConnectConnector = nil;
    }];
}

- (void)disconnectWithDisconnectionIsCompleteBlock:(GRKGrabberDisconnectionIsCompleteBlock)disconnectionIsCompleteBlock andErrorBlock:(GRKErrorBlock)errorBlock {
    [qqConnectConnector cancelAll];
    
    qqConnectConnector = [[GRKQQConnectConnector alloc] initWithGrabberType:_serviceName];
    
    [qqConnectConnector disconnectWithDisconnectionIsCompleteBlock:^(BOOL disconnected) {
        dispatch_async_on_main_queue(disconnectionIsCompleteBlock, disconnected);
        qqConnectConnector = nil;
    } andErrorBlock:^(NSError *error) {
        dispatch_async_on_main_queue(errorBlock, error);
        qqConnectConnector = nil;
    }];
}

- (void)isConnected:(GRKGrabberConnectionIsCompleteBlock)connectedBlock {
    @throw NSInvalidArgumentException;
}

- (void)isConnected:(GRKGrabberConnectionIsCompleteBlock)connectedBlock errorBlock:(GRKErrorBlock)errorBlock {
    if ( connectedBlock == nil ) @throw NSInvalidArgumentException;
    
    [qqConnectConnector cancelAll];
    
    qqConnectConnector = [[GRKQQConnectConnector alloc] initWithGrabberType:_serviceName];
    
    [qqConnectConnector isConnected:^(BOOL connected) {
        dispatch_async_on_main_queue(connectedBlock, connected);
        qqConnectConnector = nil;
    } errorBlock:^(NSError *error) {
        dispatch_async_on_main_queue(errorBlock, error);
        qqConnectConnector = nil;
    }];
}

- (void)albumsOfCurrentUserAtPageIndex:(NSUInteger)pageIndex withNumberOfAlbumsPerPage:(NSUInteger)numberOfAlbumsPerPage andCompleteBlock:(GRKServiceGrabberCompleteBlock)completeBlock andErrorBlock:(GRKErrorBlock)errorBlock {
    
    // QQ Connect don't use paging
    
    __block GRKQQConnectQuery * albumsQuery = nil;
    
    albumsQuery = [GRKQQConnectQuery queryWithMethod:@"getListAlbum" andRequest:nil withHandlingBlock:^(id query, id result) {
        if (result != nil && [result isKindOfClass:[NSDictionary class]]) {
            NSArray *array = [result objectForKey:@"album"];
            NSMutableArray * albums = [NSMutableArray arrayWithCapacity:[array count]];
            
            for (NSDictionary *dict in array) {
                GRKAlbum *album = [self albumWithRawAlbum:dict];
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

- (void)fillAlbum:(GRKAlbum *)album withPhotosAtPageIndex:(NSUInteger)pageIndex withNumberOfPhotosPerPage:(NSUInteger)numberOfPhotosPerPage andCompleteBlock:(GRKServiceGrabberCompleteBlock)completeBlock andErrorBlock:(GRKErrorBlock)errorBlock {
    // QQ Connect don't use paging
    
    __block GRKQQConnectQuery *fillAlbumQuery = nil;
    
    TCListPhotoDic *request = [[TCListPhotoDic alloc] init];
    [request setParamAlbumid:album.albumId];
    
    fillAlbumQuery = [GRKQQConnectQuery queryWithMethod:@"getListPhotoWithParams:" andRequest:request withHandlingBlock:^(id query, id result) {
        if (result != nil && [result isKindOfClass:[NSDictionary class]]) {
            NSArray *array = [result objectForKey:@"photos"];
            NSMutableArray *photos = [NSMutableArray arrayWithCapacity:[array count]];
            
            for (NSDictionary *dict in array) {
                GRKPhoto *photo = [self photoWithRawPhoto:dict];
                [photos addObject:photo];
            }
            
            [album addPhotos:photos forPageIndex:0 withNumberOfPhotosPerPage:[array count]];
            dispatch_async_on_main_queue(completeBlock, photos);
        }
        else {
            dispatch_async_on_main_queue(errorBlock, [self errorForBadFormatResultForFillAlbumOperationWithOriginalAlbum:album]);
        }
        
        [self unregisterQueryAsLoading:fillAlbumQuery];
        fillAlbumQuery = nil;
    } andErrorBlock:^(NSError *error) {
        dispatch_async_on_main_queue(errorBlock, [self errorForFillAlbumOperationWithOriginalError:error]);
        
        [self unregisterQueryAsLoading:fillAlbumQuery];
        fillAlbumQuery = nil;
    }];
    
    [self registerQueryAsLoading:fillAlbumQuery];
    [fillAlbumQuery perform];
}

- (void)fillCoverPhotoOfAlbums:(NSArray *)albums withCompleteBlock:(GRKServiceGrabberCompleteBlock)completeBlock andErrorBlock:(GRKErrorBlock)errorBlock {
    /* __block GRKQQConnectQueriesQueue *queueForCoverPhotoIds = [[GRKQQConnectQueriesQueue alloc] init];
    
    for (GRKAlbum *album in albums) {
        [queueForCoverPhotoIds addQueryWithMethod:@"getListAlbum" andRequest:nil andName:album.albumId andHandlingBlock:^id(id queueOrBatchObject, id resultOrNil, NSError *errorOrNil) {
            ; // TODO: check result
            
            return nil;
        }];
    }
    
    [self registerQueryAsLoading:queueForCoverPhotoIds];
    
    [queueForCoverPhotoIds performWithFinalBlock:^(id query, id results) {
        dispatch_async_on_main_queue(completeBlock, [results allObjects]);
        
        [self unregisterQueryAsLoading:queueForCoverPhotoIds];
        queueForCoverPhotoIds = nil;
    }];*/
    
    // Cover already loaded in albumsOfCurrentUserAtPageIndex

    dispatch_async_on_main_queue(completeBlock, albums);
}

- (void)fillCoverPhotoOfAlbum:(GRKAlbum *)album andCompleteBlock:(GRKServiceGrabberCompleteBlock)completeBlock andErrorBlock:(GRKErrorBlock)errorBlock {
    [self fillCoverPhotoOfAlbums:[NSArray arrayWithObject:album]
               withCompleteBlock:completeBlock
                   andErrorBlock:errorBlock];
}

- (void)cancelAll {
    [qqConnectConnector cancelAll];
    
    NSArray *queriesToCancle = [NSArray arrayWithArray:_queries];
    
    for (GRKQQConnectQuery *query in queriesToCancle) {
        [query cancel];
        [self unregisterQueryAsLoading:query];
    }
}

- (void)cancelAllWithCompleteBlock:(GRKServiceGrabberCompleteBlock)completeBlock {
    [self cancelAll];
    
    dispatch_async_on_main_queue(completeBlock, nil);
}

#pragma mark - Helper

- (GRKAlbum *)albumWithRawAlbum:(NSDictionary *)rawAlbum {
    NSString *albumId = [rawAlbum objectForKey:@"albumid"];
    NSString *name = [rawAlbum objectForKey:@"name"];
    NSInteger count = [[rawAlbum objectForKey:@"picnum"] intValue];
    
    NSTimeInterval createTimeDouble = [[rawAlbum objectForKey:@"createtime"] doubleValue];
    NSDate *createDate = [NSDate dateWithTimeIntervalSince1970:createTimeDouble];
    
    NSMutableDictionary * dates = [NSMutableDictionary dictionaryWithCapacity:1];
    if (createDate) [dates setObject:createDate forKey:kGRKAlbumDatePropertyDateCreated];
    
    GRKAlbum * album = [GRKAlbum albumWithId:albumId andName:name andCount:count andDates:dates];
    
    NSString *coverURL = [rawAlbum objectForKey:@"coverurl"];
    GRKImage *coverImage = [self imageWithURL:coverURL];
    GRKPhoto *coverPhoto = [GRKPhoto photoWithId:nil andCaption:nil andName:nil andImages:[NSArray arrayWithObject:coverImage] andDates:nil];
    
    album.coverPhoto = coverPhoto;
    
    return album;
}


- (GRKPhoto *)photoWithRawPhoto:(NSDictionary *)rawPhoto {
    NSString *photoId = [rawPhoto objectForKey:@"lloc"];
    NSString *name = [rawPhoto objectForKey:@"name"];
    NSString *caption = [rawPhoto objectForKey:@"desc"];
    
    NSTimeInterval updateTimeDouble = [[rawPhoto objectForKey:@"updated_time"] doubleValue];
    NSTimeInterval uploadTimeDouble = [[rawPhoto objectForKey:@"uploaded_time"] doubleValue];
    
    NSDate *updateDate = [NSDate dateWithTimeIntervalSince1970:updateTimeDouble];
    NSDate *uploadDate = [NSDate dateWithTimeIntervalSince1970:uploadTimeDouble];
    
    NSDictionary *dates = [[NSDictionary alloc] initWithObjectsAndKeys:updateDate, kGRKPhotoDatePropertyDateUpdated, uploadDate, kGRKPhotoDatePropertyDateCreated, nil];
    
    NSDictionary *largImageRaw = [rawPhoto objectForKey:@"large_image"];
    GRKImage *largeImage = [self imageWithRawImage:largImageRaw];
    
    NSString *smallImageURL = [rawPhoto objectForKey:@"small_url"];
    GRKImage *smallImage = [self imageWithURL:smallImageURL];
    
    NSArray *images = [NSArray arrayWithObjects:smallImage, largeImage, nil];
    
    GRKPhoto *photo = [GRKPhoto photoWithId:photoId andCaption:caption andName:name andImages:images andDates:dates];
    
    return photo;
}

- (GRKImage *)imageWithRawImage:(NSDictionary *)rawImage {
    NSInteger height = [[rawImage objectForKey:@"height"] integerValue];
    NSInteger width = [[rawImage objectForKey:@"width"] integerValue];
    NSString *url = [rawImage objectForKey:@"url"];
    
    GRKImage *image = [GRKImage imageWithURLString:url andWidth:width andHeight:height isOriginal:YES];
    
    return image;
}

- (GRKImage *)imageWithURL:(NSString *)url {
    return [GRKImage imageWithURL:[NSURL URLWithString:url] andWidth:0 andHeight:0 isOriginal:NO];
}
@end
