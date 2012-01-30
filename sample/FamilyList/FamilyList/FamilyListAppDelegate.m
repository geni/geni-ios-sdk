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

#import "FamilyListAppDelegate.h"

/*
 Visit http://www.geni.com/apps and register your application. Then provide the following values:
*/

static NSString* kApplicationId = @"YOUR APPLICATION ID";

@implementation FamilyListAppDelegate

@synthesize window=_window;
@synthesize geni=_geni;
@synthesize loginViewController = _loginViewController;
@synthesize familyListNavigationController = _familyListNavigationController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	NSString *accessToken = [[NSUserDefaults standardUserDefaults] stringForKey: @"accessToken"];	
	_geni = [[Geni alloc] initWithAppId:kApplicationId];
    _geni.accessToken = accessToken;
    
    _loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
    [self.window addSubview:_loginViewController.view];
    [self.window makeKeyAndVisible];
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [self.geni handleOpenURL:url];
}

- (void) login {
    [self.geni authorize:self];
}

- (void) validate {
    [self.geni validate:self];
}

- (void) logout {
    [self.geni logout:self];
}

- (void) animateFromController:(UIViewController*) from toController: (UIViewController*) to transition: (UIViewAnimationTransition) transition {
    to.view.frame = CGRectMake(0, 20, 320, 460);
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1];
	
	[UIView setAnimationTransition:transition forView:self.window cache:YES];
	
	[to viewWillAppear:YES];
	[from viewWillDisappear:YES];
	
	[from.view removeFromSuperview];
	[self.window addSubview:to.view];
	
	[from viewDidDisappear:YES];
	[to viewDidAppear:YES];
	
	[UIView commitAnimations];  
}

- (void)geniDidLogin {
	[[NSUserDefaults standardUserDefaults] setObject:self.geni.accessToken forKey:@"accessToken"];
    
    if (_familyListNavigationController == nil) {
       FamilyListTableViewController *familyListTableViewController = [[FamilyListTableViewController alloc] initWithNibName:@"FamilyListTableViewController" bundle:nil];
        _familyListNavigationController = [[UINavigationController alloc] initWithRootViewController:familyListTableViewController];
        [familyListTableViewController loadFamilyList];
        [familyListTableViewController release];
    }
    
    [self animateFromController:_loginViewController toController: _familyListNavigationController transition: UIViewAnimationTransitionFlipFromRight];
}

- (void)geniDidNotLogin:(BOOL)cancelled {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"accessToken"];
    [_loginViewController failedToLogin];   
}

- (void)geniDidLogout {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"accessToken"];
    [self animateFromController:_familyListNavigationController toController: _loginViewController transition: UIViewAnimationTransitionFlipFromLeft];
}

- (NSString *) photosPath {
    if (_photosPath == NULL) {
        NSFileManager *fileManager = [NSFileManager defaultManager]; 
        _photosPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        _photosPath = [[_photosPath stringByAppendingPathComponent:@"/Photos"] retain];
        
        NSError *error;
        if(![fileManager fileExistsAtPath:_photosPath]) {
            NSLog(@"Creating cached images dir: %@", _photosPath);
            if(![fileManager createDirectoryAtPath:_photosPath withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"Failed to create cache folder: %@", [error localizedDescription]);
            }
        }
    }
    return _photosPath;
}

- (void)dealloc {
    [_geni release];
    [_window release];
    [_familyListNavigationController release];
    [_loginViewController release];
    [super dealloc];
}

@end
