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

#import "FamilyViewController.h"
#import "FamilyTableViewCell.h"
#import "AppDelegate.h"
#import "Profile.h"

@implementation FamilyViewController
@synthesize tableView=_tableView, footerItem, profiles, imageRequests;

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self loadFamily];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.profiles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"FamilyTableViewCell";
    FamilyTableViewCell *cell = (FamilyTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[FamilyTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    Profile *p = [self.profiles objectAtIndex:indexPath.row];    
    UIImage *image = [p mugshotImage];
    cell.nameLabel.text = [p name];
    cell.relLabel.text = [p relationship];
    if (image) {
        cell.mugshotView.image = image;
    } else {
        cell.mugshotView.image = [p defaultMugshotImage];
    }
    
    return cell;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.profiles = nil;
}

- (void) loadFamily {
    self.profiles = [NSMutableArray array];
    
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"1",        @"only_list",    
                                   @"id,first_name,last_name,name,gender,mugshot_urls,relationship", @"fields",
                                   nil];
    [appDelegate.geni requestWithPath:@"user/max-family" andParams:params andDelegate:self];
}


- (void)request:(GeniRequest *)request didLoadResponse:(GeniResponse *)response {
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    
	NSArray *family = [response results];
	for (NSDictionary *profile in family) {
        [profiles addObject:[Profile profileWithAttributes: profile]];
	}
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [self.profiles sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	[self.tableView reloadData];
    
	NSString *nextPageUrl = [response nextPageURL];
	if (nextPageUrl != nil) {
        [appDelegate.geni requestWithPath:nextPageUrl andDelegate:self];
    }
    
    self.footerItem.title = [NSString stringWithFormat:@"%d relatives", [self.profiles count]];
}

- (NSString *) keyForIndexPath: (NSIndexPath *) indexPath {
    return [NSString stringWithFormat:@"%d,%d", indexPath.section, indexPath.row];
}

- (void) loadImagesForOnscreenRows {
    if ([self.profiles count] == 0) return;
    
    if (self.imageRequests == nil) 
        self.imageRequests = [NSMutableDictionary dictionary];
    
    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths) {
        Profile *profile = [self.profiles objectAtIndex:indexPath.row];
        UIImage *image = [profile mugshotImage];
        NSString *reqKey = [self keyForIndexPath:indexPath];
        if (image == nil && [imageRequests objectForKey:reqKey] == nil) {
            GeniRequest *req = [profile loadMugshotImageAtIndexPath:indexPath delegate:self];
            [imageRequests setValue:req forKey:reqKey];
        }
    }
}

-(void) profile:(Profile *) profile receivedMughshotImage:(UIImage *) image atIndexPath:(NSIndexPath *) indexPath {
    FamilyTableViewCell *cell = (FamilyTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
    cell.mugshotView.image = image;
    cell.activityView.hidden = YES;
    [imageRequests removeObjectForKey:[self keyForIndexPath:indexPath]];
}

- (void)viewWillDisappear:(BOOL)animated {
    for (GeniRequest *req in [imageRequests allValues]) {
        [req cancel];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self loadImagesForOnscreenRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self loadImagesForOnscreenRows];
}


@end
