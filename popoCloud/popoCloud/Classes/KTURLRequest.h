//
//  KTURLRequest.h
//  popoCloud
//
//  Created by suleyu on 13-8-26.
//
//

#import <Foundation/Foundation.h>

extern NSString* KTNetworkErrorDomain;
extern NSString* KTServerErrorDomain;

@interface KTURLRequest : NSObject <NSURLConnectionDataDelegate> {
    NSURLConnection* urlConnection;
    NSMutableData* resultData;
    NSInteger statusCode;
    NSError* error;
    
    id target;
    SEL selector;
}

- (id)initWithTarget:(id)target selector:(SEL)selector;

- (void)start;
- (void)cancel;

@property (nonatomic, assign) SEL downloadProgressSelector;
@property (nonatomic, assign) SEL uploadProgressSelector;

@property (nonatomic, readonly) CGFloat downloadProgress;
@property (nonatomic, readonly) CGFloat uploadProgress;

@property (nonatomic, readonly) NSInteger statusCode;
@property (nonatomic, readonly) NSData* resultData;
@property (nonatomic, readonly) NSString* resultString;
@property (nonatomic, readonly) NSObject* resultJSON;
@property (nonatomic, readonly) NSError* error;

/**
 Protocol (eg: HTTP / HTTPS / FTP etc). Defaults to HTTP
 */
@property (nonatomic,retain) NSString *protocol;

/**
 HTTP method to use (eg: GET / POST / PUT / DELETE / HEAD etc). Defaults to GET
 */
@property (nonatomic,retain) NSString *method;

/**
 服务器地址
 */
@property (nonatomic,retain) NSString *urlServer;

/**
 请求处理方法:/process?
 */
@property (nonatomic,retain) NSString *process;

/**
 参数表
 */
@property (nonatomic,retain) NSDictionary *params;

/**
 Set params in HTTP header fields
 */
@property (nonatomic,retain) NSDictionary *headers;

/**
 body
 */
@property (nonatomic,retain) NSData *body;

/**
 timeout value, the unit is second. The default value is 30 seconds
 */
@property (nonatomic,assign) NSTimeInterval timeoutSeconds;

@end
