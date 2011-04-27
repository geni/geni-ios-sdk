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

#import "LoginViewController.h"
#import "FamilyListAppDelegate.h"
#import <QuartzCore/QuartzCore.h>

@implementation LoginViewController
@synthesize authView;

- (void)dealloc {
    [authView release];
    [super dealloc];
}

- (IBAction) loginToGeni:(id) sender {
    FamilyListAppDelegate *appDelegate = (FamilyListAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate login];
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    authView.layer.cornerRadius = 20;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    FamilyListAppDelegate *appDelegate = (FamilyListAppDelegate*)[[UIApplication sharedApplication] delegate];

    if ([appDelegate.geni isAccessTokenPresent]) {
        authView.hidden = NO;
        [appDelegate validate];
    } else {
        authView.hidden = YES;
    }
}

- (void) failedToLogin {
    authView.hidden = YES;
}

@end
