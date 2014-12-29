//
//  EpubDownloadController.h
//  SkimReader
//
//  Created by Vivek Seth on 12/29/14.
//  Copyright (c) 2014 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <KFEpubKit/KFEpubKit.h>

extern NSString * const SKREpubFileDirectoryName;
extern NSString * const SKRExtractedEpubFileDirectoryName;

@class EpubDownloadController;

@protocol EpubDownloadControllerDelegate <NSObject>

- (void)epubDownloadController:(EpubDownloadController *)epubDownloadController
				  didParseEpub:(KFEpubController *)epubController;

- (void)epubDownloadController:(EpubDownloadController *)epubDownloadController
			  didFailWithError:(NSError *)error;

@end

@interface EpubDownloadController : NSObject

@property (nonatomic, weak) id<EpubDownloadControllerDelegate> delegate;

- (void)asyncDownloadAndParseEpubFromURL:(NSURL *)url;

- (void)parseEpubFromLocalURL:(NSURL *)localURL asynchronous:(BOOL)asynchronous;

+ (NSString *)pathForFolderInDocuments:(NSString *)name;

+ (NSString *)pathForFileInFolder:(NSString *)folder name:(NSString *)name;

@end

