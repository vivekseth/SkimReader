//
//  ViewController.m
//  SkimReader
//
//  Created by Vivek Seth on 12/27/14.
//  Copyright (c) 2014 Vivek Seth. All rights reserved.
//

#import "DocumentViewController.h"

#import <DBChooser/DBChooser.h>
#import <AFNetworking/AFNetworking.h>
#import <MBProgressHUD/MBProgressHUD.h>

#import "EpubViewController.h"
#import "EpubDownloadController.h"

@interface DocumentViewController () <EpubDownloadControllerDelegate>

@property (nonatomic, strong) NSMutableArray *epubControllerArray;
@property (nonatomic, strong) EpubDownloadController *downloadController;
@property (nonatomic) BOOL isSynchronouslyFindingEpubs; // Used to conditionally reload tableview on each -epubDownloadController:didParseEpub: delegate call.

@end

@implementation DocumentViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];

	self.isSynchronouslyFindingEpubs = NO;
	[self loadEpubsFromDisk];
}

#pragma mark - UITableView Stuff

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.epubControllerArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FileTableViewCell"];
	KFEpubController *epubController = self.epubControllerArray[indexPath.row];
	cell.textLabel.text = epubController.contentModel.metaData[@"title"];
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	EpubViewController *vc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"EpubViewController"];
	vc.epubController = self.epubControllerArray[indexPath.row];
	[self.navigationController pushViewController:vc animated:YES];
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		KFEpubController *epubController = self.epubControllerArray[indexPath.row];

		NSError *error = nil;
		[[NSFileManager defaultManager] removeItemAtPath:epubController.epubURL.path error: &error];
		[[NSFileManager defaultManager] removeItemAtPath:epubController.destinationURL.path error: &error];

		if (error) {
			NSLog(@"%@", error);
		}

		[self.epubControllerArray removeObjectAtIndex:indexPath.row];
		[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
}

#pragma mark - Button Handlers

- (IBAction)dropboxButtonTapped:(id)sender {
	[[DBChooser defaultChooser] openChooserForLinkType:DBChooserLinkTypeDirect
									fromViewController:self completion:^(NSArray *results) {
		 if ([results count]) {
			 // Explicitly set to NO to ensure tableView is reloaded after data comes.
			 self.isSynchronouslyFindingEpubs = NO;
			 [MBProgressHUD showHUDAddedTo:self.view animated:YES];
			 [results enumerateObjectsUsingBlock:^(DBChooserResult *res, NSUInteger idx, BOOL *stop) {
				 self.downloadController = [EpubDownloadController new];
				 self.downloadController.delegate = self;
				 [self.downloadController asyncDownloadAndParseEpubFromURL:res.link];
			 }];
		 } else {
			 // User canceled the action
			 NSLog(@"cancel");
		 }
	 }];
}

#pragma mark - EpubDownloadControllerDelegate

- (void)epubDownloadController:(EpubDownloadController *)epubDownloadController
				  didParseEpub:(KFEpubController *)epubController {
	[self.epubControllerArray addObject:epubController];

	if (!self.isSynchronouslyFindingEpubs) {
		[self.tableView reloadData];
		[MBProgressHUD hideHUDForView:self.view animated:YES];
	}
}

- (void)epubDownloadController:(EpubDownloadController *)epubDownloadController
			  didFailWithError:(NSError *)error {
	NSLog(@"error :(");
	[MBProgressHUD hideHUDForView:self.view animated:YES];
}


#pragma mark - Utility

+ (NSArray *)epubFileList {
	return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[EpubDownloadController pathForFolderInDocuments:SKREpubFileDirectoryName] error:NULL];
}

- (void)loadEpubsFromDisk {

	self.isSynchronouslyFindingEpubs = YES;
	[MBProgressHUD showHUDAddedTo:self.view animated:YES];


	self.epubControllerArray = [@[] mutableCopy];
	NSArray *filenameArray = [[self class] epubFileList];
	[filenameArray enumerateObjectsUsingBlock:^(NSString *filename, NSUInteger idx, BOOL *stop) {
		NSURL *epubFileURL = [NSURL URLWithString:[EpubDownloadController pathForFileInFolder:SKREpubFileDirectoryName name:filename]];
		EpubDownloadController *downloadController = [EpubDownloadController new];
		downloadController.delegate = self;
		[downloadController parseEpubFromLocalURL:epubFileURL asynchronous:NO];
	}];

	[self.tableView reloadData];
	[MBProgressHUD hideHUDForView:self.view animated:YES];
	self.isSynchronouslyFindingEpubs = NO;
}

@end
