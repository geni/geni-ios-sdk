/*
 * Copyright 2011 Geni
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

static NSString* kBaseURL = @"https://www.geni.com/api/";

static NSString* kAuthorizeURL = @"https://www.geni.com/oauth/authorize";
static NSString* kValidateURL = @"https://www.geni.com/oauth/validate_token";
static NSString* kInvalidateURL = @"https://www.geni.com/oauth/invalidate";

/************************************************************************************
 ** Implementation
 ************************************************************************************/

@implementation Geni

@synthesize accessToken = _accessToken,
sessionDelegate = _sessionDelegate;

/**
 * Free internal structure
 */
- (void)dealloc {
    [_accessToken release];
    [_request release];
    [_appKey release];
    [_appSecret release];
    [super dealloc];
}

/************************************************************************************
 ** Initialization
 ************************************************************************************/

/**
 * Initialize the Geni object with application key and secret.
 */
- (id)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret {
    return [self initWithAppKey:appKey appSecret:appSecret accessToken:nil];
}

- (id)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret accessToken:(NSString *) accessToken {
    self = [super init];
    if (self) {
        [_appKey release];
        _appKey = [appKey copy];
        [_appSecret release];
        _appSecret = [appSecret copy];
        [_accessToken release];
        _accessToken = [accessToken copy];
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
    
    [_request release];
    _request = [[GeniRequest getRequestWithParams:params
                                       httpMethod:httpMethod
                                         delegate:delegate
                                       requestURL:url] retain];
    [_request connect];
    return _request;
}

/**
 * A private function for parsing URL parameters.
 */
- (NSDictionary*)parseURLParams:(NSString *)query {
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
	for (NSString *pair in pairs) {
		NSArray *kv = [pair componentsSeparatedByString:@"="];
		NSString *val =
        [[kv objectAtIndex:1]
         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
		[params setObject:val forKey:[kv objectAtIndex:0]];
	}
    return params;
}


/************************************************************************************
 ** Public Methods
 ************************************************************************************/

- (void)authorize:(id<GeniSessionDelegate>)delegate {
    _sessionDelegate = delegate;
    
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   _appKey, @"client_id",
                                   _appSecret, @"client_secret",
                                   @"token", @"response_type",
                                   @"user_agent", @"type",
                                   nil];

    NSString *nextUrl = [NSString stringWithFormat:@"%@://authorize", _appKey];
    [params setValue:nextUrl forKey:@"redirect_uri"];
    NSString *geniAppUrl = [GeniRequest serializeURL:kAuthorizeURL params:params];
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
    if (![[url absoluteString] hasPrefix:[NSString stringWithFormat:@"%@://authorize", _appKey]]) {
        return NO;
    }
    
    NSString *query = [url fragment];
    if (!query) {
        query = [url query];
    }
    
    NSDictionary *params = [self parseURLParams:query];
    NSString *accessToken = [params valueForKey:@"access_token"];

    // If the URL doesn't contain the access token, an error has occurred.
    if (!accessToken) {
        NSString *errorReason = [params valueForKey:@"error"];
        NSString *errorCode = [params valueForKey:@"error_code"];
        
        BOOL userDidCancel = !errorCode && (!errorReason || [errorReason isEqualToString:@"access_denied"]);
        if ([self.sessionDelegate respondsToSelector:@selector(geniDidNotLogin:)]) {
            [_sessionDelegate geniDidNotLogin:userDidCancel];
        }
        return YES;
    }
    
    self.accessToken = accessToken;
    if ([self.sessionDelegate respondsToSelector:@selector(geniDidLogin)]) {
        [_sessionDelegate geniDidLogin];
    }
    return YES;
}

/**
 * Validates current access token. 
 **/
- (void)validate:(id<GeniSessionDelegate>)delegate {
    _sessionDelegate = delegate;
    [self requestWithPath:kValidateURL andDelegate:self];
}

/**
 * Logs user out. No confirmation is necessary.
 **/
- (void)logout:(id<GeniSessionDelegate>)delegate {
    _sessionDelegate = delegate;
    [self requestWithPath:kInvalidateURL andDelegate:nil];
    [_accessToken release];
    _accessToken = nil;
    
    NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray* geniCookies = [cookies cookiesForURL: [NSURL URLWithString:@"http://www.geni.com"]];
    for (NSHTTPCookie* cookie in geniCookies) {
        [cookies deleteCookie:cookie];
    }
    
    if ([self.sessionDelegate respondsToSelector:@selector(geniDidLogout)]) {
        [_sessionDelegate geniDidLogout];
    }
}

- (GeniRequest*)requestWithPath:(NSString *)path
                    andDelegate:(id <GeniRequestDelegate>)delegate {
    
    return [self requestWithPath:path
                            andParams:[NSMutableDictionary dictionary]
                        andHttpMethod:@"GET"
                          andDelegate:delegate];
}

- (GeniRequest*)requestWithPath:(NSString *)path
                      andParams:(NSMutableDictionary *)params
                    andDelegate:(id <GeniRequestDelegate>)delegate {
    
    return [self requestWithPath:path
                       andParams:params
                   andHttpMethod:@"GET"
                     andDelegate:delegate];
}

- (GeniRequest*)requestWithPath:(NSString *)path
                      andParams:(NSMutableDictionary *)params
                  andHttpMethod:(NSString *)httpMethod
                    andDelegate:(id <GeniRequestDelegate>)delegate {

    NSString *fullURL = path;
    if (([path rangeOfString:@"http"]).length == 0) {
        fullURL = [kBaseURL stringByAppendingString:path];
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
    [_accessToken release];
    _accessToken = nil;
    if ([self.sessionDelegate respondsToSelector:@selector(geniDidNotLogin:)]) {
        [_sessionDelegate geniDidNotLogin:NO];
    }
}

- (void)request:(GeniRequest *)request didLoad:(id)result {
    if ([self.sessionDelegate respondsToSelector:@selector(geniDidLogin)]) {
        [_sessionDelegate geniDidLogin];
    }
}

@end
