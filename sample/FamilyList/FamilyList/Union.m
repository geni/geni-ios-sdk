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

#import "Union.h"

@implementation Union
@synthesize partners, children;

- (void)dealloc {
    [partners release];
    [children release];
    [super dealloc];
}

+ (id) unionWithAttributes:(NSDictionary *) data {
    return [[[Union alloc] initWithAttributes:data] autorelease];
}

- (id)initWithAttributes: (NSDictionary *) data {
    self = [super initWithAttributes:data];
    
    if (self) {
        self.partners = [NSMutableArray array];
        self.children = [NSMutableArray array];
    }
	return self;
}

- (void) addChild: (Profile *) child {
    if (children == NULL)
        self.children = [NSMutableArray array];
        
    [children addObject:child];
}

- (void) addPartner: (Profile *) partner {
    if (partners == NULL)
        self.partners = [NSMutableArray array];

    [partners addObject:partner];
}

@end
