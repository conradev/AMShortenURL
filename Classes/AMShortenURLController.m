//
//  AMShortenURLController.m
//  AMShortenURL
//
//  Created by Conrad Kramer on 8/27/10.
//
//
//

#import "AMShortenURLController.h"

#import <GData/GDataOAuthViewControllerTouch.h>

@interface UIScreen (iOS4Additions)
- (CGFloat)scale;
@end

static AMShortenURLController *sharedInstance;
static Class $GDataOAuthViewControllerTouch;

@implementation AMShortenURLController

@synthesize delegate, connectionData=_connectionData, longURL=_longURL;

void receivedReloadNotfication(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[[AMShortenURLController sharedInstance] reloadSettings];
}

+ (void)load {
    if (![[NSBundle bundleWithPath:@"/System/Library/Frameworks/GData.framework"] load]) {
        abort();
    }
    $GDataOAuthViewControllerTouch = objc_getClass("GDataOAuthViewControllerTouch");

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)&receivedReloadNotfication, CFSTR("com.comconradkramer.actionmenutinyurl.settings"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}

+ (id)sharedInstance {
	if (!sharedInstance){
		sharedInstance = [[self alloc] init];
	}
	return sharedInstance;
}

- (void)reloadSettings {
    [username release];
    [apikey release];

    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.conradkramer.amshorturl.plist"];
    service = [settings objectForKey:@"urlshortener"] ? [[settings objectForKey:@"urlshortener"] intValue] : AMTinyURL;
    username = [settings objectForKey:@"username"];
    apikey = [settings objectForKey:@"apikey"];

    [username retain];
    [apikey retain];
}


- (id)init {
	if ((self = [super init])) {
		reachability = [[Reachability reachabilityForInternetConnection] retain];
        isLoadingRequest = NO;
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

- (BOOL)isLoadingRequest {
    return isLoadingRequest;
}

- (BOOL)isInternetAvailable {
	return internetIsAvailable;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[reachability stopNotifier];
	[reachability release];
    self.connectionData = nil;
    self.longURL = nil;
	[super dealloc];
}

- (BOOL)isSimpleRequest {
    if (service == AMTinyURL || service == AMBitly || service == AMIsgd || service == AMxrlus || service == AMTinyarrows) {
        return YES;
    }

    return NO;
}

- (NSURLRequest *)requestForLongURL:(NSString *)longurl {
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
		urlString = @"https://www.googleapis.com/urlshortener/v1/url?key=AIzaSyBYpzJ4GuCnHkD_jtaTsJ7l3oM050yAr-k";
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

            GDataOAuthAuthentication *auth = [$GDataOAuthViewControllerTouch authForGoogleFromKeychainForName:APP_SERVICE_NAME];
            if ([auth canAuthorize]) {
                [auth authorizeRequest:request];
            }
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
    if ([response rangeOfString:@"Error: Sorry, the URL you entered is on our internal blacklist"].location != NSNotFound) {
		return @"The URL you are attempting to shorten is blacklisted";
	}
    if ([response rangeOfString:@"ERROR: Blocked"].location != NSNotFound) {
		return @"The URL you are attempting to shorten is blacklisted";
	}

	return nil;
}

- (void)shortenURL:(NSString *)longURL {
    if (isLoadingRequest)
        return;

    self.longURL = longURL;
	self.connectionData = [NSMutableData data];

	shortenerConnection = [NSURLConnection connectionWithRequest:[self requestForLongURL:longURL] delegate:self];
    isLoadingRequest = (shortenerConnection != nil);
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self.connectionData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    isLoadingRequest = NO;

    self.connectionData = nil;
    self.longURL = nil;

    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
    [errorAlert release];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *shortURL = nil;
    NSString *errorMessage = nil;
    isLoadingRequest = NO;

    if ([self isSimpleRequest]) {
        shortURL = [[[[NSString alloc] initWithData:self.connectionData encoding:NSUTF8StringEncoding] gtm_stringByUnescapingFromHTML] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        errorMessage = [[AMShortenURLController sharedInstance] errorForResponse:shortURL];
    } else {
        if (service == AMGoogl) {
            NSString *responseString = [[[NSString alloc] initWithData:self.connectionData encoding:NSUTF8StringEncoding] autorelease];
            NSDictionary *responseDict = [responseString JSONValue];
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
            [delegate shortenedLongURL:self.longURL intoShortURL:shortURL];
        }
    }

    self.connectionData = nil;
    self.longURL = nil;
}

@end
