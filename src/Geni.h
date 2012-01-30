/*
 * Copyright 2011 Geni
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>
#import "GeniRequest.h"

@protocol GeniSessionDelegate;

@interface Geni : NSObject <GeniRequestDelegate> {
    NSString* _apiURL;
    NSString* _accessToken;
    id<GeniSessionDelegate> _sessionDelegate;
    GeniRequest* _request;
    NSString* _appId;
}

@property(nonatomic, copy) NSString* apiURL;

@property(nonatomic, copy) NSString* accessToken;

@property(nonatomic, assign) id<GeniSessionDelegate> sessionDelegate;

- (id)initWithAppId:(NSString *)appId;

- (void)authorize:(id<GeniSessionDelegate>)delegate;

- (void)validate:(id<GeniSessionDelegate>)delegate;

- (BOOL)handleOpenURL:(NSURL *)url;

- (void)logout:(id<GeniSessionDelegate>)delegate;

- (GeniRequest*)requestWithPath:(NSString *)path
                    andDelegate:(id <GeniRequestDelegate>)delegate;

- (GeniRequest*)requestWithPath:(NSString *)path
                      andParams:(NSMutableDictionary *)params
                    andDelegate:(id <GeniRequestDelegate>)delegate;

- (GeniRequest*)requestWithPath:(NSString *)path
                      andParams:(NSMutableDictionary *)params
                  andHttpMethod:(NSString *)httpMethod
                    andDelegate:(id <GeniRequestDelegate>)delegate;

- (BOOL)isAccessTokenPresent;

@end


/************************************************************************************
 ** Geni Session Delegate
 ************************************************************************************/

/**
 * Your application should implement this delegate to receive session callbacks.
 */
@protocol GeniSessionDelegate <NSObject>

@optional

/**
 * Called when the user successfully logged in 
 * or when the access token was validated.
 */
- (void)geniDidLogin;

/**
 * Called when the user dismissed the dialog without logging in.
 * or when the access token was not validated.
 */
- (void)geniDidNotLogin:(BOOL)cancelled;

/**
 * Called when the user logged out.
 */
- (void)geniDidLogout;

@end
