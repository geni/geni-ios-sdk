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
#import "Profile.h"

@interface Union : Model {
    NSMutableArray *partners;
    NSMutableArray *children;
}

+ (id) unionWithAttributes:(NSDictionary *) data;

@property(nonatomic, retain) NSMutableArray *partners;
@property(nonatomic, retain) NSMutableArray *children;

- (void) addChild: (Profile *) child;
- (void) addPartner: (Profile *) partner;

@end
