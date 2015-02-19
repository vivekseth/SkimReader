//
//  AddDocumentViewController.m
//  Blitz
//
//  Created by Vivek Seth on 2/18/15.
//  Copyright (c) 2015 Vivek Seth. All rights reserved.
//

#import "AddDocumentViewController.h"

#import <TOWebViewController/TOWebViewController.h>
#import <DBChooser/DBChooser.h>
#import <AFNetworking/AFNetworking.h>
#import <MBProgressHUD/MBProgressHUD.h>

#import "EpubDownloadController.h"
#import "AppDelegate.h"

@interface AddDocumentViewController () <EpubDownloadControllerDelegate>

@property (nonatomic, strong) EpubDownloadController *downloadController;
// Used to conditionally reload tableview on each -epubDownloadController:didParseEpub: delegate call.
// This has potential to cause race conditions.
@property (nonatomic) BOOL isSynchronouslyFindingEpubs;

@end

@implementation AddDocumentViewController

-(void)viewDidLoad {
	[super viewDidLoad];
	self.navigationController.navigationBar.tintColor = [AppDelegate blitzTintColor];
	[self.dropboxButton setTintColor:[AppDelegate blitzTintColor]];
	[self.gutenbergButton setTintColor:[AppDelegate blitzTintColor]];
}

- (IBAction)didTapDoneButton:(id)sender {
	[self dismissViewControllerAnimated:YES completion:^{
		NSLog(@"done dismissing");
	}];
}

- (IBAction)didTapDropboxButton:(id)sender {
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

- (IBAction)didTapGutenbergButton:(id)sender {
	TOWebViewController *webViewController = [[TOWebViewController alloc] initWithURLString:@"https://www.gutenberg.org/"];

	webViewController.navigationButtonsHidden = NO;
	webViewController.buttonTintColor = [AppDelegate blitzTintColor];
	webViewController.loadingBarTintColor = [AppDelegate blitzTintColor];

	webViewController.shouldStartLoadRequestHandler =  ^BOOL (NSURLRequest *request, UIWebViewNavigationType navigationType){
		// TODO(vivek): super hacky method for getting epub download!
		if ([request.URL.absoluteString containsString:@".epub"]) {
			[self.navigationController popViewControllerAnimated:YES];
			[MBProgressHUD showHUDAddedTo:self.view animated:YES];
			self.downloadController = [EpubDownloadController new];
			self.downloadController.delegate = self;
			[self.downloadController asyncDownloadAndParseEpubFromURL:request.URL];
			return NO;
		} else {
			return YES;
		}
	};

	[self.navigationController pushViewController:webViewController animated:YES];
}

#pragma mark - EpubDownloadControllerDelegate

- (void)epubDownloadController:(EpubDownloadController *)epubDownloadController
				  didParseEpub:(KFEpubController *)epubController {
	if (!self.isSynchronouslyFindingEpubs) {
		[MBProgressHUD hideHUDForView:self.view animated:YES];
	}
}

- (void)epubDownloadController:(EpubDownloadController *)epubDownloadController
			  didFailWithError:(NSError *)error {
	NSLog(@"error :(");
	[MBProgressHUD hideHUDForView:self.view animated:YES];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to parse epub file." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
	[alertView show];
}

@end
