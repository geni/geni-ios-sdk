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

#import "GeniRequest.h"

/************************************************************************************
 ** Constants
 ************************************************************************************/

static NSString* kUserAgent = @"iPhone";
static NSString* kStringBoundary = @"GeniPostBoundary";
static const int kGeneralErrorCode = 10000;

static const BOOL kEnableLogging = YES;

static const NSTimeInterval kTimeoutInterval = 180.0;

/************************************************************************************
 ** Implementation
 ************************************************************************************/

@implementation GeniRequest

@synthesize delegate, url, httpMethod, params, connection, response;


/************************************************************************************
 ** Class Public Mehtods
 ************************************************************************************/

+ (GeniRequest *) requestWithParams:(NSMutableDictionary *) params
                         httpMethod:(NSString *) httpMethod
                           delegate:(id<GeniRequestDelegate>) delegate
                         requestURL:(NSString *) url {
    
    GeniRequest *request = [[GeniRequest alloc] init];
    request.delegate = delegate;
    request.url = url;
    request.httpMethod = httpMethod;
    request.params = params;
    request.connection = nil;
    request.response = nil;
    
    return request;
}

/************************************************************************************
 ** Private Methods
 ************************************************************************************/
+ (NSString *)serializeURL:(NSString *)baseUrl params:(NSDictionary *)params {
    return [self serializeURL:baseUrl params:params httpMethod:@"GET"];
}

/**
 * Generate GET Query
 */
+ (NSString*)serializeParams:(NSDictionary *)params {
    NSMutableArray* pairs = [NSMutableArray array];
    for (NSString* key in [params keyEnumerator]) {
        if (([[params valueForKey:key] isKindOfClass:[UIImage class]])
            ||([[params valueForKey:key] isKindOfClass:[NSData class]])) {
            continue;
        }
        
        NSString* escaped_value = [[params objectForKey:key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
    }
    return [pairs componentsJoinedByString:@"&"];
}

/**
 * Generate GET URL
 */
+ (NSString*)serializeURL:(NSString *)baseUrl params:(NSDictionary *)params httpMethod:(NSString *)httpMethod {
    if ([httpMethod isEqualToString:@"POST"]) return baseUrl;
    
    NSURL* parsedURL = [NSURL URLWithString:baseUrl];
    NSString* queryPrefix = parsedURL.query ? @"&" : @"?";
    NSString* query = [self serializeParams:params];
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
        NSString *stringData = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
        NSLog(@"\tBody: %@", stringData);
    }
    
    for (NSString *key in [[request allHTTPHeaderFields] allKeys]) {
        NSLog(@"\t[Header]%@ = %@", key, [[request allHTTPHeaderFields] valueForKey:key]);
    }
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
- (void) generatePostBodyForRequest:(NSMutableURLRequest*) request {
    NSMutableData *body = [NSMutableData data];
    NSString *endLine = [NSString stringWithFormat:@"\r\n--%@\r\n", kStringBoundary];
    NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionary];
    
    [self utfAppendBody:body data:[NSString stringWithFormat:@"--%@\r\n", kStringBoundary]];
    
    for (id key in [self.params keyEnumerator]) {
        if (([[self.params valueForKey:key] isKindOfClass:[UIImage class]]) || ([[self.params valueForKey:key] isKindOfClass:[NSData class]])) {
            [dataDictionary setObject:[self.params valueForKey:key] forKey:key];
            continue;
        }
        
        [self utfAppendBody:body data:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key]];
        [self utfAppendBody:body data:[self.params valueForKey:key]];
        [self utfAppendBody:body data:endLine];
    }
    
    if ([dataDictionary count] == 0) {
        [request setHTTPBody:[[[self class] serializeParams: self.params] dataUsingEncoding:NSUTF8StringEncoding]];
        return;
    }
    
    for (id key in dataDictionary) {
        NSObject *dataParam = [dataDictionary valueForKey:key];
        if ([dataParam isKindOfClass:[UIImage class]]) {
            NSData* imageData = UIImageJPEGRepresentation((UIImage*)dataParam, 1);
            [self utfAppendBody:body data:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, @"image.jpg"]];
            [self utfAppendBody:body data:[NSString stringWithString:@"Content-Type: image/jpeg\r\n\r\n"]];
            [body appendData:imageData];
        } else {
            NSAssert([dataParam isKindOfClass:[NSData class]], @"dataParam must be a UIImage or NSData");
            [self utfAppendBody:body data:[NSString stringWithFormat:@"Content-Disposition: form-data; filename=\"%@\"\r\n", key]];
            [self utfAppendBody:body data:[NSString stringWithString:@"Content-Type: content/unknown\r\n\r\n"]];
            [body appendData:(NSData*)dataParam];
        }
        [self utfAppendBody:body data:endLine];
    }
    
    //    unsigned char aBuffer[[body length]];
    //    [body getBytes:aBuffer length:[body length]];
    //    NSLog(@"%s", aBuffer);    
    
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", kStringBoundary] forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:body];
}


/**
 * Formulate the NSError
 */
- (id)formError:(NSInteger)code userInfo:(NSDictionary *) errorData {
    return [NSError errorWithDomain:@"GeniErrorDomain" code:code userInfo:errorData];
}

/*
 * private helper function: call the delegate function when the request
 *                          fails with error
 */
- (void)failWithError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if ([self.delegate respondsToSelector:@selector(request:didFailWithError:)]) {
        [self.delegate request:self didFailWithError:error];
    }
}

/************************************************************************************
 ** Public Methods
 ************************************************************************************/

/**
 * @return boolean - whether this request is processing
 */
- (BOOL) lsLoading {
    return !!self.connection;
}

/**
 * make the Geni request
 */

- (void )connect {
    if ([self.delegate respondsToSelector:@selector(geniRequestIsLoading:)]) {
        [self.delegate geniRequestIsLoading:self];
    }
    
    NSString* reqUrl = [[self class] serializeURL:self.url params:self.params httpMethod: self.httpMethod];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString:reqUrl]
                                                           cachePolicy: NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval: kTimeoutInterval];
    
    [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
    [request setHTTPMethod:self.httpMethod];
    
    if ([self.httpMethod isEqualToString: @"POST"]) {
        [self generatePostBodyForRequest: request];
    }
    
    [self logRequest:request];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void) cancel {
    [self.connection cancel];
}

/************************************************************************************
 ** NSURLConnection Delegate Callbacks
 ************************************************************************************/

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)urlResponse {
    self.response = [[GeniResponse alloc] initWithHTTPURLResponse:(NSHTTPURLResponse*)urlResponse];
    
    if ([self.delegate respondsToSelector: @selector(request:didReceiveResponse:)]) {
        [self.delegate request:self didReceiveResponse:self.response];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.response appendRawData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if ([self.delegate respondsToSelector: @selector(request:didLoadRawResponse:)]) {
        [self.delegate request:self didLoadRawResponse:self.response.rawData];
    }
    
    if ([self.delegate respondsToSelector: @selector(request:didLoadResponse:)] || [self.delegate respondsToSelector: @selector(request:didFailWithError:)]) {
        NSError* error = nil;
        [self.response parse:&error];
        
        if (error) {
            [self failWithError:error];
        } else if ([self.delegate respondsToSelector: @selector(request:didLoadResponse:)]) {
            [self.delegate request:self didLoadResponse: self.response];
        }
    }
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    self.response = nil;
    self.connection = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self failWithError:error];
    self.response = nil;
    self.connection = nil;
}

@end
