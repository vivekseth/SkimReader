//
//  EpubTOCExtractor.m
//  SkimReader
//
//  Created by Vivek Seth on 12/30/14.
//  Copyright (c) 2014 Vivek Seth. All rights reserved.
//

#import "EpubTOCExtractor.h"
#import "EpubChapterListing.h"

const NSInteger SKRRootChapterLevel = 0;

@implementation EpubTOCExtractor

+ (NSArray *)chaptersForEpubController:(KFEpubController *)epubController {

	KFEpubKitBookType booktype = epubController.contentModel.bookType;

	if (booktype == KFEpubKitBookTypeEpub2) {
		return [[self class] chaptersForEpubVersion2:epubController];
	} else if (booktype == KFEpubKitBookTypeEpub3) {
		return [[self class] chaptersForEpubVersion3:epubController];
	} else {

		// Try both if not epub2 or epub3.
		NSArray *chapters = [[self class] chaptersForEpubVersion2:epubController];

		if (!chapters) {
			return [[self class] chaptersForEpubVersion3:epubController];
		}

		return chapters;
	}
}

#pragma mark - Epub2 chapters parsing

+ (NSArray *)chaptersForEpubVersion2:(KFEpubController *)epubController {

	NSError *error = nil;
	NSString *ncxString = [[self class] contentStringForManifestItem:@"ncx" epubController:epubController error:&error];
	if (error) {
		NSLog(@"%@", error);
	}
	if (!ncxString || ncxString.length == 0) {
		return nil;
	}

	error = nil;
	DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:ncxString options:kNilOptions error:&error];
	if (error) {
		NSLog(@"%@", error);
	}
	if (!document) {
		return nil;
	}

	DDXMLElement *rootElement = [document rootElement];
	DDXMLElement *navmap = [rootElement elementsForName:@"navMap"][0];
	return [[self class] chaptersFromNavPointContainerElement:navmap level:SKRRootChapterLevel];
}

+ (NSArray *)chaptersFromNavPointContainerElement:(DDXMLElement *)navPointContainerElement level:(NSInteger)level {

	NSMutableArray *chaptersArray = [@[] mutableCopy];

	NSArray *children = [navPointContainerElement children];
	[children enumerateObjectsUsingBlock:^(DDXMLElement *element, NSUInteger idx, BOOL *stop) {
		if ([element.name isEqualToString:@"navPoint"]) {
			[chaptersArray addObject:[[self class] chapterListingFromNavPointElement:element level:level]];
		}
	}];

	return [NSArray arrayWithArray:chaptersArray];
}

+ (EpubChapterListing *)chapterListingFromNavPointElement:(DDXMLElement *)navPointElement level:(NSInteger)level {

	NSString *title = [(DDXMLElement *)[(DDXMLElement *)[navPointElement elementsForName:@"navLabel"][0] elementsForName:@"text"][0] stringValue];
	NSString *relativePath = [[[navPointElement elementsForName:@"content"][0] attributeForName:@"src"] stringValue];
	NSArray *children = [[self class] chaptersFromNavPointContainerElement:navPointElement level:(level + 1)];

	return [[EpubChapterListing alloc] initWithTitle:title path:relativePath children:children level:level];
}

#pragma mark - Epub3 chapters parsing

+ (NSArray *)chaptersForEpubVersion3:(KFEpubController *)epubController {

	NSError *error = nil;
	NSString *ncxString = [[self class] contentStringForManifestItem:@"toc" epubController:epubController error:&error];
	if (error) {
		NSLog(@"%@", error);
	}
	if (!ncxString || ncxString.length == 0) {
		return nil;
	}

	error = nil;
	DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:ncxString options:kNilOptions error:&error];
	if (error) {
		NSLog(@"%@", error);
	}

	DDXMLElement *rootElement = [document rootElement];
	DDXMLElement *firstOrderedList = [[[[rootElement elementsForName:@"body"][0] elementsForName:@"section"][0] elementsForName:@"nav"][0] elementsForName:@"ol"][0];
	return [[self class] chaptersFromListContainerElement:firstOrderedList level:SKRRootChapterLevel];
}

+ (NSArray *)chaptersFromListContainerElement:(DDXMLElement *)listContainerElement level:(NSInteger)level {

	NSMutableArray *chaptersArray = [@[] mutableCopy];

	NSArray *children = [listContainerElement children];
	[children enumerateObjectsUsingBlock:^(DDXMLElement *element, NSUInteger idx, BOOL *stop) {
		if ([element.name isEqualToString:@"li"]) {
			[chaptersArray addObject:[[self class] chapterListingFromListElement:element level:level]];
		}
	}];

	return [NSArray arrayWithArray:chaptersArray];
}

+ (EpubChapterListing *)chapterListingFromListElement:(DDXMLElement *)listElement level:(NSInteger)level {

	DDXMLElement *anchorElement = (DDXMLElement *)[listElement elementsForName:@"a"][0];

	NSString *title = [anchorElement stringValue];
	NSString *relativePath = [[anchorElement attributeForName:@"href"] stringValue];
	NSArray *children = @[];

	NSArray *orderedListElementArray = [listElement elementsForName:@"ol"];
	if (orderedListElementArray.count > 0) {
		children = [[self class] chaptersFromListContainerElement:orderedListElementArray[0] level:(level + 1)];
	}

	return [[EpubChapterListing alloc] initWithTitle:title path:relativePath children:children level:level];
}

#pragma mark - Utility

+ (NSString *)contentStringForManifestItem:(NSString *)manifestItem epubController:(KFEpubController *)epubController error:(NSError **)error {

	NSString *relativePath = epubController.contentModel.manifest[manifestItem][@"href"];
	NSString *fullContentPath = [epubController.epubContentBaseURL.path stringByAppendingPathComponent:relativePath];

	NSString *contentString = [NSString stringWithContentsOfFile:fullContentPath encoding:NSUTF8StringEncoding error:error];
	if (!contentString) {
		contentString = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:fullContentPath] encoding:NSUTF8StringEncoding];
	}

	return contentString;
}

+ (NSInteger)totalChapterCount:(NSArray *)chapters {
	if (!chapters || chapters.count == 0) {
		return 0;
	}

	__block NSInteger count = 0;
	[chapters enumerateObjectsUsingBlock:^(EpubChapterListing *chapterListing, NSUInteger idx, BOOL *stop) {
		count += (1 + [[self class] totalChapterCount:chapterListing.children]);
	}];

	return count;
}

+ (NSArray *)flattenedChapterArray:(NSArray *)chapters {

	__block NSMutableArray *flatChapterArray = [@[] mutableCopy];

	[chapters enumerateObjectsUsingBlock:^(EpubChapterListing *chapterListing, NSUInteger idx, BOOL *stop) {
		[flatChapterArray addObject:chapterListing];
		[flatChapterArray addObjectsFromArray:[[self class] flattenedChapterArray:chapterListing.children]];
	}];

	return [NSArray arrayWithArray:flatChapterArray];
}

@end

