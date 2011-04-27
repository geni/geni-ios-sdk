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
#import "Model.h"
#import "GeniConnect.h"

@protocol ProfileDelegate;

@interface Profile : Model <GeniRequestDelegate> {
    id <ProfileDelegate> delegate;
    NSIndexPath *indexPath;
    
    NSMutableArray *partnerUnions;
    NSMutableArray *parentUnions;
}

@property(nonatomic, assign) id <ProfileDelegate> delegate;
@property(nonatomic, retain) NSIndexPath *indexPath;

@property(nonatomic, retain) NSArray *partnerUnions;
@property(nonatomic, retain) NSArray *parentUnions;

+ (id) profileWithAttributes:(NSDictionary *) data;

- (NSString *) name;
- (NSString *) nameSortString;
- (NSString *) relationship;

- (void) parseImmediateFamily:(NSDictionary *) familyData;
- (NSArray *) familySections;

- (UIImage *) mugshotImage;
- (void) loadMugshotImageAtIndexPath:(NSIndexPath *)newIndexPath delegate:(id <ProfileDelegate>) newDelegate; 

@end


@protocol ProfileDelegate <NSObject>

-(void) profile:(Profile *) profile receivedMughshotImage:(UIImage *) image atIndexPath:(NSIndexPath *) indexPath;
-(void) profile:(Profile *) profile didNotReceivedMughshotImageAtIndexPath:(NSIndexPath *) indexPath;

@end