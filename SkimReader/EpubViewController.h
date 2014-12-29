//
//  EpubViewController.h
//  SkimReader
//
//  Created by Vivek Seth on 12/27/14.
//  Copyright (c) 2014 Vivek Seth. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <KFEpubKit/KFEpubKit.h>

@interface EpubViewController : UITableViewController

@property (nonatomic, strong) KFEpubController *epubController;

@end
