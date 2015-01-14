//
//  AppDelegate.m
//  SkimReader
//
//  Created by Vivek Seth on 12/27/14.
//  Copyright (c) 2014 Vivek Seth. All rights reserved.
//

#import "AppDelegate.h"
#import <DBChooser/DBChooser.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.
	return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	if ([[DBChooser defaultChooser] handleOpenURL:url]) {
		// This was a Chooser response and handleOpenURL automatically ran the
		// completion block
		return YES;
	}

	return NO;
}

@end
