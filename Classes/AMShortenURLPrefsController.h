//
//  AMShortenURLPrefsController.h
//  AMShortenURL
//
//  Created by Conrad Kramer on 8/27/10.
//
//
//

#import <Preferences/PSListController.h>

#define APP_SERVICE_NAME @"AMShortenURL"

@interface AMShortenURLPrefsController : PSListController {

	NSArray *specs;
    BOOL hasGoogleCredentials;
}

@end