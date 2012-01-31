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

#import "LoginViewController.h"
#import "AppDelegate.h"

@implementation LoginViewController

- (IBAction) login:(id) sender {
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.geni authorize:self];
}

- (void)geniDidLogin {
    [self performSegueWithIdentifier:@"ShowFamily" sender:self];
}

- (void)geniDidNotLogin:(BOOL)cancelled {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Failed to authorize application." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}


@end
