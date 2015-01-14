//
//  OSSpritzLabel.h
//  OpenSpritzDemo
//
//  Created by Francesco Mattia on 08/03/14.
//  Copyright (c) 2014 Fr4ncis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VSSpritzView.h"

@interface VSSpritzLabel : UIView <VSSpritzView>

@property (nonatomic, strong) UIView *crosshairView;

@property (nonatomic, strong) UIView *containerView;

@property (nonatomic, strong) UIFont *font;

@end

