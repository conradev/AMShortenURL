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

    AMShortenURLController *urlController = [AMShortenURLController sharedInstance];
	[urlController setDelegate:self];
	[urlController shortenURL:longURL];
}

- (BOOL)canDoActionMenuShortenURL:(id)sender {
	NSString *selectedText = [self selectedTextualRepresentation];
    AMShortenURLController *urlController = [AMShortenURLController sharedInstance];
	if ([urlController isInternetAvailable] && ![urlController isLoadingRequest] && [selectedText length] > 0) {
		return [selectedText isMatchedByRegex:@"\\bhttps?://[a-zA-Z0-9\\-.]+(?:(?:/[a-zA-Z0-9\\-._?,'+\\&amp;%$=~*!():@\\\\]*)+)?"];
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

	[AMShortenURLController sharedInstance];
}

@end
