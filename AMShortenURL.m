//
//  ActionMenuTinyURL.m
//  ActionMenuTinyURL
//
//  Created by Conrad on 8/27/10.
//  Copyright Conrad Kramer 2010. All rights reserved.
//
//
//

#import <UIKit/UIKit.h>

#import "ActionMenu.h"
#import "GTMNSString+HTML.h"
#import "Reachability.h"
#import "RegexKitLite.h"

typedef enum ShortURLService {
	AMTinyURL = 0,
	AMBitly = 1,
	AMIsgd = 2,
	AMxrlus = 3,
	AMTinyarrows = 4,
} ShortURLService;

@protocol AMShortenerDelegate <NSObject>

- (void)shortenedLongURL:(NSString *)longURL intoShortURL:(NSString *)shortURL;	

@end

@interface UIScreen (iOS4Additions)
- (CGFloat)scale;
@end

@interface AMShortenURLController : NSObject {
	NSURLConnection *shortenerConnection;
	NSMutableData 	*urlData;
	NSString        *longURL;
	
	BOOL 			 internetIsAvailable;
	
	id<AMShortenerDelegate> delegate;
	
	Reachability    *reachability;
}

+ (id) sharedInstance;

- (NSURL *)apiURLForLongURL:(NSString *)longurl;
- (NSString *)errorForResponse:(NSString *)response;
- (BOOL)IsInternetAvailable;
- (void)shortenURL:(NSString *)longURL;

@property (nonatomic, assign) id<AMShortenerDelegate> delegate;

@end

static AMShortenURLController *sharedInstance;

@implementation AMShortenURLController

@synthesize delegate;

+ (id)sharedInstance {
	if (!sharedInstance){
		sharedInstance = [[self alloc] init];
	}
	return sharedInstance;
}
+ (void)createSharedInstanceIfNecessary {
	if (!sharedInstance){
		sharedInstance = [[self alloc] init];
	}
}
- (id)init {
	if ((self = [super init])) {
		reachability = [[Reachability reachabilityForInternetConnection] retain];
		internetIsAvailable = ([reachability currentReachabilityStatus] != NotReachable);
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
		[reachability startNotifier];
	}
	return self;
}
- (void)reachabilityChanged:(NSNotification *)notification {
	internetIsAvailable = ([reachability currentReachabilityStatus] != NotReachable);
}
- (BOOL)IsInternetAvailable {
	return internetIsAvailable;
}
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[reachability stopNotifier];
	[reachability release];
	[super dealloc];
}
- (NSURL *)apiURLForLongURL:(NSString *)longurl {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.conradkramer.amshorturl.plist"];
	ShortURLService service = AMTinyURL;
	NSString *apikey = @"";
	NSString *username = @"";
	if (settings) {
		for (NSString *key in [settings allKeys]) {
			if ([key isEqualToString:@"urlshortener"]) {
				service = [[settings objectForKey:key] intValue];
			}
			if ([key isEqualToString:@"username"]) {
				username = [settings objectForKey:key];
			}
			if ([key isEqualToString:@"apikey"]) {
				apikey = [settings objectForKey:key];
			}
		}
	}
	NSString *url = @"";
	if (service == AMTinyURL) {
		url = [NSString stringWithFormat:@"http://tinyurl.com/api-create.php?url=%@", longurl];
	} else if (service == AMBitly) {
		url = [NSString stringWithFormat:@"http://api.bit.ly/v3/shorten?login=%@&apiKey=%@&longUrl=%@&format=txt", username, apikey, longurl];
	} else if (service == AMIsgd) {
		url = [NSString stringWithFormat:@"http://is.gd/api.php?longurl=%@", longurl];
	} else if (service == AMxrlus) {
		url = [NSString stringWithFormat:@"http://metamark.net/api/rest/simple?long_url=%@", longurl];
	} else if (service == AMTinyarrows) {
		url = [NSString stringWithFormat:@"http://tinyarro.ws/api-create.php?url=%@", longurl];
	}
	
	return [NSURL URLWithString:url];
}
- (NSString *)errorForResponse:(NSString *)response {
	// Bit.ly
	if ([response rangeOfString:@"INVALID_LOGIN"].location != NSNotFound) {
		return @"The username you specified for bit.ly is invalid";
	}
	if ([response rangeOfString:@"INVALID_APIKEY"].location != NSNotFound) {
		return @"The API key you specified for bit.ly is invalid";
	}
	if ([response rangeOfString:@"MISSING_ARG_LOGIN"].location != NSNotFound) {
		return @"You did not specify a username for bit.ly";
	}
	if ([response rangeOfString:@"MISSING_ARG_APIKEY"].location != NSNotFound) {
		return @"You did not specify an API key for bit.ly";
	}
	if ([response rangeOfString:@"INVALID_URI"].location != NSNotFound) {
		return @"The URL you are attempting to shorten is invalid";
	}
	
	//Other sites
	if ([response rangeOfString:@"INVALID_URL"].location != NSNotFound) {
		return @"The URL you are attempting to shorten is invalid";
	}
	if ([response rangeOfString:@"Invalid URL"].location != NSNotFound) {
		return @"The URL you are attempting to shorten is invalid";
	}
	if ([response rangeOfString:@"Error: The URL entered"].location != NSNotFound) {
		return @"The URL you are attempting to shorten is invalid";
	}
	
	return nil;
}
- (void)shortenURL:(NSString *)aLongURL {
	longURL = [aLongURL copy];
	if (!urlData) {
		urlData = [[[[NSMutableData alloc] init] retain] retain];
	}
	shortenerConnection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[self apiURLForLongURL:longURL]] delegate:self];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[urlData appendData:data];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSString *shortURL = [[[[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding] gtm_stringByUnescapingFromHTML] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (urlData) {
		[urlData setData:nil];
	}
	if (delegate && [delegate respondsToSelector:@selector(shortenedLongURL:intoShortURL:)]) {
		[delegate shortenedLongURL:longURL intoShortURL:shortURL];
	}
}

@end

@implementation UIResponder (ActionMenuTinyURLAction)

- (void)shortenedLongURL:(NSString *)longURL intoShortURL:(NSString *)shortURL {
	
	NSString *errorMessage = [[AMShortenURLController sharedInstance] errorForResponse:shortURL];
	if (errorMessage) {
		UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[errorAlert show];
		[errorAlert release];
		return;
	}
	
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
