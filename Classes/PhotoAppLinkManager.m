//    Copyright (c) 2009 Hendrik Kueck
//
//    Permission is hereby granted, free of charge, to any person obtaining
//    a copy of this software and associated documentation files (the
//    "Software"), to deal in the Software without restriction, including
//    without limitation the rights to use, copy, modify, merge, publish,
//    distribute, sublicense, and/or sell copies of the Software, and to
//    permit persons to whom the Software is furnished to do so, subject to
//    the following conditions:
//
//    The above copyright notice and this permission notice shall be
//    included in all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//    OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//    WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "PhotoAppLinkManager.h"

// Substitute your own Linkshare Site ID here if you like.
// This Linkshare ID is used to create affiliate links to 
// supported apps on the App Store
static NSString *const LINKSHARE_SITE_ID = @"voTw02jXldU";

// Substitute this for testing with your own edited server side plist URL
// (Make sure to set up your XCode project so that DEBUG is defined in debug builds, 
//  otherwise the production plist file will be used)
static NSString *const DEBUG_PLIST_URL = @"http://dl.dropbox.com/u/12543232/photoapplink_debug.plist";

static NSString *const GENERIC_APP_ICON = @"sharer-generic.png";

static NSString *const PLIST_DICT_USERPREF_KEY = @"PhotoAppLink_PListDictionary";
static NSString *const LASTUPDATE_USERPREF_KEY = @"PhotoAppLink_LastUpdateDate";
static NSString *const LAUNCH_DATE_KEY = @"launchDate";
static NSString *const SUPPORTED_APPS_PLIST_KEY = @"supportedApps";
static NSString *const PASTEBOARD_NAME = @"com.photoapplink.pasteboard";

#ifdef DEBUG 
const int MINIMUM_SECS_BETWEEN_UPDATES = 0; 
#else
// update list of supported apps every 3 days at most (to avoid unneccessary network access)
const int MINIMUM_SECS_BETWEEN_UPDATES = 3 * 24 * 60 * 60; 
#endif

@interface PhotoAppLinkManager() 
@property (nonatomic,  copy) NSArray *supportedApps;
@property (nonatomic,retain) UIImage *imageToSend;
@end

@implementation PhotoAppLinkManager

@dynamic destinationAppNames;
@synthesize supportedApps;
@synthesize imageToSend;


// trigger background update of the list of supported apps
// This update is only performed once every few days
- (void)updateSupportedAppsInBackground
{
    // check if we already updated recently
    NSUserDefaults* userPrefs = [NSUserDefaults standardUserDefaults];
    NSDate* lastUpdateDate = [userPrefs objectForKey:LASTUPDATE_USERPREF_KEY];
    NSTimeInterval secondsSinceLastUpdate = [[NSDate date] timeIntervalSinceDate:lastUpdateDate];
    if (!lastUpdateDate || secondsSinceLastUpdate > MINIMUM_SECS_BETWEEN_UPDATES) {
        [self performSelectorInBackground:@selector(requestSupportedAppURLSchemesUpdate) withObject:nil];            
    }
}


// this method runs in a background thread and downloads the latest plist file with information
// on the supported apps and their URL schemes.
- (void)requestSupportedAppURLSchemesUpdate
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    // Download dictionary from plist stored on server
#ifdef DEBUG 
    NSURL* plistURL = [NSURL URLWithString:DEBUG_PLIST_URL];
#else
    NSURL* plistURL = [NSURL URLWithString:@"http://www.photoapplink.com/photoapplink.plist"];
#endif
    NSDictionary* plistDict = [NSDictionary dictionaryWithContentsOfURL:plistURL];
    //NSLog(@"Received updated plist dict: %@", plistDict);
    if (plistDict) {
        [self performSelectorOnMainThread:@selector(storeUpdatedPlistContent:) 
                               withObject:plistDict waitUntilDone:YES];        
    }
    [pool release];
}

- (void)storeUpdatedPlistContent:(NSDictionary*)plistDict
{
    // store the new dictionary in the user preferences
    NSUserDefaults* userPrefs = [NSUserDefaults standardUserDefaults];
    [userPrefs setObject:plistDict forKey:PLIST_DICT_USERPREF_KEY];
    // store time stamp of update
    [userPrefs setObject:[NSDate date] forKey:LASTUPDATE_USERPREF_KEY];
    [userPrefs synchronize];
    
    // invalidate list of supported apps
    self.supportedApps = nil;
}


- (NSArray*)supportedApps
{
    if (supportedApps) return supportedApps;
    NSUserDefaults* userPrefs = [NSUserDefaults standardUserDefaults];
    NSDictionary* plistDict = [userPrefs dictionaryForKey:PLIST_DICT_USERPREF_KEY];
    
    // deactivate until official launch date
    NSDate* launchDate = [plistDict objectForKey:LAUNCH_DATE_KEY];
    if (launchDate && ([launchDate compare:[NSDate date]] == NSOrderedDescending)) return nil;
    
    NSArray* plistApps = [plistDict objectForKey:SUPPORTED_APPS_PLIST_KEY];
    if (plistApps == nil) return nil;
    
    NSString* ownBundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSMutableArray* newSupportedApps = [NSMutableArray array];
    for (NSDictionary* plistAppInfo in plistApps) {
        NSString* bundleID = [plistAppInfo objectForKey:@"bundleID"];
        // Drop entry for the currently running app
        if (! [bundleID isEqualToString:ownBundleID]) {
            PALAppInfo* appInfo = [[PALAppInfo alloc] init];
            appInfo.bundleID = bundleID;
            appInfo.appName = [plistAppInfo objectForKey:@"name"];
            appInfo.canSend = [[plistAppInfo objectForKey:@"sends"] boolValue];
            appInfo.canReceive = [[plistAppInfo objectForKey:@"receives"] boolValue];
            appInfo.urlScheme = [NSURL URLWithString:[[plistAppInfo objectForKey:@"scheme"] 
                                                      stringByAppendingString:@"://"]];
            appInfo.appleID = [plistAppInfo objectForKey:@"appleID"];
            appInfo.installed = (appInfo.canReceive && 
                                 [[UIApplication sharedApplication] canOpenURL:appInfo.urlScheme]);
            appInfo.appDescription = [plistAppInfo objectForKey:@"description"];
            appInfo.thumbnailURL = [NSURL URLWithString:[plistAppInfo objectForKey:@"thumbnail"]];
            appInfo.thumbnail2xURL = [NSURL URLWithString:[plistAppInfo objectForKey:@"thumbnail2x"]];
            [appInfo updateThumbnail];
            [newSupportedApps addObject:appInfo];
            [appInfo release];        
        }
    }
    supportedApps = [newSupportedApps copy];
    return supportedApps;
}

- (NSArray*)destinationApps
{
    return [self.supportedApps filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K=TRUE", @"installed"]];
}

- (NSArray*)destinationAppNames
{
    NSMutableArray* appNames = [NSMutableArray array];
    for (PALAppInfo* appInfo in self.supportedApps) {
        if (appInfo.installed) {
            [appNames addObject:appInfo.appName];
        }
    }
    return appNames;
}

- (UIImage*)genericAppIcon
{
    if (genericAppIcon) return genericAppIcon;
    genericAppIcon = [[UIImage imageNamed:GENERIC_APP_ICON] retain];
    return genericAppIcon;
}

- (void)invokeApplication:(NSString*)appName withImage:(UIImage*)image
{
    UIPasteboard* pasteboard = [UIPasteboard pasteboardWithName:PASTEBOARD_NAME create:YES];
    [pasteboard setPersistent:YES];
    NSData* jpegData = UIImageJPEGRepresentation(image, 0.99);
    [pasteboard setData:jpegData forPasteboardType:@"public.jpeg"];
    for (PALAppInfo* appInfo in self.supportedApps) {
        if ([appInfo.appName isEqualToString:appName]) {
            // launch the app
            [[UIApplication sharedApplication] openURL:appInfo.urlScheme];
        }
    }    
}

- (UIImage*)popPassedInImage
{
    // Note: We are just looking for an existing pasteboard, however specifying create:NO 
    // will never find the existing pasteboard. This is a bug in Apple's implementation 
    UIPasteboard* pasteboard = [UIPasteboard pasteboardWithName:PASTEBOARD_NAME create:YES];
    UIImage* image = [pasteboard image];
    // clear the pasteboard
    [pasteboard setItems:nil];
    return image;
}

- (UIActionSheet*)actionSheetToSendImage:(UIImage*)image
{
    self.imageToSend = image;
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    actionSheet.title = @"Send To";
    actionSheet.delegate = self;
    
    NSArray *apps = self.destinationApps;
    for (PALAppInfo *info in apps) {
        [actionSheet addButtonWithTitle:info.appName];
    }
    [actionSheet addButtonWithTitle:@"Cancel"];
    actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
    
    return [actionSheet autorelease];
}

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSArray *apps = self.destinationApps;
    if (buttonIndex < [apps count]) {
        PALAppInfo *app = [apps objectAtIndex:buttonIndex];
        [self invokeApplication:app.appName withImage:self.imageToSend];
    }
    self.imageToSend = nil;
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    self.imageToSend = nil;
}


#pragma mark -
#pragma mark Singleton 

static PhotoAppLinkManager *s_sharedPhotoAppLinkManager = nil;

+ (PhotoAppLinkManager*)sharedPhotoAppLinkManager
{
    if (s_sharedPhotoAppLinkManager == nil) {
        s_sharedPhotoAppLinkManager = [[super allocWithZone:NULL] init];
    }
    return s_sharedPhotoAppLinkManager;    
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedPhotoAppLinkManager] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

@end

@implementation PALAppInfo

@synthesize appName, urlScheme, appDescription, bundleID, appleID;
@synthesize thumbnailURL, thumbnail2xURL, installed, canSend, canReceive;
@synthesize thumbnail;

- (void) dealloc
{
    [appName release];
	[urlScheme release];
	[bundleID release];
    [appleID release];
	[thumbnailURL release];
	[thumbnail2xURL release];
    [thumbnail release];
    
    [super dealloc];
}

- (NSURL*)appStoreLink
{
    if (self.appleID == nil) return nil;
    // This creates a LinkShare affiliate link, but without any redirection. It does straight to the app store item.
    NSString* affiliateLink = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%@?mt=8&partnerId=30&tduid=%@",
                               self.appleID, LINKSHARE_SITE_ID];
    return [NSURL URLWithString:affiliateLink];
}

- (void)updateThumbnail
{
    if (thumbnail) return;

    NSArray  *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [cachePaths objectAtIndex:0];
    NSString *cacheFile = [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"icon-%@.png", bundleID]];
    
    if ([[NSFileManager defaultManager] isReadableFileAtPath:cacheFile]) {
        thumbnail = [[UIImage alloc] initWithContentsOfFile:cacheFile];
    }
    
    NSUserDefaults* userPrefs = [NSUserDefaults standardUserDefaults];
    NSDate* lastUpdateDate = [userPrefs objectForKey:[LASTUPDATE_USERPREF_KEY stringByAppendingString:bundleID]];
    NSTimeInterval secondsSinceLastUpdate = [[NSDate date] timeIntervalSinceDate:lastUpdateDate];
    if (thumbnail == nil || !lastUpdateDate || secondsSinceLastUpdate > MINIMUM_SECS_BETWEEN_UPDATES) {
        [self performSelectorInBackground:@selector(requestIconUpdate) withObject:nil];            
    }
}

- (void)requestIconUpdate
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    UIScreen *mainScreen = [UIScreen mainScreen];
    BOOL isRetina = [mainScreen respondsToSelector:@selector(scale)] && [mainScreen scale] == 2.0f;
    NSURL *thumbURL = isRetina ? thumbnail2xURL : thumbnailURL;
    
    NSData *imageData = [NSData dataWithContentsOfURL:thumbURL];
    if (imageData) {
        UIImage *thumb = [UIImage imageWithData:imageData];
        // Just to avoid any consurrency issue
        [self performSelectorOnMainThread:@selector(storeUpdatedThumbnail:)
                               withObject:thumb
                            waitUntilDone:YES];

        // Update the cache
        NSArray  *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cacheDirectory = [cachePaths objectAtIndex:0];
        NSString *cacheFile = [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"icon-%@.png", bundleID]];
        [imageData writeToFile:cacheFile atomically:YES];

        NSUserDefaults* userPrefs = [NSUserDefaults standardUserDefaults];
        // store time stamp of update
        [userPrefs setObject:[NSDate date] forKey:[LASTUPDATE_USERPREF_KEY stringByAppendingString:bundleID]];
        [userPrefs synchronize];
    }
    
    [pool release];
}

- (void)storeUpdatedThumbnail:(UIImage*)thumb
{
    [thumbnail release];
    thumbnail = [thumb retain];
}

- (UIImage*)thumbnail
{
    if (thumbnail) return thumbnail;
    return [[PhotoAppLinkManager sharedPhotoAppLinkManager] genericAppIcon];
}

@end



