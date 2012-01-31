/*
 * Copyright 2011-2012 Geni
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
#import "GeniSDK.h"

@protocol ProfileDelegate;

@interface Profile : NSObject <GeniRequestDelegate> {
}

@property(nonatomic, retain) NSMutableDictionary *attributes;
@property(nonatomic, assign) id <ProfileDelegate> delegate;
@property(nonatomic, retain) NSIndexPath *indexPath;

- (id) initWithAttributes:(NSDictionary *) data;
+ (id) profileWithAttributes:(NSDictionary *) data;

- (NSString *) name;
- (NSString *) relationship;
- (UIImage *) mugshotImage;
- (UIImage *) defaultMugshotImage;
- (GeniRequest *) loadMugshotImageAtIndexPath:(NSIndexPath *)newIndexPath delegate:(id <ProfileDelegate>) newDelegate; 

@end


@protocol ProfileDelegate <NSObject>

-(void) profile:(Profile *) profile receivedMughshotImage:(UIImage *) image atIndexPath:(NSIndexPath *) indexPath;

@end