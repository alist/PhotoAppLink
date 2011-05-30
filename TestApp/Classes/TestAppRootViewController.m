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

#import "TestAppRootViewController.h"
#import "PALSendToController.h"
#import "PALManager.h"
#import "PALMoreAppsController.h"

@interface TestAppRootViewController()
@property (nonatomic, retain) UIImageView *imageView;
@end

@implementation TestAppRootViewController

@dynamic image;
@synthesize imageView;

- (void)dealloc
{
    [imageView release];
	[super dealloc];
}

- (IBAction)showActionSheet
{
    // Simple UIActionSheet method
    UIActionSheet *actionSheet = [[PALManager sharedPALManager] actionSheetToSendImage:self.image];
    if (actionSheet)
    {
        [actionSheet showInView:self.view];
    }
    else
    {
        UIAlertView *newView = [[UIAlertView alloc] initWithTitle:nil 
                                                          message:@"You don't have any PhotoAppLink compatible apps installed in your device"
                                                         delegate:nil 
                                                cancelButtonTitle:@"OK" 
                                                otherButtonTitles:nil];
        [newView show];
        [newView release];
    }
}

- (IBAction)showSendToAppController
{
    // PhotoAppLinkSendToController method
    PALSendToController *newView = [[PALSendToController alloc] init];

    // These are custom buttons for your own sharing options, such as send to fb, twitter, etc...
    [newView addSharingActionWithTitle:@"test action 01" icon:[UIImage imageNamed:@"PAL_unknown_app_icon.png"] identifier:1];
    [newView addSharingActionWithTitle:@"test action 02" icon:[UIImage imageNamed:@"PAL_unknown_app_icon.png"] identifier:1];
    
    // The image you want to share. This can also be provided by a delegate method
    newView.image = self.image;
    
    // Gotta set the delegate because of the custom sharing items. Otherwise not needed.
    newView.delegate = self;

    // Present it however you want...
    [self.navigationController pushViewController:newView animated:YES];
//    [self presentModalViewController:newView animated:YES];
    
    [newView release];
}

- (IBAction)showMoreAppsTable
{
    PALMoreAppsController* moreAppsVC = [[PALMoreAppsController alloc] init];
    [self.navigationController pushViewController:moreAppsVC animated:YES];
    [moreAppsVC release];
}


#pragma mark -
#pragma PhotoAppLinkSendToControllerDelegate

// Delegate method that gets called when a custom sharing item is pressed by the user.
- (void)photoAppLinkImage:(UIImage*)image sendToItemWithIdentifier:(int)identifier
{
    UIAlertView *newView = [[UIAlertView alloc] initWithTitle:nil 
                                                      message:[NSString stringWithFormat:@"Triggered action %d", identifier]
                                                     delegate:nil 
                                            cancelButtonTitle:@"OK" 
                                            otherButtonTitles:nil];
    [newView show];
    [newView release];
}

- (void)setImage:(UIImage*)newImage
{
    self.imageView.image = newImage;
    if (newImage) {
        float imageWidth = newImage.size.width;
        float imageHeight = newImage.size.height;
        float maxDim = MAX(imageWidth, imageHeight);
        float scaleFactor = MIN(280.0 / maxDim, 1.0);
        self.imageView.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);            
    }
}

- (UIImage*) image
{
    return self.imageView.image;
}

@end





