//
//  OSSpritzLabel.m
//  OpenSpritzDemo
//
//  Created by Francesco Mattia on 08/03/14.
//  Copyright (c) 2014 Fr4ncis. All rights reserved.
//

#import "VSSpritzLabel.h"
#import "UIView+KHAExtensions.h"

const CGFloat VSDarkGreyTextWhiteLevel = 0.55;

@interface VSSpritzLabel ()
@property (nonatomic, strong) UILabel *wordLabel;
@property (nonatomic, strong) NSLayoutConstraint *horizontalWordPositionConstraint;
@property (nonatomic, strong) NSLayoutConstraint *horizontalCrosshairPositionConstraint;
@property (nonatomic) CGFloat pivotOffset;
@end

@implementation VSSpritzLabel

#pragma mark - Init

- (instancetype)init {
	self = [super initWithFrame:CGRectZero];
	if (!self) {
        return nil;
    }

	[self _commonInit];

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (!self) {
        return nil;
    }

	[self _commonInit];

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (!self) {
        return nil;
    }

	[self _commonInit];

    return self;
}

/**
 All init methods should call this method.
 */
- (void)_commonInit {
	_font = [[self class] defaultFont];
	[self setUpContainerView];
	[self setUpWordLabel];
	[self setUpCrosshairView];
}

#pragma mark - Set Up

- (void)setUpWordLabel {
	self.wordLabel = [UILabel new];
	self.wordLabel.font = self.font;
	self.wordLabel.textAlignment = NSTextAlignmentLeft;

	self.wordLabel.translatesAutoresizingMaskIntoConstraints = NO;
	[self insertSubview:self.wordLabel atIndex:2];
	[self kha_addConstraintsForVerticallyCenteredSubview:self.wordLabel];

	NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem:self.wordLabel
																  attribute:NSLayoutAttributeLeft
																  relatedBy:NSLayoutRelationEqual
																	 toItem:self
																  attribute:NSLayoutAttributeLeft
																 multiplier:1.0
																   constant:0.0];
	self.horizontalWordPositionConstraint = constraint;
	[self addConstraint:constraint];
}

- (void)setUpContainerView {

	self.containerView = self.containerView ?: [[self class] defaultContainerView];
	UIView *containerView = self.containerView;

	containerView.translatesAutoresizingMaskIntoConstraints = NO;
	[self insertSubview:containerView atIndex:0];
	[self kha_pinSubview:containerView toEdges:UIRectEdgeAll];

	self.backgroundColor = [UIColor clearColor]; // To allow containerView to dictate visual shape of spritzLabel.
}

- (void)setUpCrosshairView {

	self.crosshairView = self.crosshairView ?: [[self class] defaultCrosshairView];
	UIView *crosshairView = self.crosshairView;

	crosshairView.translatesAutoresizingMaskIntoConstraints = NO;
	[self insertSubview:crosshairView atIndex:1];
	[self kha_addConstraintsForFullHeightSubview:crosshairView];
	[self kha_addConstraintsForVerticallyCenteredSubview:crosshairView];

	self.horizontalCrosshairPositionConstraint = [NSLayoutConstraint constraintWithItem:self
																			  attribute:NSLayoutAttributeLeft
																			  relatedBy:NSLayoutRelationEqual
																				 toItem:crosshairView
																			  attribute:NSLayoutAttributeCenterX
																			 multiplier:1.0
																			   constant:-self.pivotOffset];
	[self addConstraint:self.horizontalCrosshairPositionConstraint];
}

/**
 Updates font to fit in area
 Updates crosshair location based on width
 */
// TODO(vivek): Only update constraints and font if dimensions of self have been invalidated
- (void)layoutSubviews {
	const CGFloat heightToFontSizeRatio = 0.3333;
	const CGFloat widthToPivotOffsetRatio = 0.3333;

	CGFloat oldOffsetFromLeft = self.pivotOffset - self.horizontalWordPositionConstraint.constant;
	CGFloat oldWordWidth = [self.wordLabel.text sizeWithAttributes:@{NSFontAttributeName: self.font}].width;

	self.pivotOffset = widthToPivotOffsetRatio * self.frame.size.width;
	self.horizontalCrosshairPositionConstraint.constant = -self.pivotOffset;
	self.font = [self.font fontWithSize:(heightToFontSizeRatio * self.frame.size.height)];

	// Calculate new offset for word based on old offset
	if (oldWordWidth != 0) {
		CGFloat offsetFromLeftWidthPercentage = oldOffsetFromLeft / oldWordWidth;
		CGFloat newOffsetFromLeft = offsetFromLeftWidthPercentage * [self.wordLabel.text sizeWithAttributes:@{NSFontAttributeName: self.font}].width;
		self.horizontalWordPositionConstraint.constant = -newOffsetFromLeft+self.pivotOffset;
	}

	[super layoutSubviews];
}

#pragma mark - Utility

- (CGFloat)calculateOffsetForWord:(NSString *)word pivotCharacterIndex:(NSInteger)pivotCharacterIndex {
	NSRange pivotCharRange = NSMakeRange(pivotCharacterIndex, 1);
	NSAssert(pivotCharRange.location != NSNotFound, @"no pivot char found");

	NSString *leftPartOfWord = [word substringToIndex:pivotCharacterIndex];
	NSString *pivotCharString = [word substringWithRange:pivotCharRange];

	CGFloat leftPartWidth = [leftPartOfWord sizeWithAttributes:@{NSFontAttributeName: self.font}].width;
	CGFloat centerPartWidth = [pivotCharString sizeWithAttributes:@{NSFontAttributeName: self.font}].width;

	return leftPartWidth + 0.5 * centerPartWidth;
}

+ (UIView *)defaultCrosshairView {
	UIView *crosshairView = [UIView new];

	// crosshairView.backgroundColor = [UIColor lightGrayColor];
	// crosshairView.alpha = 0.2;
	[crosshairView kha_constrainWidth:1.0];

	// Setup top part of crosshair view.
	UIView *topView = [UIView new];
	topView.backgroundColor = [self.class defaultTintColor];
	[crosshairView addSubview:topView];

	topView.translatesAutoresizingMaskIntoConstraints = NO;
	[crosshairView kha_pinSubview:topView toEdges:UIRectEdgeTop|UIRectEdgeLeft|UIRectEdgeRight];
	[crosshairView addConstraint:[NSLayoutConstraint constraintWithItem:topView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:crosshairView attribute:NSLayoutAttributeHeight multiplier:0.166666667 constant:0.0]];

	// Setup top part of crosshair view.
	UIView *bottomView = [UIView new];
	bottomView.backgroundColor = [self.class defaultTintColor];
	[crosshairView addSubview:bottomView];

	bottomView.translatesAutoresizingMaskIntoConstraints = NO;
	[crosshairView kha_pinSubview:bottomView toEdges:UIRectEdgeBottom|UIRectEdgeLeft|UIRectEdgeRight];
	[crosshairView addConstraint:[NSLayoutConstraint constraintWithItem:bottomView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:crosshairView attribute:NSLayoutAttributeHeight multiplier:.166666667 constant:0.0]];

	return crosshairView;
}

+ (UIView *)defaultContainerView {
	UIView *containerView = [UIView new];

	containerView.layer.borderColor = [self.class defaultTintColor].CGColor; //[UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
	containerView.layer.borderWidth = 1.0;
	containerView.layer.cornerRadius = 20;
	containerView.backgroundColor = [UIColor whiteColor];

	return containerView;
}

+ (UIFont *)defaultFont {
	return [UIFont fontWithName:@"Helvetica" size:60.0f];
}

+ (UIColor *)defaultTintColor {
	return [UIColor colorWithRed:244.0/255.0 green:134.0/255.0 blue:25.0/255.0 alpha:1.0];
}

#pragma mark - Public Methods

- (void)setWord:(NSString *)word pivotCharacterIndex:(NSInteger)pivotCharacterIndex {
	NSAssert(word && ![word isEqualToString:@""], @"word must not be nil, nor empty string");

	// Update font size and crosshair location if needed.
	[self layoutIfNeeded];

	CGFloat offsetFromLeft = [self calculateOffsetForWord:word pivotCharacterIndex:pivotCharacterIndex];
	self.horizontalWordPositionConstraint.constant = -offsetFromLeft+self.pivotOffset;
	self.wordLabel.text = word;

	NSMutableAttributedString * mutableAttributedString =
	[[NSMutableAttributedString alloc] initWithString:word
										   attributes:@{
														NSFontAttributeName: self.font,
														NSForegroundColorAttributeName : [UIColor colorWithWhite:VSDarkGreyTextWhiteLevel alpha:1.0]
														}];

	NSRange pivotCharRange = NSMakeRange(pivotCharacterIndex, 1);
	[mutableAttributedString setAttributes:@{
											 NSFontAttributeName: self.font,
											 NSForegroundColorAttributeName : [UIColor blackColor]
											 }
									 range:pivotCharRange];

	self.wordLabel.attributedText = mutableAttributedString;
}

- (void)beginStartAnimationWithCompletion:(void(^)(BOOL finished))completion {
	UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.pivotOffset, self.frame.size.height)];
	leftView.backgroundColor = [self.class defaultTintColor];
	leftView.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:leftView];
	CGRect toFrameLeftView = CGRectMake(self.pivotOffset, 0, 0, self.frame.size.height);


	UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(self.pivotOffset, 0, (self.frame.size.width - self.pivotOffset), self.frame.size.height)];
	rightView.backgroundColor = [self.class defaultTintColor];
	rightView.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:rightView];
	CGRect toFrameRightView = CGRectMake(self.pivotOffset, 0, 0, self.frame.size.height);

	// Use exponential decay animation curve.
	// Setting springDampening to 1.0 creates a 'critically dampened' spring.
	// Its velocity decays with absolutely no oscilation.
	[UIView animateWithDuration:1.0 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:0.0 options:0 animations:^{
		leftView.alpha = 0.1;
		leftView.frame = toFrameLeftView;

		rightView.alpha = 0.1;
		rightView.frame = toFrameRightView;
	} completion:^(BOOL finished) {
		[leftView removeFromSuperview];
		[rightView removeFromSuperview];
		completion(finished);
	}];
}

@end