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

@interface DocumentViewController ()

@property (nonatomic, strong) NSArray *files;

@end

@implementation DocumentViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	self.files = [[self class] listFileAtPath:[[self class] applicationDocumentsDirectory].path];

	self.refreshControl = [[UIRefreshControl alloc] init];
	self.refreshControl.backgroundColor = [UIColor purpleColor];
	self.refreshControl.tintColor = [UIColor whiteColor];
	[self.refreshControl addTarget:self
							action:@selector(refreshTableViewData)
				  forControlEvents:UIControlEventValueChanged];

}

#pragma mark - UITableView Stuff

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FileTableViewCell"];
	cell.textLabel.text = self.files[indexPath.row];
	return cell;
}

- (void)refreshTableViewData {
	self.files = [[self class] listFileAtPath:[[self class] applicationDocumentsDirectory].path];
	[self.tableView reloadData];
	[self.refreshControl endRefreshing];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	// Return YES if you want the specified item to be editable.
	return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *path = [[[self class] applicationDocumentsDirectory].path stringByAppendingPathComponent:self.files[indexPath.row]];
	NSLog(@"%@", path);
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSString *path = [[[self class] applicationDocumentsDirectory].path stringByAppendingPathComponent:self.files[indexPath.row]];
		NSError *error = nil;
		[[NSFileManager defaultManager] removeItemAtPath: path error: &error];
		self.files = [[self class] listFileAtPath:[[self class] applicationDocumentsDirectory].path];
		[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		if (error) {
			NSLog(@"%@", error);
		}
	}
}

#pragma mark - Button Handlers

- (IBAction)dropboxButtonTapped:(id)sender {
	[[DBChooser defaultChooser] openChooserForLinkType:DBChooserLinkTypeDirect
									fromViewController:self completion:^(NSArray *results) {
		 if ([results count]) {
			 // Process results from Chooser
			 [results enumerateObjectsUsingBlock:^(DBChooserResult *res, NSUInteger idx, BOOL *stop) {
				 NSLog(@"%@", res.link);
				 [MBProgressHUD showHUDAddedTo:self.view animated:YES];
				 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
					 NSData *data = [NSData dataWithContentsOfURL:res.link];
					 [data writeToFile:[[[self class] applicationDocumentsDirectory].path stringByAppendingPathComponent:res.name] atomically:YES];
					 NSLog(@"download complete");
					 dispatch_async(dispatch_get_main_queue(), ^{
						 self.files = [[self class] listFileAtPath:[[self class] applicationDocumentsDirectory].path];
						 [self.tableView reloadData];
						 [MBProgressHUD hideHUDForView:self.view animated:YES];
					 });
				 });
			 }];
		 } else {
			 // User canceled the action
			 NSLog(@"cancel");
		 }
	 }];
}

#pragma mark - Utility

+ (NSArray *)listFileAtPath:(NSString *)path {
	NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
	for (int count = 0; count < (int)[directoryContent count]; count++)
	{
		NSLog(@"File %d: %@", (count + 1), [directoryContent objectAtIndex:count]);
	}
	return directoryContent;
}

+ (NSURL *)applicationDocumentsDirectory {
	return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
												   inDomains:NSUserDomainMask] lastObject];
}

@end
