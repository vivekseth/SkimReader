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
#import "EpubTOCExtractor.h"
#import "EpubChapterListing.h"

@interface EpubViewController ()

@property (nonatomic, strong) NSArray *chapterListings;

@end

@implementation EpubViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.chapterListings = [EpubTOCExtractor flattenedChapterArray:[EpubTOCExtractor chaptersForEpubController:self.epubController]];
}

#pragma mark - UITableView Stuff

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.chapterListings.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EpubTableViewCell"];
	EpubChapterListing *chapterListing = self.chapterListings[indexPath.row];

	cell.textLabel.text = chapterListing.title;
	cell.indentationWidth = 20;
	cell.indentationLevel = chapterListing.level;

	return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	EpubChapterListing *chapterListing = self.chapterListings[indexPath.row];
	NSString *relativePath = chapterListing.path;
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

@end
