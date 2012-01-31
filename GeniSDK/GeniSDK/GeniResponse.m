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

#import "GeniResponse.h"
#import "SBJson.h"

static const int kGeneralResponseErrorCode = 10000;

@implementation GeniResponse

@synthesize rawData, httpURLResponse, jsonBody, stringBody;


/************************************************************************************
 ** Logging Methods (Debug)
 ************************************************************************************/

- (void) logResponse:(NSHTTPURLResponse *)response {
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
    NSString *stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"\tBody: %@", stringData);
}

/************************************************************************************
 ** Public Methods
 ************************************************************************************/

- (id) initWithHTTPURLResponse:(NSHTTPURLResponse *) response {
    self = [super init];
    if (self) {
        self.httpURLResponse = response;
        [self logResponse: response];
    }
    return self;
}

- (void) appendRawData:(NSData *)data {
    if (self.rawData == nil) {
        self.rawData = [[NSMutableData alloc] init];
    }
    [self.rawData appendData:data];    
}

- (id) parse:(NSError **)error {
    [self logResponseBody: self.rawData];
    
    self.stringBody = [[NSString alloc] initWithData:self.rawData encoding:NSUTF8StringEncoding];
    SBJsonParser *jsonParser = [SBJsonParser new];
    id result = [jsonParser objectWithString:self.stringBody];
    
    if ([result isKindOfClass:[NSDictionary class]]) {
        self.jsonBody = result;
        if ([result objectForKey:@"error"] != nil) {
            if (error != nil) {
                *error = [NSError errorWithDomain:@"PlatformErrorDomain" code:kGeneralResponseErrorCode userInfo:[result objectForKey:@"error"]];
            }
            return nil;
        }
    }
    return result;
}


- (BOOL) isHTML {
	NSRange range = [[self.httpURLResponse MIMEType] rangeOfString: @"html"];
	return (range.length != 0);
}

- (BOOL) isImage {
	NSRange range = [[self.httpURLResponse MIMEType] rangeOfString: @"image"];
	return (range.length != 0);
}

- (BOOL) isJSON {
	NSRange range = [[self.httpURLResponse MIMEType] rangeOfString: @"json"];
	return (range.length != 0);
}

- (NSString *) headerValueForKey:(NSString*) key {
    return [[self.httpURLResponse allHeaderFields] objectForKey:key];
}

- (UIImage *) image {
    if (![self isImage]) return nil;
    return [UIImage imageWithData:self.rawData];
}

- (id) objectForKey: (NSString *) key {
    return [self.jsonBody objectForKey:key];
}

- (NSString *) valueForKey: (NSString *) key {
    return (NSString *) [self objectForKey: key];
}

- (NSArray *) results {
    return [self objectForKey:@"results"];
}

- (NSString *) nextPageURL {
    return [self valueForKey:@"next_page"];
}

- (NSString *) previousPageURL {
    return [self valueForKey:@"previous_page"];
}


@end
