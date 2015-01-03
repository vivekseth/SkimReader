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
	SkimReaderViewController *vc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"SkimReaderViewController"];
	vc.textContent = [self textForEpubChapterIndex:indexPath.row];
	[self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Utility

+ (NSString *)strippedStringForPath:(NSString *)path {
	NSString *fullContentPath = path;
	NSString *contentString = [NSString stringWithContentsOfFile:fullContentPath encoding:NSUTF8StringEncoding error:nil];

	if (contentString == nil) {
		NSLog(@"stringWithContentsOfFile didnt work");
		NSData *data = [NSData dataWithContentsOfFile:fullContentPath];
		NSString *temp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		contentString = temp;
	}

	NSString *strippedString = [[contentString stringByDecodingHTMLEntities] stringByConvertingHTMLToPlainText];
	return strippedString;
}

- (NSString *)fullPathForSpineIndex:(NSInteger)spineIndex {
	NSString *relativePath = self.epubController.contentModel.manifest[self.epubController.contentModel.spine[spineIndex]][@"href"];
	return [self.epubController.epubContentBaseURL.path stringByAppendingPathComponent:relativePath];
}

- (NSString *)textForEpubChapterIndex:(NSInteger)chapterIndex {
	NSString *fullContentPath = [self.epubController.epubContentBaseURL.path stringByAppendingPathComponent:[(EpubChapterListing *)self.chapterListings[chapterIndex] path]];
	NSString *strippedString = @"";

	NSInteger currentSpineIndex = 0;
	NSString *currentContentPath = [self fullPathForSpineIndex:currentSpineIndex];
	while (![fullContentPath hasPrefix:currentContentPath]) {
		currentSpineIndex++;
		currentContentPath = [self fullPathForSpineIndex:currentSpineIndex];
	}

	if (chapterIndex < self.chapterListings.count - 1) { // Iterate until the beginning of the next chapter.
		NSString *nextFullContentPath = [self.epubController.epubContentBaseURL.path stringByAppendingPathComponent:[(EpubChapterListing *)self.chapterListings[chapterIndex + 1] path]];
		while (![nextFullContentPath hasPrefix:currentContentPath]) {
			strippedString = [NSString stringWithFormat:@"%@ %@", strippedString, [self.class strippedStringForPath:currentContentPath]];

			currentSpineIndex++;
			currentContentPath = [self fullPathForSpineIndex:currentSpineIndex];
		}
	} else { // Last chapter so iterate until the end.
		while (currentSpineIndex < self.epubController.contentModel.spine.count) {
			strippedString = [NSString stringWithFormat:@"%@ %@", strippedString, [self.class strippedStringForPath:currentContentPath]];

			currentSpineIndex++;
			if (currentSpineIndex == self.epubController.contentModel.spine.count) {
				break;
			}
			currentContentPath = [self fullPathForSpineIndex:currentSpineIndex];
		}
	}

	return strippedString;
}

@end
