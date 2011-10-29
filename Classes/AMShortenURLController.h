//
//  AMShortenURLController.h
//  AMShortenURL
//
//  Created by Conrad Kramer on 8/27/10.
//
//
//

#import <UIKit/UIKit.h>

#import "JSON.h"
#import "GTMNSString+HTML.h"
#import "Reachability.h"
#import "RegexKitLite.h"

#import "AMShortenURLPrefsController.h"

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

@interface AMShortenURLController : NSObject {
	NSURLConnection *shortenerConnection;
	NSMutableData 	*_connectionData;
	NSString        *_longURL;

    ShortURLService service;
	NSString *apikey;
	NSString *username;

	BOOL internetIsAvailable;
    BOOL isLoadingRequest;

	id<AMShortenerDelegate> delegate;

	Reachability    *reachability;
}

@property (nonatomic, retain) NSString *longURL;
@property (nonatomic, retain) NSMutableData *connectionData;

+ (id) sharedInstance;

- (NSURLRequest *)requestForLongURL:(NSString *)longurl;
- (NSString *)errorForResponse:(NSString *)response;
- (BOOL)isInternetAvailable;
- (BOOL)isLoadingRequest;
- (BOOL)isSimpleRequest;
- (void)reloadSettings;
- (void)shortenURL:(NSString *)longURL;

@property (nonatomic, assign) id<AMShortenerDelegate> delegate;

@end
