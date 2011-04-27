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

#import "Profile.h"
#import "Union.h"
#import "FamilyListAppDelegate.h"

@implementation Profile
@synthesize delegate, indexPath;
@synthesize parentUnions, partnerUnions;

- (void)dealloc {
    [parentUnions release];
    [partnerUnions release];
    [indexPath release];
    [super dealloc];
}

+ (id) profileWithAttributes:(NSDictionary *) data {
    return [[[Profile alloc] initWithAttributes:data] autorelease];
}

/************************************************************************************
 ** BASIC
 ************************************************************************************/

- (NSString *) name {
    if ([attributes objectForKey:@"name"] == nil) {
        return @"No Name";
    }
    return [attributes objectForKey:@"name"];
}

- (NSString *) nameSortString {
    NSMutableString *sortString = [NSMutableString string];
    if ([attributes objectForKey:@"last_name"] == nil) {
        [sortString appendString:@""];
    } else {
        [sortString appendString:[attributes objectForKey:@"last_name"]];
    }
    
    [sortString appendString:@"ZZZZZZZZZZZZZ"];
    
    if ([attributes objectForKey:@"first_name"] == nil) {
        [sortString appendString:@"ZZZZZZZZZZZZZ"];
    } else {
        [sortString appendString:[attributes objectForKey:@"first_name"]];
    }
    
    return sortString;
}

- (NSString *) relationship {
    if ([attributes objectForKey:@"relationship"] == nil) {
        return @"No Relationship";
    }
    return [attributes objectForKey:@"relationship"];
}

/************************************************************************************
 ** IMMEDIATE FAMILY
 ************************************************************************************/

- (void) parseImmediateFamily:(NSDictionary *) familyData {
    self.parentUnions = [NSMutableArray array];
    self.partnerUnions = [NSMutableArray array];
    
    NSDictionary *myNode = [familyData objectForKey:[self nodeId]];
    
    NSDictionary *edges = [myNode objectForKey:@"edges"];
    if (edges == NULL) return;
    
    for (NSString *unionKey in edges.allKeys) {
        NSDictionary *familyUnion = [edges objectForKey:unionKey];
        Union *fUn = [Union unionWithAttributes: [NSDictionary dictionaryWithObjectsAndKeys: unionKey, @"nodeId", nil]];
        
        NSString *rel = [familyUnion objectForKey: @"rel"];
        
        if ([rel isEqualToString:@"partner"])  {
            [partnerUnions addObject:fUn];
        } else {
            [parentUnions addObject:fUn];
        }
        
        NSDictionary *unionData = [familyData objectForKey:unionKey];
        if (unionData == NULL) continue;
        
        NSDictionary *unionEdges = [unionData objectForKey:@"edges"];
        if (unionEdges == NULL) continue;
        
        for (NSString *unionProfileNodeId in unionEdges.allKeys) {
            NSDictionary *unionProfileRel = [unionEdges objectForKey:unionProfileNodeId];
            
            NSDictionary *unionProfileJSON = [familyData objectForKey:unionProfileNodeId];
            Profile *profile = [Profile profileWithAttributes:unionProfileJSON];
            
            if ([[unionProfileRel objectForKey: @"rel"] isEqualToString:@"partner"]) { 
                [fUn addPartner:profile];
            } else {
                [fUn addChild:profile];
            }
        }
    }
}

- (NSMutableArray *) parentsSectionData {
    NSMutableArray *profiles = [NSMutableArray array];
    if (parentUnions == NULL) return profiles;
    
    for (Union *fUn in parentUnions) {
        if (fUn.partners == NULL) continue;
        [profiles addObjectsFromArray:fUn.partners];
    }
    
    return profiles;
}

- (NSMutableArray *) partnersSectionData {
    NSMutableArray *profiles = [NSMutableArray array];
    if (partnerUnions == NULL) return profiles;
    
    for (Union *fUn in partnerUnions) {
        if (fUn.partners == NULL) continue;
        for (Profile *partner in fUn.partners) {
            if ([[partner nodeId] isEqualToString:[self nodeId]]) continue;
            [profiles addObject:partner];
        }
    }
    
    return profiles;
}

- (NSMutableArray *) childrenSectionData {
    NSMutableArray *profiles = [NSMutableArray array];
    if (partnerUnions == NULL) return profiles;
    
    for (Union *fUn in partnerUnions) {
        if (fUn.children == NULL) continue;
        [profiles addObjectsFromArray:fUn.children];
    }
    
    return profiles;    
}

- (NSMutableArray *) siblingsSectionData {
    NSMutableArray *profiles = [NSMutableArray array];
    if (parentUnions == NULL) return profiles;
    
    for (Union *fUn in parentUnions) {
        if (fUn.children == NULL) continue;
        for (Profile *child in fUn.children) {
            if ([[child nodeId] isEqualToString:[self nodeId]]) continue;
            [profiles addObject:child];
        }
    }
    
    return profiles; 
}

- (NSArray *) familySections {
    NSMutableArray *sections = [NSMutableArray array];
    
    NSMutableArray *sectionData = [self parentsSectionData];
    if ([sectionData count] > 0) [sections addObject: [NSDictionary dictionaryWithObjectsAndKeys: sectionData, @"data", @"Parents", @"title", nil]];
    
    sectionData = [self partnersSectionData];
    if ([sectionData count] > 0) [sections addObject: [NSDictionary dictionaryWithObjectsAndKeys: sectionData, @"data", @"Spouses", @"title", nil]];
    
    sectionData = [self childrenSectionData];
    if ([sectionData count] > 0) [sections addObject: [NSDictionary dictionaryWithObjectsAndKeys: sectionData, @"data", @"Children", @"title", nil]];
    
    sectionData = [self siblingsSectionData];
    if ([sectionData count] > 0) [sections addObject: [NSDictionary dictionaryWithObjectsAndKeys: sectionData, @"data", @"Siblings", @"title", nil]];
    
    return sections;    
}

/************************************************************************************
 ** MUGSHOT
 ************************************************************************************/

- (UIImage *) mugshotImage {
    FamilyListAppDelegate *appDelegate = (FamilyListAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *filePath = [[appDelegate photosPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.jpg", [attributes objectForKey:@"id"]]];

    NSDictionary *mugshotUrls = [attributes valueForKey:@"mugshot_urls"];
    if (mugshotUrls == nil || [mugshotUrls valueForKey:@"large"] == nil) {
        return [UIImage imageNamed:[NSString stringWithFormat:@"photo_silhouette_%@.gif", [attributes valueForKey:@"gender"]]];    
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager]; 
    if(![fileManager fileExistsAtPath:filePath]) 
        return nil;
    
    return [UIImage imageWithData:[NSData dataWithContentsOfFile:filePath]];
}

- (void) loadMugshotImageAtIndexPath:(NSIndexPath *)newIndexPath delegate:(id <ProfileDelegate>) newDelegate {
    self.indexPath = newIndexPath;
    self.delegate = newDelegate;
    
    NSDictionary *mugshotUrls = [attributes valueForKey:@"mugshot_urls"];
    FamilyListAppDelegate *appDelegate = (FamilyListAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.geni requestWithPath:[mugshotUrls valueForKey:@"large"] andDelegate:self];
}

- (void)request:(GeniRequest *)request didFailWithError:(NSError *)error {
    [delegate profile:self didNotReceivedMughshotImageAtIndexPath:indexPath];
}

- (void)request:(GeniRequest *)request didLoad:(id)result {
    UIImage *resultImage = [UIImage imageWithData:(NSData *)result];
    FamilyListAppDelegate *appDelegate = (FamilyListAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *filePath = [[appDelegate photosPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.jpg", [attributes objectForKey:@"id"]]];
    NSData *imageData = UIImageJPEGRepresentation(resultImage, 0);
    [imageData writeToFile:filePath atomically:YES];
    [delegate profile:self receivedMughshotImage:resultImage atIndexPath:indexPath];
}

@end
