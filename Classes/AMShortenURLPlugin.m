//
//  AMShortenURLPlugin.m
//  AMShortenURL
//
//  Created by Conrad Kramer on 8/27/10.
//
//
//

#import "AMShortenURLController.h"

#import "ActionMenu.h"

@implementation UIResponder (AMShortenURL)

- (void)shortenedLongURL:(NSString *)longURL intoShortURL:(NSString *)shortURL {
	
	if ([self respondsToSelector:@selector(paste:)]) {
		NSMutableString *string = [NSMutableString stringWithString:[self selectedTextualRepresentation]];
		if (string && [string length] > 0) {
			[string replaceOccurrencesOfString:longURL withString:shortURL options:NSCaseInsensitiveSearch range:NSMakeRange(0, [string length])];
			[[UIPasteboard generalPasteboard] setString:string];
			if ([[self selectedTextualRepresentation] isEqualToString:[self textualRepresentation]]) {
				[self selectAll:self];	
			}
			[self paste:self];
		}
	}
	
	[[UIPasteboard generalPasteboard] setString:shortURL];
}
- (void)doActionMenuShortenURL:(id)sender {
	NSArray *urls = [[self selectedTextualRepresentation] componentsMatchedByRegex:@"\\bhttps?://[a-zA-Z0-9\\-.]+(?:(?:/[a-zA-Z0-9\\-._?,'+\\&amp;%$=~*!():@\\\\]*)+)?"];
	if ([urls count] < 1) {
		return;
	}
	NSString *longURL = [urls objectAtIndex:0];
	
	[[AMShortenURLController sharedInstance] setDelegate:self];
	[[AMShortenURLController sharedInstance] shortenURL:longURL];
}

- (BOOL)canDoActionMenuShortenURL:(id)sender {
	CMLog(@"Getting text");
	NSString *selectedText = [self selectedTextualRepresentation];
	if ([[AMShortenURLController sharedInstance] IsInternetAvailable] && [selectedText length] > 0) {
		CMLog(@"Got text, checking match");
		CMLog(@"%@", selectedText);
		BOOL isMatched = NO;
		isMatched = [selectedText isMatchedByRegex:@"\\bhttps?://[a-zA-Z0-9\\-.]+(?:(?:/[a-zA-Z0-9\\-._?,'+\\&amp;%$=~*!():@\\\\]*)+)?"];
		CMLog(@"Checked match, returning value");
		return isMatched;
	}
	return NO;
}

+ (void)load {
	NSObject<AMMenuItem> *menuitem = [[UIMenuController sharedMenuController] registerAction:@selector(doActionMenuShortenURL:) title:@"Shorten URL" canPerform:@selector(canDoActionMenuShortenURL:)];
	
	UIScreen *screen = [UIScreen mainScreen];
	if ([screen respondsToSelector:@selector(scale)] && [screen scale] >= 2.0 && [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/ActionMenu/Plugins/Shorten URL@2x.png"]) {
		menuitem.image = [UIImage imageWithContentsOfFile:@"/Library/ActionMenu/Plugins/Shorten URL@2x.png"];
	} else {
		menuitem.image = [UIImage imageWithContentsOfFile:@"/Library/ActionMenu/Plugins/Shorten URL.png"];
	}
	
	[AMShortenURLController createSharedInstanceIfNecessary];
}

@end
