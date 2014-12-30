//
//  EpubChapterListing.h
//  SkimReader
//
//  Created by Vivek Seth on 12/30/14.
//  Copyright (c) 2014 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EpubChapterListing : NSObject

/**
 title of chapter as specified by EPUB
 */
@property (nonatomic, strong, readonly) NSString *title;

/**
 Full path to chapter on disk.
 */
@property (nonatomic, strong, readonly) NSString *path;

/**
 Parent chapter nodes will contain array of EpubChapterListing objects.
 */
@property (nonatomic, strong, readonly) NSArray *children;

/**
 Represents nesting level of a chapter. Root level chapters have level of 1.
 */
@property (nonatomic, readonly) NSInteger level;

- (instancetype)initWithTitle:(NSString *)title
						 path:(NSString *)path
					 children:(NSArray *)children
						level:(NSInteger)level;

@end
