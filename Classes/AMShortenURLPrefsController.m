//
//  AMShortenURLPrefsController.m
//  AMShortenURL
//
//  Created by Conrad Kramer on 8/27/10.
//
//
//

#import "AMShortenURLPrefsController.h"

#import <GData/GDataOAuthViewControllerTouch.h>

#include <objc/runtime.h>
#include <objc/message.h>

static Class $GDataOAuthViewControllerTouch;

@implementation AMShortenURLPrefsController

// Hacky patches on existing framework
static void nonexistantImplementation(id self, SEL sel) { }
static void setRootController(id self, SEL sel, id controller) { }

+ (void)load {
    if (![[NSBundle bundleWithPath:@"/System/Library/Frameworks/GData.framework"] load]) {
        abort();
    }

    $GDataOAuthViewControllerTouch = objc_getClass("GDataOAuthViewControllerTouch");

    Method popView = class_getInstanceMethod($GDataOAuthViewControllerTouch, @selector(popView));
    method_setImplementation(popView, (IMP)&nonexistantImplementation);
    class_addMethod($GDataOAuthViewControllerTouch, @selector(setRootController:), (IMP)&setRootController, "v@:@");
}

-(void)setURLShortener:(id)value specifier:(PSSpecifier *)spec {
	[self setPreferenceValue:value specifier:spec];
	[[NSUserDefaults standardUserDefaults] synchronize];

	if ([value intValue] == 1) {
		if (![self specifierForID:@"username"]) {
			[self insertSpecifier:[specs objectAtIndex:4] afterSpecifierID:@"urlshortener" animated:NO];
		}
		if (![self specifierForID:@"apikey"]) {
			[self insertSpecifier:[specs objectAtIndex:5] afterSpecifierID:@"username" animated:NO];
		}
		if (![self specifierForID:@"infobutton"]) {
			[self insertSpecifier:[specs objectAtIndex:6] afterSpecifierID:@"apikey" animated:NO];
		}
	} else if ([self specifierForID:@"apikey"] || [self specifierForID:@"username"] || [self specifierForID:@"infobutton"]) {
		if ([self specifierForID:@"apikey"]) {
			[self removeSpecifierID:@"apikey" animated:NO];
		}
		if ([self specifierForID:@"username"]) {
			[self removeSpecifierID:@"username" animated:NO];
		}
		if ([self specifierForID:@"infobutton"]) {
			[self removeSpecifierID:@"infobutton" animated:NO];
		}
	}
    if ([value intValue] == 5) {
        if ([[$GDataOAuthViewControllerTouch authForGoogleFromKeychainForName:APP_SERVICE_NAME] canAuthorize]) {
            if ([self specifierForID:@"authbuttonin"]) {
                [self removeSpecifierID:@"authbuttonin" animated:NO];
            }
            if (![self specifierForID:@"authbuttonout"]) {
                [self insertSpecifier:[specs objectAtIndex:8] afterSpecifierID:@"urlshortener" animated:NO];
            }
        } else {
            if ([self specifierForID:@"authbuttonout"]) {
                [self removeSpecifierID:@"authbuttonout" animated:NO];
            }
            if (![self specifierForID:@"authbuttonin"]) {
                [self insertSpecifier:[specs objectAtIndex:7] afterSpecifierID:@"urlshortener" animated:NO];
            }
        }
    } else {
        if ([self specifierForID:@"authbuttonin"]) {
            [self removeSpecifierID:@"authbuttonin" animated:NO];
        }
        if ([self specifierForID:@"authbuttonout"]) {
            [self removeSpecifierID:@"authbuttonout" animated:NO];
        }
    }
}

- (void)showDonationPage:(PSSpecifier *)spec {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=8GMYVX3582Y7E"]];
}

- (void)showBitlyInfo:(PSSpecifier *)spec {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://bit.ly/a/your_api_key"]];
}

- (void)authButtonPressed:(PSSpecifier *)spec {
	GDataOAuthAuthentication *auth = [$GDataOAuthViewControllerTouch authForGoogleFromKeychainForName:APP_SERVICE_NAME];

    if ([auth canAuthorize]) {
        [$GDataOAuthViewControllerTouch removeParamsFromKeychainForName:APP_SERVICE_NAME];
        [$GDataOAuthViewControllerTouch revokeTokenForGoogleAuthentication:auth];

        if ([self specifierForID:@"authbuttonout"]) {
            [self removeSpecifierID:@"authbuttonout" animated:NO];
        }
        if (![self specifierForID:@"authbuttonin"]) {
            [self insertSpecifier:[specs objectAtIndex:7] afterSpecifierID:@"urlshortener" animated:NO];
        }
    } else {
        NSString *scope = @"https://www.googleapis.com/auth/urlshortener";
        GDataOAuthViewControllerTouch *viewController = [[[$GDataOAuthViewControllerTouch alloc] initWithScope:scope language:nil appServiceName:APP_SERVICE_NAME delegate:self finishedSelector:@selector(viewController:finishedWithAuth:error:)] autorelease];
        viewController.navigationItem.title = @"Sign In";

        [[self navigationController] pushViewController:viewController animated:YES];
    }
}
- (void)viewController:(GDataOAuthViewControllerTouch *)viewController finishedWithAuth:(GDataOAuthAuthentication *)auth error:(NSError *)error {
    [[self navigationController] popToViewController:self animated:YES];
    if ([auth canAuthorize]) {
        if ([self specifierForID:@"authbuttonin"]) {
            [self removeSpecifierID:@"authbuttonin" animated:NO];
        }
        if (![self specifierForID:@"authbuttonout"]) {
            [self insertSpecifier:[specs objectAtIndex:8] afterSpecifierID:@"urlshortener" animated:NO];
        }
    } else {
        if ([self specifierForID:@"authbuttonout"]) {
            [self removeSpecifierID:@"authbuttonout" animated:NO];
        }
        if (![self specifierForID:@"authbuttonin"]) {
            [self insertSpecifier:[specs objectAtIndex:7] afterSpecifierID:@"urlshortener" animated:NO];
        }
    }
}
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"AMShortURL" target:self] retain];
		specs = [[_specifiers retain] retain];
	}

	NSMutableArray *mutSpecs = [_specifiers mutableCopy];

	int prefValue = 0;
	for (PSSpecifier *spec in mutSpecs) {
		if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"urlshortener"]) {
			prefValue = [(NSString *)[self readPreferenceValue:spec] intValue];
		}
	}

    BOOL authButtonInExists = NO;
    BOOL authButtonOutExists = NO;
	BOOL usernameExists = NO;
	BOOL infoExists = NO;
	BOOL apikeyExists = NO;
	for (PSSpecifier *spec in mutSpecs) {
		if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"username"]) {
			usernameExists = YES;
		}
		if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"infobutton"]) {
			infoExists = YES;
		}
		if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"apikey"]) {
			apikeyExists = YES;
		}
        if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"authbuttonin"]) {
			authButtonInExists = YES;
		}
        if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"authbuttonout"]) {
			authButtonOutExists = YES;
		}
	}

	if (prefValue == 5) {
        if ([[objc_getClass("GDataOAuthViewControllerTouch") authForGoogleFromKeychainForName:APP_SERVICE_NAME] canAuthorize]) {
            if (authButtonInExists) {
                [mutSpecs removeObjectAtIndex:7];
            }
        } else {
            if (authButtonOutExists) {
                [mutSpecs removeObjectAtIndex:8];
            }
        }
    } else {
        if (authButtonOutExists) {
            [mutSpecs removeObjectAtIndex:8];
        }
        if (authButtonInExists) {
            [mutSpecs removeObjectAtIndex:7];
        }
    }

	if (prefValue == 1) {
		if (!usernameExists) {
			[mutSpecs insertObject:[specs objectAtIndex:4] atIndex:4];
		}
        if (!apikeyExists) {
			[mutSpecs insertObject:[specs objectAtIndex:5] atIndex:5];
		}
		if (!infoExists) {
			[mutSpecs insertObject:[specs objectAtIndex:6] atIndex:6];
		}
	} else {
		if (infoExists) {
			[mutSpecs removeObjectAtIndex:6];
		}
		if (apikeyExists) {
			[mutSpecs removeObjectAtIndex:5];
		}
		if (usernameExists) {
			[mutSpecs removeObjectAtIndex:4];
		}
	}

	_specifiers = [mutSpecs copy];
	[mutSpecs release];

	return _specifiers;
}
@end

// vim:ft=objc
