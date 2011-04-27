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

#import "ProfileTableViewCell.h"

@implementation ProfileTableViewCell
@synthesize imageView, nameLabel, infoLabel, activityIndicator;

- (void)dealloc {
    [imageView release];
    [nameLabel release];
    [infoLabel release];
    [activityIndicator release];
    [super dealloc];
}

- (UILabel *) newLabelWithPrimaryColor:(UIColor *)primaryColor selectedColor:(UIColor *)selectedColor fontSize:(CGFloat)fontSize bold:(BOOL)bold {
	UIFont *font;
	
	if (bold) {
		font = [UIFont boldSystemFontOfSize:fontSize];
	} else {
		font = [UIFont systemFontOfSize:fontSize];
	}
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
	label.backgroundColor = [UIColor whiteColor];
	label.opaque = YES;
	label.textColor = primaryColor;
	label.highlightedTextColor = selectedColor;
	label.font = font;
	
	return [label autorelease];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		self.nameLabel = [self newLabelWithPrimaryColor:[UIColor blackColor] selectedColor:[UIColor whiteColor] fontSize:14.0 bold:YES];
		self.nameLabel.textAlignment = UITextAlignmentLeft;
		[self.contentView addSubview:self.nameLabel];

		self.infoLabel = [self newLabelWithPrimaryColor:[UIColor grayColor] selectedColor:[UIColor whiteColor] fontSize:12.0 bold:NO];
		self.infoLabel.textAlignment = UITextAlignmentLeft;
		[self.contentView addSubview:self.infoLabel];
        
		self.imageView = [[UIImageView alloc] initWithImage:[self defaultLoadingImage]];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
		[self.contentView addSubview:self.imageView];
		[self.imageView release];
        
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		[self.contentView addSubview:self.activityIndicator];
		[self.activityIndicator release];
        
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
    [imageView setFrame: CGRectMake(2, 3, 46, 46)];
    [activityIndicator setFrame: CGRectMake(15, 15, 20, 20)];
    [nameLabel setFrame: CGRectMake(58, 7, 240, 20)];
    [infoLabel setFrame: CGRectMake(58, 27, 240, 20)];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (UIImage *) defaultLoadingImage {
    return [UIImage imageNamed:@"photo_silhouette_unknown.gif"];
}

-(void) markAsLoading {
    self.imageView.image = [self defaultLoadingImage];
    activityIndicator.hidden = NO; 
    [activityIndicator startAnimating];
}

-(void) updateWithImage:(UIImage *) image {
    [activityIndicator stopAnimating];
    activityIndicator.hidden = YES; 
    imageView.image = image;
    [imageView setNeedsDisplay];
}

-(void) updateWithNoImage {
    [activityIndicator stopAnimating];
    activityIndicator.hidden = YES; 
}


@end
