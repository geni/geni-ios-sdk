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

static NSString* kApplicationId = @"YOUR APPLICATION ID";

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize geni;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	self.geni = [[Geni alloc] initWithAppId:kApplicationId];
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [self.geni handleOpenURL:url];
}

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSString *) photosPath {
    if (photosPath_ == NULL) {
        NSFileManager *fileManager = [NSFileManager defaultManager]; 
        photosPath_ = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        photosPath_ = [photosPath_ stringByAppendingPathComponent:@"/Photos"];
        
        NSError *error;
        if(![fileManager fileExistsAtPath:photosPath_]) {
            if(![fileManager createDirectoryAtPath:photosPath_ withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"Failed to create cache folder: %@", [error localizedDescription]);
            }
        }
    }
    
    return photosPath_;
}

@end
