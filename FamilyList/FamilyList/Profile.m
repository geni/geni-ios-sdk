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


#import "Profile.h"
#import "AppDelegate.h"

@implementation Profile
@synthesize delegate, indexPath, attributes;

+ (id) profileWithAttributes:(NSDictionary *) data {
    return [[Profile alloc] initWithAttributes:data];
}

- (id) initWithAttributes:(NSDictionary *) data {
    self = [super init];
    if (self) {
        self.attributes = [NSMutableDictionary dictionaryWithDictionary:data];
    }
    return self;
}

/************************************************************************************
 ** BASIC
 ************************************************************************************/

- (NSString *) name {
    if ([self.attributes objectForKey:@"name"] == nil) {
        return @"No Name";
    }
    return [self.attributes objectForKey:@"name"];
}

- (NSString *) relationship {
    if ([attributes objectForKey:@"relationship"] == nil) {
        return @"relative";
    }
    return [attributes objectForKey:@"relationship"];
}

/************************************************************************************
 ** MUGSHOT
 ************************************************************************************/

- (void) storeImage: (UIImage *) image {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *filePath = [[appDelegate photosPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.jpg", [attributes objectForKey:@"id"]]];
    NSData *imageData = UIImageJPEGRepresentation(image, 0);
    [imageData writeToFile:filePath atomically:YES];
}

- (UIImage *) mugshotImage {
    NSDictionary *mugshotUrls = [attributes valueForKey:@"mugshot_urls"];
    if (mugshotUrls == nil || [mugshotUrls valueForKey:@"large"] == nil) {
        return [self defaultMugshotImage];    
    }

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *filePath = [[appDelegate photosPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.jpg", [attributes objectForKey:@"id"]]];

    if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]) 
        return nil;
    
    return [UIImage imageWithData:[NSData dataWithContentsOfFile:filePath]];
}

- (UIImage *) defaultMugshotImage {
    return [UIImage imageNamed:[NSString stringWithFormat:@"%@.gif", [attributes valueForKey:@"gender"]]];    
}

- (GeniRequest *) loadMugshotImageAtIndexPath:(NSIndexPath *)newIndexPath delegate:(id <ProfileDelegate>) newDelegate {
    self.indexPath = newIndexPath;
    self.delegate = newDelegate;
    
    NSDictionary *mugshotUrls = [attributes valueForKey:@"mugshot_urls"];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    return [appDelegate.geni requestWithPath:[mugshotUrls valueForKey:@"large"] andDelegate:self];
}

- (void)request:(GeniRequest *)request didFailWithError:(NSError *)error {
    UIImage *image = [self defaultMugshotImage];
    [self storeImage: image];
    [delegate profile:self receivedMughshotImage:image atIndexPath:indexPath];
}

- (void)request:(GeniRequest *)request didLoadResponse:(GeniResponse *)response {
    UIImage *image = [response image];
    [self storeImage: image];
    [delegate profile:self receivedMughshotImage:image atIndexPath:indexPath];
}

@end
