//
//  EpubChapterListing.m
//  SkimReader
//
//  Created by Vivek Seth on 12/30/14.
//  Copyright (c) 2014 Vivek Seth. All rights reserved.
//

#import "EpubChapterListing.h"

@implementation EpubChapterListing

- (instancetype)initWithTitle:(NSString *)title
						 path:(NSString *)path
					 children:(NSArray *)children
						level:(NSInteger)level {
	self = [super init];
	if (!self) {
		return nil;
	}

	_title = title;
	_path = path;
	_children = children;
	_level = level;

	return self;
}

@end
