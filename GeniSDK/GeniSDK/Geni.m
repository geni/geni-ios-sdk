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

#import "Geni.h"
#import "GeniRequest.h"

/************************************************************************************
 ** Constants
 ************************************************************************************/

static NSString* kApiURL = @"https://www.geni.com";
static NSString* kAuthorizePath = @"/oauth/authorize";
static NSString* kValidatePath = @"/oauth/validate_token";
static NSString* kInvalidatePath = @"/oauth/invalidate";

/************************************************************************************
 ** Implementation
 ************************************************************************************/

@implementation Geni

@synthesize appId, request, accessToken, sessionDelegate;

/************************************************************************************
 ** Initialization
 ************************************************************************************/

/**
 * Initialize the Geni object with application id.
 */

- (id)initWithAppId:(NSString *)newAppId {
    self = [super init];
    if (self) {
        self.appId = newAppId;
    }
    return self;
}

/************************************************************************************
 ** Private Methods
 ************************************************************************************/

/**
 * A private helper function for sending HTTP requests.
 *
 * @param url
 *            url to send http request
 * @param params
 *            parameters to append to the url
 * @param httpMethod
 *            http method @"GET" or @"POST"
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 */
- (GeniRequest*)openUrl:(NSString *)url
                 params:(NSMutableDictionary *)params
             httpMethod:(NSString *)httpMethod
               delegate:(id<GeniRequestDelegate>)delegate {
    
    if ([self isAccessTokenPresent]) {
        [params setValue:self.accessToken forKey:@"access_token"];
    }
    
    self.request = [GeniRequest requestWithParams: params
                                       httpMethod: httpMethod
                                         delegate: delegate
                                       requestURL: url];
    [self.request connect];
    return request;
}

/**
 * A private function for parsing URL parameters.
 */
- (NSDictionary*)parseURLParams:(NSString *)query {
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	for (NSString *pair in pairs) {
		NSArray *kv = [pair componentsSeparatedByString:@"="];
		NSString *val = [[kv objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		[params setObject:val forKey:[kv objectAtIndex:0]];
	}
    return params;
}


/************************************************************************************
 ** Public Methods
 ************************************************************************************/

- (NSString *) oauthCallbackUrl {
    return [NSString stringWithFormat:@"geni%@://authorize", appId];
}

- (void)authorize:(id<GeniSessionDelegate>)delegate {
    self.sessionDelegate = delegate;
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   appId,                  @"client_id",
                                   @"token",                @"response_type",
                                   [self oauthCallbackUrl], @"redirect_uri",
                                   nil];
    NSString *geniAppUrl = [GeniRequest serializeURL:[kApiURL stringByAppendingString:kAuthorizePath] params:params];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:geniAppUrl]];
}

/**
 * This function processes the URL the Safari used to
 * open your application during a single sign-on flow.
 *
 * You MUST call this function in your UIApplicationDelegate's handleOpenURL
 * method (see
 * http://developer.apple.com/library/ios/#documentation/uikit/reference/UIApplicationDelegate_Protocol/Reference/Reference.html
 * for more info).
 *
 * This will ensure that the authorization process will proceed smoothly once the
 * Geni application or Safari redirects back to your application.
 *
 * @param URL the URL that was passed to the application delegate's handleOpenURL method.
 *
 * @return YES if the URL starts with 'app_key://authorize and hence was handled
 *   by SDK, NO otherwise.
 */
- (BOOL)handleOpenURL:(NSURL *)url {
    // If the URL's structure doesn't match the structure used for Geni authorization, abort.
    if (![[url absoluteString] hasPrefix:[self oauthCallbackUrl]]) {
        return NO;
    }
    
    NSString *query = [url fragment];
    if (!query) {
        query = [url query];
    }
    
    NSDictionary *params = [self parseURLParams:query];
    NSString *newAccessToken = [params valueForKey:@"access_token"];
    
    // If the URL doesn't contain the access token, an error has occurred.
    if (!newAccessToken) {
        NSString *status = [params valueForKey:@"status"];
        
        BOOL userDidCancel = status && [status isEqualToString:@"unauthorized"];
        if ([self.sessionDelegate respondsToSelector:@selector(geniDidNotLogin:)]) {
            [self.sessionDelegate geniDidNotLogin:userDidCancel];
        }
        return YES;
    }
    
    self.accessToken = newAccessToken;
    if ([self.sessionDelegate respondsToSelector:@selector(geniDidLogin)]) {
        [self.sessionDelegate geniDidLogin];
    }
    return YES;
}

/**
 * Validates current access token. 
 **/
- (void)validate:(id<GeniSessionDelegate>)delegate {
    self.sessionDelegate = delegate;
    [self requestWithPath:[kApiURL stringByAppendingString:kValidatePath] andDelegate:self];
}

/**
 * Logs user out. No confirmation is necessary.
 **/
- (void)logout:(id<GeniSessionDelegate>)delegate {
    self.sessionDelegate = delegate;
    [self requestWithPath:[kApiURL stringByAppendingString:kInvalidatePath] andDelegate:nil];
    self.accessToken = nil;
    
    NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray* geniCookies = [cookies cookiesForURL: [NSURL URLWithString:kApiURL]];
    for (NSHTTPCookie* cookie in geniCookies) {
        [cookies deleteCookie:cookie];
    }
    
    if ([self.sessionDelegate respondsToSelector:@selector(geniDidLogout)]) {
        [self.sessionDelegate geniDidLogout];
    }
}

- (GeniRequest*)requestWithPath: (NSString *)path
                    andDelegate: (id <GeniRequestDelegate>)delegate {
    
    return [self requestWithPath: path
                       andParams: [NSMutableDictionary dictionary]
                   andHttpMethod: @"GET"
                     andDelegate: delegate];
}

- (GeniRequest*)requestWithPath: (NSString *)path
                      andParams: (NSMutableDictionary *)params
                    andDelegate: (id <GeniRequestDelegate>)delegate {
    
    return [self requestWithPath: path
                       andParams: params
                   andHttpMethod: @"GET"
                     andDelegate: delegate];
}

- (GeniRequest*)requestWithPath: (NSString *)path
                      andParams: (NSMutableDictionary *)params
                  andHttpMethod: (NSString *)httpMethod
                    andDelegate: (id <GeniRequestDelegate>)delegate {
    
    NSString *fullURL = path;
    if (([path rangeOfString:@"http"]).length == 0) {
        fullURL = [kApiURL stringByAppendingFormat:@"/api/%@", path];
    }
    
    return [self openUrl:fullURL
                  params:params
              httpMethod:httpMethod
                delegate:delegate];
}

/**
 * @return boolean - whether access token is present
 */
- (BOOL)isAccessTokenPresent {
    return (self.accessToken != nil);
}

/**
 * Validate the token.
 */
- (void)request:(GeniRequest *)request didFailWithError:(NSError *)error {
    self.accessToken = nil;
    if ([self.sessionDelegate respondsToSelector:@selector(geniDidNotLogin:)]) {
        [self.sessionDelegate geniDidNotLogin:NO];
    }
}

- (void)request:(GeniRequest *)request didLoad:(id)result {
    NSDictionary *data = (NSDictionary *) result;
    if ([data valueForKey:@"access_token"] != nil) {
        self.accessToken = [data valueForKey:@"access_token"];
    }
    
    if ([self.sessionDelegate respondsToSelector:@selector(geniDidLogin)]) {
        [self.sessionDelegate geniDidLogin];
    }
}

@end
