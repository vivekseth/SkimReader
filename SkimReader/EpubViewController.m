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

@property (nonatomic, strong) NSArray *chapterXMLElements;

@end

@implementation EpubViewController

#pragma mark - UITableView Stuff

- (void)viewDidLoad {
	NSString *relativePath = self.epubController.contentModel.manifest[@"ncx"][@"href"];
	NSString *fullContentPath = [self.epubController.epubContentBaseURL.path stringByAppendingPathComponent:relativePath];
	NSString *contentString = [NSString stringWithContentsOfFile:fullContentPath encoding:NSUTF8StringEncoding error:nil];

	NSError *error = nil;
	DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:contentString options:kNilOptions error:&error];
	if (error) {
		NSLog(@"%@",error);
		return;
	}

	DDXMLElement *rootElement = [document rootElement];
	DDXMLElement *navmap = [rootElement elementsForName:@"navMap"][0];
	NSArray *chapterXMLElements = [navmap elementsForName:@"navPoint"];
	self.chapterXMLElements = chapterXMLElements;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (self.chapterXMLElements) {
		return self.chapterXMLElements.count;
	} else {
		return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.chapterXMLElements) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EpubTableViewCell"];
		DDXMLElement *navPoint = self.chapterXMLElements[indexPath.row];
		cell.textLabel.text = [(DDXMLElement *)[(DDXMLElement *)[navPoint elementsForName:@"navLabel"][0] elementsForName:@"text"][0] stringValue];
		return cell;
	} else {
		return nil;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.chapterXMLElements) {
		DDXMLElement *navPoint = self.chapterXMLElements[indexPath.row];
		DDXMLElement *contentElement = [navPoint elementsForName:@"content"][0];
		NSString *relativePath = [[contentElement attributeForName:@"src"] stringValue];
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
