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

#import "FamilyListTableViewController.h"
#import "FamilyListAppDelegate.h"
#import "Profile.h"
#import "ProfileTableViewCell.h"

@implementation FamilyListTableViewController
@synthesize profiles;

- (void)dealloc {
    [profiles release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Family List";
    self.profiles = [NSMutableArray array];
    
    UIBarButtonItem *accountButton = [[UIBarButtonItem alloc] initWithTitle:@"Account" style:UIBarButtonItemStyleBordered target:self action:@selector(showAccountOptions)];
    self.navigationItem.leftBarButtonItem = accountButton;
    [accountButton release];

    UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(loadFamilyList)];
    self.navigationItem.rightBarButtonItem = reloadButton;
    [reloadButton release];
}

- (void) showAccountOptions {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Account Options" delegate:self 
                                                    cancelButtonTitle:@"Cancel" 
                                               destructiveButtonTitle: NULL 
                                                    otherButtonTitles: @"Logout", nil];
    [actionSheet showInView:self.view];
    [actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    FamilyListAppDelegate *appDelegate = (FamilyListAppDelegate*) [[UIApplication sharedApplication] delegate];
    
    if (buttonIndex == 0) {
        [appDelegate logout];
        return;
    }
}

- (void) loadFamilyList {
    [self showLoadingView];
    
    self.profiles = [NSMutableArray array];

    FamilyListAppDelegate *appDelegate = (FamilyListAppDelegate*) [[UIApplication sharedApplication] delegate];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"1",        @"only_list",    
                                   @"id,first_name,last_name,name,gender,mugshot_urls,relationship", @"fields",
                                   nil];
    [appDelegate.geni requestWithPath:@"user/max-family" andParams:params andDelegate:self];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.profiles = nil;
}

- (void)request:(GeniRequest *)request didLoad:(id)result {
    FamilyListAppDelegate *appDelegate = (FamilyListAppDelegate*) [[UIApplication sharedApplication] delegate];

    NSDictionary *data = (NSDictionary *) result;
    
	NSArray *family = [data objectForKey:@"results"];
	for (NSDictionary *profile in family) {
        [profiles addObject:[Profile profileWithAttributes: profile]];
	}

    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor1, nil];
    [self.profiles sortUsingDescriptors:sortDescriptors];
	[self.tableView reloadData];
    
	NSString *nextPageUrl = [data objectForKey:@"next_page"];
	if (nextPageUrl != nil) {
        [appDelegate.geni requestWithPath:nextPageUrl andDelegate:self];
	} else {
        [self hideLoadingView];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [profiles count];
}

- (Profile *) profileAtIndexPath:(NSIndexPath *)indexPath {
    return (Profile *)[profiles objectAtIndex:indexPath.row];
}

#pragma mark - Table view delegate


@end
