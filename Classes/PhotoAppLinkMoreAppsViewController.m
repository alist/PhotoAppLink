//
//  PhotoAppLinkMoreAppsViewController.m
//  PhotoAppLinkTestApp
//
//  Created by Hendrik Kueck on 11-05-22.
//  Copyright 2011 Pocket Pixels Inc. All rights reserved.
//

#import "PhotoAppLinkMoreAppsViewController.h"
#import "PhotoAppLinkManager.h"  
#import "PhotoAppLinkMoreAppsTableCellView.h"

static const int ROWHEIGHT = 86;

@implementation PhotoAppLinkMoreAppsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        PhotoAppLinkManager* palManager = [PhotoAppLinkManager sharedPhotoAppLinkManager];
        // TODO filter out apps for the wrong platform
        NSPredicate* notInstalledPred = [NSPredicate predicateWithFormat:@"%K=FALSE", @"installed"];
        additionalApps =  [palManager.supportedApps filteredArrayUsingPredicate:notInstalledPred];
        [additionalApps retain];
    }
    return self;
}

- (id)init {
    return [self initWithStyle:UITableViewStylePlain];
}

- (void)dealloc
{
    [additionalApps release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.allowsSelection = NO;
    self.tableView.rowHeight = ROWHEIGHT;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    
    UIImage* shadowImage = [UIImage imageNamed:@"PAL_tableview_shadow.png"];
    UIImageView* bottomShadowView = [[UIImageView alloc] initWithImage:shadowImage];
    UIImageView* topShadowView = [[UIImageView alloc] initWithImage:shadowImage];
    [topShadowView setTransform:CGAffineTransformMakeScale(1.0, -1.0)];
    self.tableView.tableFooterView = bottomShadowView;
    self.tableView.tableHeaderView = topShadowView;
    [bottomShadowView release];
    self.tableView.contentInset = UIEdgeInsetsMake(-20, 0, -20, 0);
    self.navigationItem.title = NSLocalizedString(@"Compatible Apps", @"PhotoAppLink");

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [additionalApps count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PALAppInfoCell";
    static const int APPINFOVIEW_TAG = 1042;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    PhotoAppLinkMoreAppsTableCellView* appInfoView;
    UIButton* storeButton;
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PAL_tablecell_background.png"]];
        CGRect cellFrame = CGRectMake(0.0, 0.0, 320, ROWHEIGHT);
        appInfoView= [[PhotoAppLinkMoreAppsTableCellView alloc] initWithFrame:cellFrame];
        appInfoView.tag = APPINFOVIEW_TAG;
        [cell.contentView addSubview:appInfoView];
        [appInfoView release];
        // add button to go to App Store
        UIImage* buttonBG = [UIImage imageNamed:@"PAL_store_button.png"];
        UIImage* stretchableButtonBG = [buttonBG stretchableImageWithLeftCapWidth:5 topCapHeight:12];
        // TODO add assert
        storeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [storeButton setBackgroundImage:stretchableButtonBG forState:UIControlStateNormal];
        [storeButton addTarget:self action:@selector(storeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [storeButton setTitle:@"Store" forState:UIControlStateNormal];
        [storeButton.titleLabel setFont:[UIFont boldSystemFontOfSize:13]];
        [storeButton.titleLabel setShadowColor:[UIColor blackColor]];
        [storeButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];        
        storeButton.frame = CGRectMake(0, 0, 50, 25);
        [cell setAccessoryView:storeButton];
    }
    else {
        appInfoView = (PhotoAppLinkMoreAppsTableCellView*) [cell.contentView viewWithTag:APPINFOVIEW_TAG];
        storeButton = (UIButton*) cell.accessoryView;
    }
    
    PALAppInfo* appInfo = [additionalApps objectAtIndex:indexPath.row];
    [appInfoView setAppInfo:appInfo];
    storeButton.tag = indexPath.row;
    return cell;
}

- (void)storeButtonTapped:(id)sender
{
    UIButton* tappedButton = sender;
    PALAppInfo* appInfo = [additionalApps objectAtIndex:tappedButton.tag];
    // TODO dismiss modal view controller?
    NSURL* appStoreURL = [appInfo appStoreLink];
    if (appStoreURL != nil) {
        [[UIApplication sharedApplication] openURL:appStoreURL];        
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

@end
