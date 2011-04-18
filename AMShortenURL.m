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
#import "JSON.h"
#import "GTMNSString+HTML.h"
#import "Reachability.h"
#import "RegexKitLite.h"

typedef enum ShortURLService {
	AMTinyURL = 0,
	AMBitly = 1,
	AMIsgd = 2,
	AMxrlus = 3,
	AMTinyarrows = 4,
    AMGoogl = 5
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
	
    ShortURLService service;
	NSString *apikey;
	NSString *username;
    
	BOOL 			 internetIsAvailable;
	
	id<AMShortenerDelegate> delegate;
	
	Reachability    *reachability;
}

+ (id) sharedInstance;

- (NSURLRequest *)requestForLongURL:(NSString *)longurl;
- (NSString *)errorForResponse:(NSString *)response;
- (BOOL)IsInternetAvailable;
- (BOOL)isSimpleRequest;
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
- (void)reloadSettings {
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.conradkramer.amshorturl.plist"];
	service = AMTinyURL;
	apikey = @"";
	username = @"";
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
}
- (id)init {
	if ((self = [super init])) {
		reachability = [[Reachability reachabilityForInternetConnection] retain];
		internetIsAvailable = ([reachability currentReachabilityStatus] != NotReachable);
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
		[reachability startNotifier];
        [self reloadSettings];
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
- (BOOL)isSimpleRequest {
    [self reloadSettings];
    if (service == AMTinyURL || service == AMBitly || service == AMIsgd || service == AMxrlus || service == AMTinyarrows) {
        return YES;
    }
    return NO;
}
- (NSURLRequest *)requestForLongURL:(NSString *)longurl {
    
    [self reloadSettings];
    
	NSString *urlString;
	if (service == AMTinyURL) {
		urlString = [NSString stringWithFormat:@"http://tinyurl.com/api-create.php?url=%@", longurl];
	} else if (service == AMBitly) {
		urlString = [NSString stringWithFormat:@"http://api.bit.ly/v3/shorten?login=%@&apiKey=%@&longUrl=%@&format=txt", username, apikey, longurl];
	} else if (service == AMIsgd) {
		urlString = [NSString stringWithFormat:@"http://is.gd/api.php?longurl=%@", longurl];
	} else if (service == AMxrlus) {
		urlString = [NSString stringWithFormat:@"http://metamark.net/api/rest/simple?long_url=%@", longurl];
	} else if (service == AMTinyarrows) {
		urlString = [NSString stringWithFormat:@"http://tinyarro.ws/api-create.php?url=%@", longurl];
	} else if (service == AMGoogl) {
        // The key parameter is an apikey I signed up for to identify AMShortenURL
		urlString = @"https://www.googleapis.com/urlshortener/v1/url?key=AIzaSyBa126dkv76GJYzVOdSrC7_HIUdGOrCVtY";
	} else {
        return nil;
    }
    
	NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    if (![self isSimpleRequest]) {
        if (service == AMGoogl) {
            [request setHTTPMethod:@"POST"];
            NSDictionary *requestDict = [NSDictionary dictionaryWithObject:longurl forKey:@"longUrl"];
            [request setHTTPBody:[[requestDict JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        }
    }
    
    return request;
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
	longURL = [[aLongURL copy] retain];
	if (!urlData) {
		urlData = [[[NSMutableData alloc] init] retain];
	}
    
	shortenerConnection = [NSURLConnection connectionWithRequest:[self requestForLongURL:longURL] delegate:self];
}
        

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[urlData appendData:data];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if (urlData) {
		[urlData release];
	}
    if (longURL) {
        [longURL release];
    }
    
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
    [errorAlert release];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *shortURL = nil;
    NSString *errorMessage = nil;
    if ([self isSimpleRequest]) {
        shortURL = [[[[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding] gtm_stringByUnescapingFromHTML] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        errorMessage = [[AMShortenURLController sharedInstance] errorForResponse:shortURL];
    } else {
        if (service == AMGoogl) {
            NSDictionary *responseDict = [[[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding] JSONValue];
            shortURL = [responseDict objectForKey:@"id"];
            if (!shortURL) {
                if ([responseDict objectForKey:@"error"]) {
                    errorMessage = [[responseDict objectForKey:@"error"] objectForKey:@"message"];
                }
            }
        }
    }
	
    if (errorMessage) {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
        [errorAlert release];
    } else {
        if (delegate && [delegate respondsToSelector:@selector(shortenedLongURL:intoShortURL:)]) {
            [delegate shortenedLongURL:longURL intoShortURL:shortURL];
        }
    }
    
    if (urlData) {
		[urlData release];
	}
    if (longURL) {
        [longURL release];
    }
}

@end

@implementation UIResponder (ActionMenuTinyURLAction)

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
