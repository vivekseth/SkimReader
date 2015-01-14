//
//  EpubTOCExtractor.h
//  SkimReader
//
//  Created by Vivek Seth on 12/30/14.
//  Copyright (c) 2014 Vivek Seth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <KFEpubKit/KFEpubKit.h>

@interface EpubTOCExtractor : NSObject

+ (NSArray *)chaptersForEpubController:(KFEpubController *)epubController;

+ (NSInteger)totalChapterCount:(NSArray *)chapters;

+ (NSArray *)flattenedChapterArray:(NSArray *)chapters;

@end
