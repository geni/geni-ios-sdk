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

#import "GeniResponse.h"
#import "JSON.h"

static const int kGeneralResponseErrorCode = 10000;

@implementation GeniResponse

@synthesize rawData = _rawData;
@synthesize HTTPURLResponse = _HTTPURLResponse;
@synthesize JSONBody = _JSONBody;
@synthesize stringBody = _stringBody;

/**
 * Free internal structure
 */
- (void)dealloc {
    [_rawData release];
    [_HTTPURLResponse release];
    [_JSONBody release];
    [_stringBody release];
    [super dealloc];
}

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
    NSString *stringData = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSLog(@"\tBody: %@", stringData);
}

/************************************************************************************
 ** Public Methods
 ************************************************************************************/

- (id) initWithHTTPURLResponse:(NSHTTPURLResponse *) response {
    self = [super init];
    if (self) {
        self.HTTPURLResponse = response;
        [self logResponse: response];
    }
    return self;
}

- (void) appendRawData:(NSData *)data {
    if (_rawData == nil) {
        _rawData = [[NSMutableData alloc] init];
    }
    [_rawData appendData:data];    
}

- (id) parse:(NSError **)error {
    [self logResponseBody:_rawData];
    
    _stringBody = [[NSString alloc] initWithData:_rawData encoding:NSUTF8StringEncoding];
    SBJSON *jsonParser = [[SBJSON new] autorelease];
    id result = [jsonParser objectWithString:_stringBody];
    
    if ([result isKindOfClass:[NSDictionary class]]) {
        self.JSONBody = result;
        if ([result objectForKey:@"error"] != nil) {
            if (error != nil) {
                *error = [NSError errorWithDomain:@"GeniErrorDomain" code:kGeneralResponseErrorCode userInfo:[result objectForKey:@"error"]];
            }
            return nil;
        }
    }
    return result;
}

- (BOOL) isHTML {
	NSRange range = [[self.HTTPURLResponse MIMEType] rangeOfString: @"html"];
	return (range.length != 0);
}

- (BOOL) isImage {
	NSRange range = [[self.HTTPURLResponse MIMEType] rangeOfString: @"image"];
	return (range.length != 0);
}

- (BOOL) isJSON {
	NSRange range = [[self.HTTPURLResponse MIMEType] rangeOfString: @"json"];
	return (range.length != 0);
}

- (NSString *) headerValueForKey:(NSString*) key {
    return [[self.HTTPURLResponse allHeaderFields] objectForKey:key];
}

- (UIImage *) image {
    if (![self isImage]) return nil;
    return [UIImage imageWithData:self.rawData];
}

- (id) objectForKey: (NSString *) key {
    return [[self JSONBody] objectForKey:key];
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
