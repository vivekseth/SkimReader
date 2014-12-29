//
//  EpubViewController.m
//  SkimReader
//
//  Created by Vivek Seth on 12/27/14.
//  Copyright (c) 2014 Vivek Seth. All rights reserved.
//

#import "EpubViewController.h"
#import <KFEpubKit/KFEpubKit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "NSString+HTML.h"
#import "SkimReaderViewController.h"

@interface EpubViewController ()

@end

@implementation EpubViewController

#pragma mark - UITableView Stuff

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (self.epubController.contentModel) {
		return self.epubController.contentModel.spine.count;
	} else {
		return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.epubController.contentModel) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EpubTableViewCell"];
		cell.textLabel.text = self.epubController.contentModel.spine[indexPath.row];
		return cell;
	} else {
		return nil;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.epubController.contentModel) {
		NSString *relativePath = self.epubController.contentModel.manifest[self.epubController.contentModel.spine[indexPath.row]][@"href"];
		NSString *fullContentPath = [self.epubController.epubContentBaseURL.path stringByAppendingPathComponent:relativePath];
		NSString *contentString = [NSString stringWithContentsOfFile:fullContentPath encoding:NSUTF8StringEncoding error:nil];

		if (contentString == nil) {
			NSLog(@"stringWithContentsOfFile didnt work");
			NSData *data = [NSData dataWithContentsOfFile:fullContentPath];
			NSString *temp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			contentString = temp;
		}

		NSString *strippedString = [[contentString stringByDecodingHTMLEntities] stringByConvertingHTMLToPlainText];
		SkimReaderViewController *vc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"SkimReaderViewController"];
		vc.textContent = strippedString;
		[self.navigationController pushViewController:vc animated:YES];
	}
}

@end
