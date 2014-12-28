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

@interface EpubViewController () <KFEpubControllerDelegate>

@property (nonatomic, strong) KFEpubController *epubController;
@property (nonatomic, strong) KFEpubContentModel *contentModel;

@end

@implementation EpubViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	self.contentModel = nil;

	NSString *uncompressedEpubDirectoryPath = [[[self class] applicationDocumentsDirectory].path
												stringByAppendingPathComponent:@"uncompressed"];
	[[NSFileManager defaultManager] removeItemAtPath:uncompressedEpubDirectoryPath error:nil];
	NSError *error;
	if (![[NSFileManager defaultManager] createDirectoryAtPath:uncompressedEpubDirectoryPath
								   withIntermediateDirectories:YES
													attributes:nil
														 error:&error])
	{
		NSLog(@"Create directory error: %@", error);
	} else {
		self.epubController = [[KFEpubController alloc] initWithEpubURL:self.epubURL andDestinationFolder:[NSURL URLWithString:uncompressedEpubDirectoryPath]];
		self.epubController.delegate = self;
		[self.epubController openAsynchronous:YES];
	}
}

+ (NSURL *)applicationDocumentsDirectory {
	return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
												   inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - UITableView Stuff 

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (self.contentModel) {
		return self.contentModel.spine.count;
	} else {
		return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.contentModel) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EpubTableViewCell"];
		cell.textLabel.text = self.contentModel.spine[indexPath.row];
		return cell;
	} else {
		return nil;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.contentModel) {
		NSString *relativePath = self.contentModel.manifest[self.contentModel.spine[indexPath.row]][@"href"];
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

#pragma mark - KFEpubControllerDelegate

- (void)epubController:(KFEpubController *)controller didOpenEpub:(KFEpubContentModel *)contentModel {
	[MBProgressHUD hideHUDForView:self.view animated:YES];
	NSLog(@"successfully opened epub!");


	/**
	 @property (nonatomic) KFEpubKitBookType bookType;
	 @property (nonatomic) KFEpubKitBookEncryption bookEncryption;

	 @property (nonatomic, strong) NSDictionary *metaData;
	 @property (nonatomic, strong) NSString *coverPath;
	 @property (nonatomic, strong) NSDictionary *manifest;
	 @property (nonatomic, strong) NSArray *spine;
	 @property (nonatomic, strong) NSArray *guide;
	 */

	NSLog(@"%@", contentModel.metaData);
	NSLog(@"%@", contentModel.coverPath);
	NSLog(@"%@", contentModel.manifest);
	NSLog(@"%@", contentModel.spine);
	NSLog(@"%@", contentModel.guide);

	self.contentModel = contentModel;
	[self.tableView reloadData];
}

- (void)epubController:(KFEpubController *)controller didFailWithError:(NSError *)error {
	[MBProgressHUD hideHUDForView:self.view animated:YES];
	NSLog(@"error opening epub.");
	NSLog(@"%@", error);
}

- (void)epubController:(KFEpubController *)controller willOpenEpub:(NSURL *)epubURL {
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

@end
