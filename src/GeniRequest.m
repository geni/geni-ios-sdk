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

#import "GeniRequest.h"
#import "JSON.h"

/************************************************************************************
 ** Constants
 ************************************************************************************/

static NSString* kUserAgent = @"iPhone";
static NSString* kStringBoundary = @"GeniPostBoundary";
static const int kGeneralErrorCode = 10000;

static const BOOL kEnableLogging = NO;

static const NSTimeInterval kTimeoutInterval = 180.0;

/************************************************************************************
 ** Implementation
 ************************************************************************************/

@implementation GeniRequest

@synthesize delegate = _delegate,
url = _url,
httpMethod = _httpMethod,
params = _params,
connection = _connection,
responseText = _responseText;

/**
 * Free internal structure
 */
- (void)dealloc {
    [_connection cancel];
    [_connection release];
    [_responseText release];
    [_url release];
    [_httpMethod release];
    [_params release];
    [super dealloc];
}

/************************************************************************************
 ** Class Public Mehtods
 ************************************************************************************/

+ (GeniRequest *)getRequestWithParams:(NSMutableDictionary *) params
                         httpMethod:(NSString *) httpMethod
                           delegate:(id<GeniRequestDelegate>) delegate
                         requestURL:(NSString *) url {
    
    GeniRequest *request = [[[GeniRequest alloc] init] autorelease];
    request.delegate = delegate;
    request.url = url;
    request.httpMethod = httpMethod;
    request.params = params;
    request.connection = nil;
    request.responseText = nil;
    
    return request;
}

/************************************************************************************
 ** Private Methods
 ************************************************************************************/

+ (NSString *)serializeURL:(NSString *)baseUrl params:(NSDictionary *)params {
    return [self serializeURL:baseUrl params:params httpMethod:@"GET"];
}

/**
 * Generate get URL
 */
+ (NSString*)serializeURL:(NSString *)baseUrl
                   params:(NSDictionary *)params
               httpMethod:(NSString *)httpMethod {
    
    NSURL* parsedURL = [NSURL URLWithString:baseUrl];
    NSString* queryPrefix = parsedURL.query ? @"&" : @"?";
    
    NSMutableArray* pairs = [NSMutableArray array];
    for (NSString* key in [params keyEnumerator]) {
        if (([[params valueForKey:key] isKindOfClass:[UIImage class]])
            ||([[params valueForKey:key] isKindOfClass:[NSData class]])) {
            if ([httpMethod isEqualToString:@"GET"]) {
                NSLog(@"can not use GET to upload a file");
            }
            continue;
        }
        
        NSString* escaped_value = (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                      NULL, /* allocator */
                                                                                      (CFStringRef)[params objectForKey:key],
                                                                                      NULL, /* charactersToLeaveUnescaped */
                                                                                      (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                      kCFStringEncodingUTF8);
        
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
        [escaped_value release];
    }
    NSString* query = [pairs componentsJoinedByString:@"&"];
    
    return [NSString stringWithFormat:@"%@%@%@", baseUrl, queryPrefix, query];
}

/************************************************************************************
 ** Logging Methods (Debug)
 ************************************************************************************/

- (void) logRequest:(NSURLRequest *)request {
    if (kEnableLogging == NO) return;
    
    NSLog(@"-------------------------------------------------------");
    NSLog(@"Request");
    NSLog(@"\tURL: %@", [[request URL] absoluteString]);
    NSLog(@"\tMethod: %@", [request HTTPMethod]);
    if ([[request HTTPMethod] isEqualToString:@"POST"] && [request HTTPBody] != nil) {
        NSString *stringData = [[[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
        NSLog(@"\tBody: %@", stringData);
    }
    for (NSString *key in [[request allHTTPHeaderFields] allKeys]) {
        NSLog(@"\t[Header]%@ = %@", key, [[request allHTTPHeaderFields] valueForKey:key]);
    }
}

- (void) logResponse:(NSHTTPURLResponse *)response {
    if (kEnableLogging == NO) return;

    NSLog(@"-------------------------------------------------------");
    NSLog(@"Response");
    NSLog(@"\tURL: %@", [[response URL] absoluteString]);
    NSLog(@"\tCode: %d", [response statusCode]);
    NSLog(@"\tMime Type: %@", [response MIMEType]);
    NSLog(@"\tExpected Content Length: %lld", [response expectedContentLength]);
    NSLog(@"\tText Encoding Name: %@", [response textEncodingName]);
    NSLog(@"\tSuggested File Name: %@", [response suggestedFilename]);
    for (NSString *key in [[response allHeaderFields] allKeys]) {
        NSLog(@"\t[Header]%@ = %@", key, [[response allHeaderFields] valueForKey:key]);
    }
}

- (void) logResponseBody:(NSData *)data {
    if (kEnableLogging == NO) return;

    NSString *stringData = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSLog(@"\tBody: %@", stringData);
}


/************************************************************************************
 ** Serialization Methods
 ************************************************************************************/

/**
 * Body append for POST method
 */
- (void)utfAppendBody:(NSMutableData *)body data:(NSString *)data {
    [body appendData:[data dataUsingEncoding:NSUTF8StringEncoding]];
}

/**
 * Generate body for POST method
 */
- (NSMutableData *)generatePostBody {
    NSMutableData *body = [NSMutableData data];
    NSString *endLine = [NSString stringWithFormat:@"\r\n--%@\r\n", kStringBoundary];
    NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionary];
    
    [self utfAppendBody:body data:[NSString stringWithFormat:@"--%@\r\n", kStringBoundary]];
    
    for (id key in [_params keyEnumerator]) {
        if (([[_params valueForKey:key] isKindOfClass:[UIImage class]])
            ||([[_params valueForKey:key] isKindOfClass:[NSData class]])) {
            
            [dataDictionary setObject:[_params valueForKey:key] forKey:key];
            continue;
        }
        
        [self utfAppendBody:body
                       data:[NSString
                             stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",
                             key]];
        [self utfAppendBody:body data:[_params valueForKey:key]];
        [self utfAppendBody:body data:endLine];
    }
    
    if ([dataDictionary count] > 0) {
        for (id key in dataDictionary) {
            NSObject *dataParam = [dataDictionary valueForKey:key];
            if ([dataParam isKindOfClass:[UIImage class]]) {
                NSData* imageData = UIImageJPEGRepresentation((UIImage*)dataParam, 1);
                [self utfAppendBody:body
                               data:[NSString stringWithFormat:
                                     @"Content-Disposition: form-data; filename=\"%@\"\r\n", key]];
                [self utfAppendBody:body
                               data:[NSString stringWithString:@"Content-Type: image/png\r\n\r\n"]];
                [body appendData:imageData];
            } else {
                NSAssert([dataParam isKindOfClass:[NSData class]],
                         @"dataParam must be a UIImage or NSData");
                [self utfAppendBody:body
                               data:[NSString stringWithFormat:
                                     @"Content-Disposition: form-data; filename=\"%@\"\r\n", key]];
                [self utfAppendBody:body
                               data:[NSString stringWithString:@"Content-Type: content/unknown\r\n\r\n"]];
                [body appendData:(NSData*)dataParam];
            }
            [self utfAppendBody:body data:endLine];
            
        }
    }
    
    return body;
}

/**
 * Formulate the NSError
 */
- (id)formError:(NSInteger)code userInfo:(NSDictionary *) errorData {
    return [NSError errorWithDomain:@"geniErrDomain" code:code userInfo:errorData];
}

/**
 * parse the response data
 */
- (id)parseJsonResponse:(NSData *)data error:(NSError **)error {
    NSString* responseString = [[[NSString alloc] initWithData:data
                                                      encoding:NSUTF8StringEncoding]
                                autorelease];
    SBJSON *jsonParser = [[SBJSON new] autorelease];
    id result = [jsonParser objectWithString:responseString];
    
    if (![result isKindOfClass:[NSArray class]]) {
        if ([result objectForKey:@"error"] != nil) {
            if (error != nil) {
                *error = [self formError:kGeneralErrorCode
                                userInfo:[result objectForKey:@"error"]];
            }
            return nil;
        }
    }
    
    return result;
}

/*
 * private helper function: call the delegate function when the request
 *                          fails with error
 */
- (void)failWithError:(NSError *)error {
    if ([_delegate respondsToSelector:@selector(request:didFailWithError:)]) {
        [_delegate request:self didFailWithError:error];
    }
}

/*
 * private helper function: handle the response data
 */
- (void)handleResponseData:(NSData *)data {
    [self logResponseBody:data];

    if ([_delegate respondsToSelector:
         @selector(request:didLoadRawResponse:)]) {
        [_delegate request:self didLoadRawResponse:data];
    }
    
    if ([_delegate respondsToSelector:@selector(request:didLoad:)] ||
        [_delegate respondsToSelector:
         @selector(request:didFailWithError:)]) {
            NSError* error = nil;
            id result = [self parseJsonResponse:data error:&error];
            
            if (error) {
                [self failWithError:error];
            } else if ([_delegate respondsToSelector:
                        @selector(request:didLoad:)]) {
                [_delegate request:self didLoad:(result == nil ? data : result)];
            }
            
        }
}

/************************************************************************************
 ** Public Methods
 ************************************************************************************/

/**
 * @return boolean - whether this request is processing
 */
- (BOOL)loading {
    return !!_connection;
}

/**
 * make the Geni request
 */
- (void)connect {
    if ([_delegate respondsToSelector:@selector(requestLoading:)]) {
        [_delegate requestLoading:self];
    }
    
    NSString* url = [[self class] serializeURL:_url params:_params httpMethod:_httpMethod];
    
    NSMutableURLRequest* request =
    [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                        timeoutInterval:kTimeoutInterval];
    [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
    
    [request setHTTPMethod:self.httpMethod];
    if ([self.httpMethod isEqualToString: @"POST"]) {
        NSString* contentType = [NSString
                                 stringWithFormat:@"multipart/form-data; boundary=%@", kStringBoundary];
        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        
        [request setHTTPBody:[self generatePostBody]];
    }
    
    [self logRequest:request];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

/************************************************************************************
 ** NSURLConnection Delegate Callbacks
 ************************************************************************************/

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _responseText = [[NSMutableData alloc] init];
    
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    [self logResponse:httpResponse];

    if ([_delegate respondsToSelector:
         @selector(request:didReceiveResponse:)]) {
        [_delegate request:self didReceiveResponse:httpResponse];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_responseText appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self handleResponseData:_responseText];
    
    [_responseText release];
    _responseText = nil;
    [_connection release];
    _connection = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self failWithError:error];
    
    [_responseText release];
    _responseText = nil;
    [_connection release];
    _connection = nil;
}

@end
