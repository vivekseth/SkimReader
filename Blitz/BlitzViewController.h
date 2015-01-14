//
//  SkimReaderViewController.h
//  SkimReader
//
//  Created by Vivek Seth on 12/27/14.
//  Copyright (c) 2014 Vivek Seth. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <VSSpritz/VSSpritzLabel.h>
#import <VSSpritz/VSSpritzView.h>
#import <VSSpritz/VSSpritzViewController.h>

@interface SkimReaderViewController : UIViewController

@property (nonatomic, strong) NSString *textContent;

@property (nonatomic, strong) IBOutlet VSSpritzLabel *spritzLabel;

@property (nonatomic, strong) IBOutlet UIButton *playPauseButton;

@property (nonatomic, strong) IBOutlet UIButton *skipForwardButton;

@property (nonatomic, strong) IBOutlet UIButton *skipBackwardsButton;

@property (nonatomic, strong) IBOutlet UILabel *wpmLabel;

@property (nonatomic, strong) IBOutlet UIProgressView *progressView;

- (IBAction)wpmSliderValueDidChange:(UISlider *)sender;

- (IBAction)playPauseButtonTapped:(UIButton *)sender;

- (IBAction)skipForwardButtonTapped:(UIButton *)sender;

- (IBAction)skipBackwardsButtonTapped:(UIButton *)sender;

@end
