//
//  SkimReaderViewController.m
//  SkimReader
//
//  Created by Vivek Seth on 12/27/14.
//  Copyright (c) 2014 Vivek Seth. All rights reserved.
//

#import "SkimReaderViewController.h"

static const NSInteger defaultWPM = 300;

@interface SkimReaderViewController () <VSSpritzViewControllerDelegate>

@property (nonatomic) BOOL isStarted;

@property (nonatomic, strong) VSSpritzViewController *spritzViewController;

@end

@implementation SkimReaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	self.spritzViewController = [[VSSpritzViewController alloc] initWithBodyText:self.textContent];
	self.spritzViewController.spritzView = self.spritzLabel;
	self.spritzViewController.delegate = self;
	self.isStarted = false;

	[self setPlayPauseButtonState:self.isStarted];
	[self setWPMValue:defaultWPM];
	[self setProgressViewValue:0];

	[self.playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
	[self.playPauseButton setTitle:@"Play" forState:UIControlStateSelected];
}

#pragma mark - UI Element Handlers

- (IBAction)wpmSliderValueDidChange:(UISlider *)slider {
	[self setWPMValue:(NSInteger)slider.value];
}

- (IBAction)playPauseButtonTapped:(UIButton *)sender {
	if (self.isStarted) {
		[self.spritzViewController stop];
	} else {
		[self.spritzViewController start];
	}
	self.isStarted = !self.isStarted;
	[self setPlayPauseButtonState:self.isStarted];
}

- (IBAction)skipForwardButtonTapped:(UIButton *)sender {
	[self setRelativeProgress:500];
}

- (IBAction)skipBackwardsButtonTapped:(UIButton *)sender {
	[self setRelativeProgress:-500];
}

#pragma mark - Utility

- (void)setWPMValue:(NSInteger)wpm {
	self.wpmLabel.text = [NSString stringWithFormat:@"%ld WPM", (long)wpm];
	self.spritzViewController.wordsPerMinute = wpm;
}

- (void)setPlayPauseButtonState:(BOOL)isStarted {
	if (self.isStarted) {
		self.playPauseButton.selected = YES;
	} else {
		self.playPauseButton.selected = NO;
	}

}

- (void)setProgressViewValue:(CGFloat)progress {
	self.progressView.progress = progress;
}

- (void)setRelativeProgress:(NSInteger)relativeProgress {
	[self.spritzViewController stop];
	self.isStarted = NO;
	[self setPlayPauseButtonState:self.isStarted];

	NSInteger currentProgress = self.spritzViewController.currentWordIndex;
	currentProgress += relativeProgress;
	currentProgress = MAX(0, MIN(currentProgress, self.spritzViewController.totalWordCount-1));

	self.spritzViewController.currentWordIndex = currentProgress;
	[self.spritzViewController displayWordWithIndex:self.spritzViewController.currentWordIndex];
	[self setProgressViewValue:((CGFloat)(self.spritzViewController.currentWordIndex + 1) / (CGFloat)self.spritzViewController.totalWordCount)];
}

#pragma mark - VSSpritzViewControllerDelegate

- (void)spritzViewControllerDidFinishShowingWords:(VSSpritzViewController * )spritzViewController {
	self.isStarted = false;
	[self setPlayPauseButtonState:self.isStarted];
}

- (void)spritzViewController:(VSSpritzViewController * )spritzViewController didShowWordIndex:(NSUInteger)wordIndex {
	[self setProgressViewValue:((CGFloat)(wordIndex + 1) / (CGFloat)spritzViewController.totalWordCount)];
}

@end
