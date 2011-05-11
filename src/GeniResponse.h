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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GeniResponse : NSObject {
    NSHTTPURLResponse *_HTTPURLResponse;
    NSMutableData *_rawData;
    NSString *_stringBody;
    NSDictionary *_JSONBody;
}

@property(nonatomic, retain) NSHTTPURLResponse *HTTPURLResponse;
@property(nonatomic, retain) NSMutableData *rawData;
@property(nonatomic, retain) NSString *stringBody;
@property(nonatomic, retain) NSDictionary *JSONBody;

- (id) initWithHTTPURLResponse:(NSHTTPURLResponse *) response;
- (void) appendRawData:(NSData *)data;
- (id) parse:(NSError **)error;

- (BOOL) isHTML;
- (BOOL) isImage;
- (BOOL) isJSON;

- (NSString *) headerValueForKey:(NSString*) key;

- (id) objectForKey: (NSString *) key;
- (NSString *) valueForKey: (NSString *) key;

- (UIImage *) image;
- (NSArray *) results;
- (NSString *) nextPageURL;
- (NSString *) previousPageURL;

@end
