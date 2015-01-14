//
//  EpubDownloadController.m
//  SkimReader
//
//  Created by Vivek Seth on 12/29/14.
//  Copyright (c) 2014 Vivek Seth. All rights reserved.
//

#import "EpubDownloadController.h"

#import <AFNetworking/AFNetworking.h>

NSString * const SKREpubFileDirectoryName = @"epub";
NSString * const SKRExtractedEpubFileDirectoryName = @"extracted";

@interface EpubDownloadController () <KFEpubControllerDelegate>

@property (nonatomic, strong) KFEpubController *epubController;

@end

@implementation EpubDownloadController

- (void)parseEpubFromLocalURL:(NSURL *)localURL asynchronous:(BOOL)asynchronous {
	[[self class] createDirectoryIfNeeded:[[self class] pathForFolderInDocuments:SKRExtractedEpubFileDirectoryName]];
	NSURL *destinationFolderURL = [NSURL URLWithString:[[self class] pathForFileInFolder:SKRExtractedEpubFileDirectoryName name:[localURL lastPathComponent]]];
	self.epubController = [[KFEpubController alloc] initWithEpubURL:localURL
											   andDestinationFolder:destinationFolderURL];
	self.epubController.delegate = self;
	[self.epubController openAsynchronous:asynchronous];
}

- (void)asyncDownloadAndParseEpubFromURL:(NSURL *)url {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.responseSerializer = [AFHTTPResponseSerializer serializer];
	[manager GET:url.absoluteString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSData *data = (NSData *)responseObject;
		NSString *filename= [[NSUUID UUID] UUIDString];
		NSString *epubFilePath = [[self class] pathForFileInFolder:SKREpubFileDirectoryName name:filename];

		[[self class] createDirectoryIfNeeded:[[self class] pathForFolderInDocuments:SKREpubFileDirectoryName]];
		[data writeToFile:epubFilePath atomically:YES];

		[self parseEpubFromLocalURL:[NSURL URLWithString:epubFilePath] asynchronous:YES];

	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (self.delegate && [self.delegate respondsToSelector:@selector(epubDownloadController:didFailWithError:)]) {
			[self.delegate epubDownloadController:self didFailWithError:error];
		}
	}];
}

#pragma mark - KFEpubControllerDelegate

- (void)epubController:(KFEpubController *)controller didOpenEpub:(KFEpubContentModel *)contentModel {
	NSLog(@"successfully downloaded and parsed epub");

	if (self.delegate && [self.delegate respondsToSelector:@selector(epubDownloadController:didParseEpub:)]) {
		[self.delegate epubDownloadController:self didParseEpub:controller];
	}
}

- (void)epubController:(KFEpubController *)controller didFailWithError:(NSError *)error {
	NSLog(@"error opening epub.");
	NSLog(@"%@", error);

	[[NSFileManager defaultManager] removeItemAtPath:controller.epubURL.path error: nil];
	[[NSFileManager defaultManager] removeItemAtPath:controller.destinationURL.path error: nil];

	if (self.delegate && [self.delegate respondsToSelector:@selector(epubDownloadController:didFailWithError:)]) {
		[self.delegate epubDownloadController:self didFailWithError:error];
	}
}

#pragma mark - Utility

+ (NSString *)pathForFileInFolder:(NSString *)folder name:(NSString *)name {
	return [[[[self class] applicationDocumentsDirectory].path stringByAppendingPathComponent:folder] stringByAppendingPathComponent:name];
}

// TOOD (vivek): use boolean return to handle errors
+ (BOOL)createDirectoryIfNeeded:(NSString *)path {
	NSError *error;
	if (![[NSFileManager defaultManager] createDirectoryAtPath:path
								   withIntermediateDirectories:YES
													attributes:nil
														 error:&error])
	{
		return NO;
	} else {
		return YES;
	}
}

+ (NSString *)pathForFolderInDocuments:(NSString *)name {
	return [[[self class] applicationDocumentsDirectory].path
			stringByAppendingPathComponent:name];
}

+ (NSURL *)applicationDocumentsDirectory {
	return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
												   inDomains:NSUserDomainMask] lastObject];
}

@end



