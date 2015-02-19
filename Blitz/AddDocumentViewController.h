//
//  AddDocumentViewController.h
//  Blitz
//
//  Created by Vivek Seth on 2/18/15.
//  Copyright (c) 2015 Vivek Seth. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddDocumentViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIButton *dropboxButton;

@property (nonatomic, strong) IBOutlet UIButton *gutenbergButton;

- (IBAction)didTapDoneButton:(id)sender;

- (IBAction)didTapDropboxButton:(id)sender;

- (IBAction)didTapGutenbergButton:(id)sender;

@end
