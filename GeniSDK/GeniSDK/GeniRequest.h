/*
 * Copyright 2011-2012 Geni
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GeniResponse.h"

@protocol GeniRequestDelegate;

/**
 * Do not use this interface directly, instead, use method in Geni.h
 */
@interface GeniRequest : NSObject {
}

@property(nonatomic,assign) id<GeniRequestDelegate> delegate;

/**
 * The URL which will be contacted to execute the request.
 */
@property(nonatomic,copy) NSString* url;

/**
 * The API method which will be called.
 */
@property(nonatomic,copy) NSString* httpMethod;

/**
 * The dictionary of parameters to pass to the method.
 *
 * These values in the dictionary will be converted to strings using the
 * standard Objective-C object-to-string conversion facilities.
 */
@property(nonatomic,retain) NSMutableDictionary* params;
@property(nonatomic,retain) NSURLConnection*  connection;
@property(nonatomic,retain) GeniResponse*  response;


+ (NSString*) serializeURL: (NSString *)baseUrl params: (NSDictionary *)params;
+ (NSString*) serializeURL: (NSString *)baseUrl params: (NSDictionary *)params httpMethod: (NSString *)httpMethod;

+ (GeniRequest*) requestWithParams: (NSMutableDictionary *) params
                        httpMethod: (NSString *) httpMethod
                          delegate: (id<GeniRequestDelegate>)delegate
                        requestURL: (NSString *) url;
- (void) connect;

- (void) cancel;

- (BOOL) lsLoading;

@end

/************************************************************************************
 ** Geni Request Delegate
 ************************************************************************************/

/*
 *Your application should implement this delegate
 */
@protocol GeniRequestDelegate <NSObject>

@optional

/**
 * Called just before the request is sent to the server.
 */
- (void)geniRequestIsLoading:(GeniRequest *)request;

/**
 * Called when the server responds and begins to send back data.
 */
- (void)request:(GeniRequest *)request didReceiveResponse:(GeniResponse *)response;

/**
 * Called when an error prevents the request from completing successfully.
 */
- (void)request:(GeniRequest *)request didFailWithError:(NSError *)error;

/**
 * Called when a request returns a response.
 *
 * The result object is the raw response from the server of type NSData
 */
- (void)request:(GeniRequest *)request didLoadRawResponse:(NSData *)data;

/**
 * Called when a request returns and its response has been parsed into
 * an object.
 *
 * The resulting object may be a dictionary, an array, a string, or a number,
 * depending on thee format of the API response.
 */
- (void)request:(GeniRequest *)request didLoadResponse:(GeniResponse *)response;

@end

