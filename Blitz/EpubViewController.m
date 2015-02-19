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
#import <HTMLReader/HTMLReader.h>

#import "NSString+HTML.h"
#import "BlitzViewController.h"
#import "EpubTOCExtractor.h"
#import "EpubChapterListing.h"

#import "AppDelegate.h"

@interface EpubViewController ()

@property (nonatomic, strong) NSArray *chapterListings;

@end

@implementation EpubViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.chapterListings = [EpubTOCExtractor flattenedChapterArray:[EpubTOCExtractor chaptersForEpubController:self.epubController]];
}

- (void)viewWillAppear:(BOOL)animated {
	// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
	NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
	[self.tableView deselectRowAtIndexPath:tableSelection animated:YES];
}

#pragma mark - UITableView Stuff

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.chapterListings.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EpubTableViewCell"];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EpubTableViewCell"];
	}

	EpubChapterListing *chapterListing = self.chapterListings[indexPath.row];

	cell.textLabel.text = chapterListing.title;
	cell.indentationWidth = 20;
	cell.indentationLevel = chapterListing.level;

	// Orange Highlight
	cell.selectedBackgroundView = [UIView new];
	cell.selectedBackgroundView.backgroundColor = [AppDelegate blitzTintColor];
	cell.textLabel.highlightedTextColor = [UIColor whiteColor];

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

	// Epub using IDs to indicate chapters
	NSArray *fullContentPathParts = [fullContentPath componentsSeparatedByString:@"#"];
	if (fullContentPathParts.count > 1) {
		NSString *fullContentPathNextChapter = nil;
		if (chapterIndex + 1 < self.chapterListings.count) {
			fullContentPathNextChapter = [self.epubController.epubContentBaseURL.path stringByAppendingPathComponent:[(EpubChapterListing *)self.chapterListings[chapterIndex + 1] path]];
		}

		NSString *currentChapterXMLFilePath = fullContentPathParts[0];
		NSString *currentChapterXMLIDString = fullContentPathParts[1];
		NSString *contentString = [NSString stringWithContentsOfFile:currentChapterXMLFilePath encoding:NSUTF8StringEncoding error:nil];

		// Not the last chapter
		if (fullContentPathNextChapter) {
			NSArray *fullContentPathPartsNextChapter = [fullContentPathNextChapter componentsSeparatedByString:@"#"];

			// next chapter has id and is in the same page.
			if (fullContentPathPartsNextChapter.count > 1 && [currentChapterXMLFilePath isEqualToString:fullContentPathPartsNextChapter[0]]) {
				NSString *nextChapterXMLIDString = fullContentPathPartsNextChapter[1];

				HTMLDocument *document = [HTMLDocument documentWithString:contentString];
				HTMLNode *startNode = [document firstNodeMatchingSelector:[NSString stringWithFormat:@"#%@", currentChapterXMLIDString]];
				HTMLNode *endNode = [document firstNodeMatchingSelector:[NSString stringWithFormat:@"#%@", nextChapterXMLIDString]];

				NSString *documentTextContent = [document textContent];
				NSString *startNodeTextContent = [startNode textContent];
				NSString *endNodeTextContent = [endNode textContent];

				NSArray * componentsSplitByStart = [documentTextContent componentsSeparatedByString:startNodeTextContent];
				// yay it worked!
				if (componentsSplitByStart.count == 2) {
					NSArray * componentsFromLastStartComponentSplitByEnd = [componentsSplitByStart[1] componentsSeparatedByString:endNodeTextContent];
					if (componentsFromLastStartComponentSplitByEnd.count == 2) {
						return [NSString stringWithFormat:@"%@ %@ %@", startNodeTextContent, componentsFromLastStartComponentSplitByEnd[0], endNodeTextContent];
					} else {
						return [NSString stringWithFormat:@"%@ %@", startNodeTextContent, componentsSplitByStart[1]];
					}
				}

				return documentTextContent;
			}

			// next chapter does not have id or is not in the same page.
			else {
				HTMLDocument *document = [HTMLDocument documentWithString:contentString];
				HTMLNode *node = [document firstNodeMatchingSelector:[NSString stringWithFormat:@"#%@", currentChapterXMLIDString]];

				NSString *documentTextContent = [document textContent];
				NSString *startNodeTextContent = [node textContent];

				NSArray * components = [documentTextContent componentsSeparatedByString:startNodeTextContent];
				// yay it worked!
				if (components.count == 2) {
					return [NSString stringWithFormat:@"%@ %@", startNodeTextContent, components[1]];
				}

				// nope!
				else {
					return documentTextContent;
				}
			}
		}

		// The last chapter
		else {
			HTMLDocument *document = [HTMLDocument documentWithString:contentString];
			HTMLNode *node = [document firstNodeMatchingSelector:[NSString stringWithFormat:@"#%@", currentChapterXMLIDString]];

			NSString *documentTextContent = [document textContent];
			NSString *startNodeTextContent = [node textContent];

			NSArray * components = [documentTextContent componentsSeparatedByString:startNodeTextContent];
			// yay it worked!
			if (components.count == 2) {
				return [NSString stringWithFormat:@"%@ %@", startNodeTextContent, components[1]];
			}

			// nope!
			else {
				return documentTextContent;
			}
		}
	}

	// Epub using files to indicate _starts_ of chapters.
	else {

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
	}

	return strippedString;
}

@end
