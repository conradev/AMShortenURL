//
//  AMShortenURLPrefsController.m
//  AMShortenURL
//
//  Created by Conrad Kramer on 8/27/10.
//
//
//

#import "AMShortenURLPrefsController.h"

@implementation AMShortenURLPrefsController

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
}
- (void)showBitlyInfo:(id)something {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://bit.ly/a/your_api_key"]];
}
- (id)tableView:(id)view titleForFooterInSection:(int)section {
	if (section == ([self numberOfSectionsInTableView:view] - 1)) {
		return @"\n\nCopyright © 2010 Conrad Kramer";
	} else {
	return [super tableView:view titleForFooterInSection:section];
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
