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

#import "GeniTableViewController.h"
#import "ProfileTableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "ImmediateFamilyTableViewController.h"

@implementation GeniTableViewController

@synthesize tableView=_tableView;
@synthesize loadingView=_loadingView;

- (void)dealloc {
    [_tableView release];
    [_loadingView release];
    [super dealloc];
}

- (void) showLoadingView {
    if (_loadingView == nil) {
        _loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 460)];
        _loadingView.backgroundColor = [UIColor whiteColor];
        _loadingView.alpha = 0.8;
        
        UIView *internalView = [[[UIView alloc] initWithFrame:CGRectMake(20, 130, 280, 105)] autorelease];
        internalView.layer.cornerRadius = 20;
        internalView.backgroundColor = [UIColor blackColor];
        [_loadingView addSubview:internalView];
        
        UIActivityIndicatorView *activityView = [[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(80, 44, 20, 20)] autorelease];
        [activityView startAnimating];
        [internalView addSubview:activityView];
        
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(115, 43, 152, 21)] autorelease];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        label.text = @"Loading...";
        [internalView addSubview:label];
        
        [self.view addSubview:_loadingView];
    }
    
    [_loadingView setHidden:NO];
}

- (void) hideLoadingView {
    [_loadingView setHidden:YES];
}

// Sould be overloaded by the extending class
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 0;
}

// Sould be overloaded by the extending class
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

// Sould be overloaded by the extending class
- (Profile *) profileAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 52;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ProfileCell";
    
    ProfileTableViewCell *cell = (ProfileTableViewCell*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[ProfileTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    Profile *profile = [self profileAtIndexPath:indexPath];
    cell.nameLabel.text = [profile name];
    cell.infoLabel.text = [profile relationship];
    
    UIImage *image = [profile mugshotImage];    
    if (image) {
        [cell updateWithImage: image];
    } else {
        [cell markAsLoading];
        [profile loadMugshotImageAtIndexPath: indexPath delegate: self];
    }
    
    return cell;
}

-(void) profile:(Profile *) profile receivedMughshotImage:(UIImage *) image atIndexPath:(NSIndexPath *) indexPath {
    ProfileTableViewCell *cell = (ProfileTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
    [cell updateWithImage: image];
}

-(void) profile:(Profile *) profile didNotReceivedMughshotImageAtIndexPath:(NSIndexPath *) indexPath {
    ProfileTableViewCell *cell = (ProfileTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
    [cell updateWithNoImage];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Profile *profile = [self profileAtIndexPath:indexPath];
    
    ImmediateFamilyTableViewController *controller = [[ImmediateFamilyTableViewController alloc] initWithNibName:@"ImmediateFamilyTableViewController" bundle:nil];
    [controller loadImmediateFamilyForProfile:profile];
     
    [self.navigationController pushViewController:controller animated:YES];
}

@end
