//
//  PALSendToController.m
//
//  Created by Gustavo Ambrozio on 26/5/11.
//

#import "PALSendToController.h"
#import "PALManager.h"
#import "PALMoreAppsController.h"
#import "PALAppInfo.h"

#define BUTTONS_WIDTH   57.0f
#define BUTTONS_HEIGHT  77.0f
#define BUTTONLABEL_WIDTH  79.0f

#define BUTTONS_MIN_WIDTH   82.0f
#define BUTTONS_MIN_HEIGHT  82.0f

#define SCROLLVIEW_BOTTOM_MARGIN 18.0f
#define SCROLLVIEW_TOP_MARGIN 8.0f
#define SCROLLVIEW_SIDE_MARGIN 8.0f

@interface PALSendToController (PrivateStuff)

- (void)addButtonWithTitle:(NSString*)title icon:(UIImage*)icon inPosition:(int)position;
- (void)fixIconsLayoutAnimated:(BOOL)animated;
- (void)buttonClicked:(id)sender;
- (void)setupScrollViewContent;
- (void)dismissWithLeavingApp:(BOOL)leavingApp;

@end

@implementation PALSendToController

@synthesize delegate = _delegate;
@synthesize image = _image;

@synthesize iconsScrollView = _iconsScrollView;
@synthesize scrollViewBackgroundView = _scrollViewBackgroundView;
@synthesize iconsPageControl = _iconsPageControl;
@synthesize moreAppsButton = _moreAppsButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    _delegate = nil;
    [_image release];
    [_sharingActions release];
    [_iconsScrollView release];
    [_scrollViewBackgroundView release];
    [_iconsPageControl release];
    [_moreAppsButton release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSAssert(self.navigationController != nil, @"PALSendToController must be presented in a UINavigationController");
    
    UIImage* bgTexture = [UIImage imageNamed:@"PAL_brushed_metal.png"];
    UIColor* bgPattern = [UIColor colorWithPatternImage:bgTexture];
    [self.view setBackgroundColor:bgPattern];
    
    UIImage* scrollViewBG = [UIImage imageNamed:@"PAL_scrollview_background.png"];
    UIImage* stretchableScrollViewBG = [scrollViewBG stretchableImageWithLeftCapWidth:34 topCapHeight:34];
    [_scrollViewBackgroundView setImage:stretchableScrollViewBG];
    // make sure the view is positioned behind the scroll view and not in front of it   
    [self.view sendSubviewToBack:_scrollViewBackgroundView];
    
    // Customization of the button to make it nicer.
    UIImage* buttonBG = [UIImage imageNamed:@"PAL_button_background.png"];
    UIImage* stretchableButtonBG = [buttonBG stretchableImageWithLeftCapWidth:5 topCapHeight:12];
    [_moreAppsButton setBackgroundImage:stretchableButtonBG forState:UIControlStateNormal];

    self.navigationItem.title = NSLocalizedString(@"Send image to", @"PhotoAppLink");
    NSString* backButtonTitle = NSLocalizedString(@"back", @"PhotoAppLink");
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:backButtonTitle
                                                                   style:UIBarButtonItemStyleBordered 
                                                                  target:nil action:nil];
    [[self navigationItem] setBackBarButtonItem:backButton];
    [backButton release];
    
    BOOL isPresentedModally = (self.navigationController.parentViewController.modalViewController == self.navigationController);
    BOOL weAreTheRootController = ([self.navigationController.viewControllers objectAtIndex:0] == self);
    if (isPresentedModally && weAreTheRootController) {
        UIBarButtonItem* cancelButton = 
        [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"PhotoAppLink")
                                         style:UIBarButtonItemStyleBordered 
                                        target:self action:@selector(cancel)];
        [[self navigationItem] setLeftBarButtonItem:cancelButton];
        [cancelButton release];        
    }
    
    [self setupScrollViewContent];    
}

- (void)viewDidUnload
{
    [self setIconsScrollView:nil];
    [self setScrollViewBackgroundView:nil];
    [self setIconsPageControl:nil];
    [self setMoreAppsButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self fixIconsLayoutAnimated:YES];
}

- (void)setupScrollViewContent
{
    int pos = 0;
    
    // First add the custom sharing options
    if (_sharingActions) 
    {
        for (NSArray *sharingAction in _sharingActions)
        {
            [self addButtonWithTitle:[sharingAction objectAtIndex:0]
                                icon:[sharingAction objectAtIndex:1]
                          inPosition:pos++];
        }
    }
    
    // Go though the list of available apps
    NSArray *sharers = [[PALManager sharedPALManager] destinationApps];
    for (PALAppInfo *info in sharers)
    {
        [self addButtonWithTitle:info.name
                            icon:info.thumbnail
                      inPosition:pos++];
    }
    
    _iconsPageControl.currentPage = 0;
    [self fixIconsLayoutAnimated:NO];
}

// Called after initialization and before presenting to add custom sharers
// If you do this you must provide a delegate that implements photoAppLinkImage:sendToItemWithIdentifier:
- (void)addSharingActionWithTitle:(NSString*)title icon:(UIImage*)icon identifier:(int)identifier
{
    if (_sharingActions == nil)
        _sharingActions = [[NSMutableArray alloc] init];
    
    NSAssert(title != nil, @"Title for sharing action can not be nil");
    NSAssert(icon != nil, @"Sharing action must have a valid icon image");
    
    [_sharingActions addObject:[NSArray arrayWithObjects:title, icon, [NSNumber numberWithInt:identifier], nil]];
}

// Creates a UIView with the button and label
// Makes it easier to layout.
- (void)addButtonWithTitle:(NSString*)title icon:(UIImage*)icon inPosition:(int)position 
{
    UIView *encapsulator = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, BUTTONS_WIDTH, BUTTONS_HEIGHT)];
    encapsulator.tag = position + 1;
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag = position + 1;
    btn.frame = CGRectMake(0.0f, 0.0f, BUTTONS_WIDTH, BUTTONS_WIDTH);
    [btn setBackgroundImage:icon forState:UIControlStateNormal];
    btn.showsTouchWhenHighlighted = YES;
    btn.adjustsImageWhenHighlighted = YES;
    [btn addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [encapsulator addSubview:btn];
    
    float buttonOffset = (BUTTONS_WIDTH - BUTTONLABEL_WIDTH) / 2.0;
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(buttonOffset, BUTTONS_WIDTH, BUTTONLABEL_WIDTH, 20.0f)];
    lbl.text = title;
    lbl.font = [UIFont boldSystemFontOfSize:12.0f];
    lbl.lineBreakMode = UILineBreakModeMiddleTruncation;
    lbl.textAlignment = UITextAlignmentCenter;
    lbl.textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.shadowColor = [UIColor blackColor];
    lbl.shadowOffset = CGSizeMake(0.0f, 1.0f);
    [encapsulator addSubview:lbl];
    [lbl release];
    
    [_iconsScrollView addSubview:encapsulator];
    [encapsulator release];
}

// Fixes the layout base on the size of the UIScrollView
- (void)fixIconsLayoutAnimated:(BOOL)animated
{
    NSArray *subviews = [_iconsScrollView subviews];
    if ([subviews count] > 0)
    {
        if (animated)
        {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.1f];
        }
        CGFloat fullW = _iconsScrollView.bounds.size.width;
        CGFloat fullH = _iconsScrollView.bounds.size.height;
        CGFloat w = fullW - 2.0 * SCROLLVIEW_SIDE_MARGIN;
        CGFloat h = fullH - SCROLLVIEW_BOTTOM_MARGIN - SCROLLVIEW_TOP_MARGIN;
        
        // Number of rows and columns of icons
        int iconsX = (int)floor(w / BUTTONS_MIN_WIDTH);
        int iconsY = (int)floor(h / BUTTONS_MIN_HEIGHT);
        
        // The spacing between icons
        CGFloat dx = floor(w / iconsX);
        CGFloat dy = floor(h / iconsY);
        
        // The left/top margin
        CGFloat x0 = floor((dx - BUTTONS_WIDTH) / 2.0f) + SCROLLVIEW_SIDE_MARGIN;
        CGFloat y0 = floor((dy - BUTTONS_HEIGHT) / 2.0f) + SCROLLVIEW_TOP_MARGIN;
        
        int posX = 0;
        int posY = 0;
        int page = 0;
        for (UIView *view in subviews)
        {
            view.frame = CGRectMake(x0 + dx * posX + page * fullW, 
                                    y0 + dy * posY, 
                                    BUTTONS_WIDTH, 
                                    BUTTONS_HEIGHT);
            
            if (++posX == iconsX)
            {
                posX = 0;
                if (++posY == iconsY)
                {
                    posY = 0;
                    page++;
                }
            }
        }
        
        // page now holds the number of pages
        // don't add if posX==0 && posY==0 because this would
        // be an empty page
        if (posX != 0 || posY != 0)
            page++;
        
        _iconsPageControl.hidden = (page <= 1);
        _iconsScrollView.contentSize = CGSizeMake(page * fullW, fullH);
        
        _iconsPageControl.numberOfPages = page;
        if (_iconsPageControl.currentPage >= page)
            _iconsPageControl.currentPage = page - 1;
        
        [_iconsScrollView scrollRectToVisible:CGRectMake(_iconsPageControl.currentPage * fullW, 0.0f,
                                                         fullW, fullH) 
                                     animated:NO];
        
        if (animated)
        {
            [UIView commitAnimations];
        }
    }
}

- (void)buttonClicked:(id)sender
{
    // Get the image from the property or from the delegate
    UIImage *imageToShare = self.image;
    if (imageToShare == nil && _delegate && [_delegate respondsToSelector:@selector(photoAppLinkImage)])
        imageToShare = [_delegate photoAppLinkImage];
    BOOL leavingApp = NO;
    if (imageToShare == nil)
    {
        NSLog(@"This should not happen! You have to either set this object's image or set a delegate and implement photoAppLinkImage");
    }
    else
    {
        int position = [sender tag] - 1;
        if (_sharingActions && position < [_sharingActions count])
        {
            NSArray *sharingAction = [_sharingActions objectAtIndex:position];
            [_delegate photoAppLinkImage:imageToShare sendToItemWithIdentifier:[[sharingAction objectAtIndex:2] intValue]];
        }
        else
        {
            if (_sharingActions)
                position -= [_sharingActions count];
            
            NSArray *sharers = [[PALManager sharedPALManager] destinationApps];
            PALAppInfo *info = [sharers objectAtIndex:position];
            [[PALManager sharedPALManager] invokeApplication:info withImage:imageToShare];
            leavingApp = YES;
        }
    }
    [self dismissWithLeavingApp:leavingApp];
}


- (void)dismissWithLeavingApp:(BOOL)leavingApp
{
    if ([_delegate respondsToSelector:@selector(finishedWithSendToController:leavingApp:)]) {
        [_delegate finishedWithSendToController:self leavingApp:leavingApp];
    }
    else {
        // default behavior
        BOOL isPresentedModally = (self.navigationController.parentViewController.modalViewController == self.navigationController);
        BOOL useAnimation = !leavingApp;
        if (isPresentedModally) {
            [self dismissModalViewControllerAnimated:useAnimation];            
        }
        else {
            [self.navigationController popViewControllerAnimated:useAnimation];
        }
    }
}

- (void)cancel
{
    [self dismissWithLeavingApp:NO];
}


- (IBAction)pageChanged:(id)sender
{
    [_iconsScrollView scrollRectToVisible:CGRectMake(_iconsPageControl.currentPage * _iconsScrollView.frame.size.width, 0.0f,
                                                     _iconsScrollView.frame.size.width, _iconsScrollView.frame.size.height) 
                                 animated:YES];
}

- (IBAction)moreApps:(id)sender
{
    PALMoreAppsController *moreAppsView = [[[PALMoreAppsController alloc] init] autorelease];
    [moreAppsView setDelegate:self];
    [self.navigationController pushViewController:moreAppsView animated:YES];
    
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // Fix my page control
    _iconsPageControl.currentPage = _iconsScrollView.contentOffset.x / _iconsScrollView.frame.size.width;
}

#pragma mark - PALMoreAppsControllerDelegate
-(void)finishedWithMoreAppsController:(PALMoreAppsController *)controller leavingApp:(BOOL)leavingApp
{
    // first pop the more apps controller
    [self.navigationController popViewControllerAnimated:NO];
    // then dismiss this controller as appropriate
    [self dismissWithLeavingApp:leavingApp];
}

@end
