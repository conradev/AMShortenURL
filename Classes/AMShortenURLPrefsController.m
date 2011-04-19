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

@implementation AMShortenURLPrefsController

// Hacky patches on existing framework
static void nonexistantImplementation(id self, SEL sel) { }
static void setRootController(id self, SEL sel, id controller) { }
+ (void)load {
    Method popView = class_getInstanceMethod(objc_getClass("GDataOAuthViewControllerTouch"), @selector(popView));
    method_setImplementation(popView, (IMP)&nonexistantImplementation);
    class_addMethod(objc_getClass("GDataOAuthViewControllerTouch"), @selector(setRootController:), (IMP)&setRootController, "v@:@");
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
        if (![self specifierForID:@"authbutton"]) {
			[self insertSpecifier:[specs objectAtIndex:7] afterSpecifierID:@"urlshortener" animated:NO];
		}
    } else if ([self specifierForID:@"authbutton"]) {
        [self removeSpecifierID:@"authbutton" animated:NO];
    }
}
- (void)showBitlyInfo:(id)something {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://bit.ly/a/your_api_key"]];
}
- (void)authButtonPressed:(id)something {
	GDataOAuthAuthentication *auth = [GDataOAuthViewControllerTouch authForGoogleFromKeychainForName:APP_SERVICE_NAME];
    
    if ([auth canAuthorize]) {
        [GDataOAuthViewControllerTouch removeParamsFromKeychainForName:APP_SERVICE_NAME];
        [GDataOAuthViewControllerTouch revokeTokenForGoogleAuthentication:auth];
        
        // SET SIGN IN
    } else {
        NSString *scope = @"https://www.googleapis.com/auth/urlshortener";
        

        GDataOAuthViewControllerTouch *viewController = [[[GDataOAuthViewControllerTouch alloc] initWithScope:scope language:nil appServiceName:APP_SERVICE_NAME delegate:self finishedSelector:@selector(viewController:finishedWithAuth:error:)] autorelease];
        viewController.navigationItem.title = @"Google Account";
        
        [[self navigationController] pushViewController:viewController animated:YES];
    }
}
- (void)viewController:(GDataOAuthViewControllerTouch *)viewController finishedWithAuth:(GDataOAuthAuthentication *)auth error:(NSError *)error {
    [[self navigationController] popToViewController:self animated:YES];
    if ([auth canAuthorize]) {
        // SET SIGN OUT
    }
    
}
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"AMShortURL" target:self] retain];
		specs = [[_specifiers retain] retain];
	}
	
	NSMutableArray *mutSpecs = [_specifiers mutableCopy];
	
    GDataOAuthAuthentication *auth = [GDataOAuthViewControllerTouch authForGoogleFromKeychainForName:APP_SERVICE_NAME];
    if ([auth canAuthorize]) {
        // SET SIGN OUT
    } else {
        // SET SIGN IN
    }
    
	int prefValue = 0;
	for (PSSpecifier *spec in mutSpecs) {
		if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"urlshortener"]) {
			prefValue = [(NSString *)[self readPreferenceValue:spec] intValue];
		}
	}
	
    BOOL authButtonExists = NO;
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
        if ([[[spec properties] objectForKey:@"id"] isEqualToString:@"authbutton"]) {
			authButtonExists = YES;
		}
	}
	if (prefValue == 5) {
        if (!authButtonExists) {
            [mutSpecs insertObject:[specs objectAtIndex:7] atIndex:7];
        }
    } else {
        if (authButtonExists) {
            [mutSpecs removeObjectAtIndex:7];
        }
    }
	if (prefValue == 1) {
		if (!usernameExists) {
			[mutSpecs insertObject:[specs objectAtIndex:4] atIndex:4];
		}
		if (!infoExists) {
			[mutSpecs insertObject:[specs objectAtIndex:6] atIndex:6];
		}
		if (!apikeyExists) {
			[mutSpecs insertObject:[specs objectAtIndex:5] atIndex:5];
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
