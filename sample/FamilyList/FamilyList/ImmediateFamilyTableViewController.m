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

#import "ImmediateFamilyTableViewController.h"
#import "FamilyListAppDelegate.h"
#import "ProfileTableViewCell.h"

@implementation ImmediateFamilyTableViewController
@synthesize profile, sections;

- (void)dealloc {
    [profile release];
    [sections release];
    [super dealloc];
}

- (void) loadImmediateFamilyForProfile:(Profile *) newProfile {
    self.profile = newProfile;
    self.sections = [NSMutableArray array];
    self.title = [profile name];
    
    [self showLoadingView];
    
    FamilyListAppDelegate *appDelegate = (FamilyListAppDelegate*) [[UIApplication sharedApplication] delegate];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"id,first_name,last_name,name,gender,mugshot_urls,relationship", @"fields",
                                   nil];
    [appDelegate.geni requestWithPath:[NSString stringWithFormat:@"%@/immediate-family", [profile nodeId]] 
                            andParams:params andDelegate:self];
}

- (void)request:(GeniRequest *)request didLoad:(id)result {
    NSDictionary *data = (NSDictionary *) result;
    [profile parseImmediateFamily:[data objectForKey:@"nodes"]];
    self.sections = [profile familySections];
	[self.tableView reloadData];

    [self hideLoadingView];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *sectionInfo = [sections objectAtIndex:section];
    NSArray *sectionData = [sectionInfo objectForKey:@"data"];
    return [sectionData count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *sectionInfo = [sections objectAtIndex:section];
    return [sectionInfo objectForKey:@"title"];
}

- (Profile *) profileAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *sectionInfo = [sections objectAtIndex:indexPath.section];
    NSArray *sectionData = [sectionInfo objectForKey:@"data"];
    return (Profile *)[sectionData objectAtIndex: indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ProfileTableViewCell *cell = (ProfileTableViewCell*) [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.infoLabel.text = @"";
    return cell;
}

@end
