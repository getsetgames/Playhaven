//
//  PreloadingViewController.m
//  playhaven-sdk-ios
//
//  Created by Jeremy Berman on 3/9/15.
//
//

#import "PreloadingViewController.h"
#import "PHPreloader.h"
#import "PHCacheObject.h"
#import "PHPreloadingObject.h"
#import "PHConstants.h"
#import "PHCacheCreativeRequest.h"

#define FILE_1_URL @"http://cdn.liverail.com/adasset4/1331/229/331/lo.mp4"
#define FILE_2_URL @"http://cdn.liverail.com/adasset4/1331/229/7969/me.flv"
#define LOG_SPACER @"\n----------\n"

@interface PreloadingViewController () <UITableViewDelegate, UITableViewDataSource, PHCacheCreativeRequestDelegate> {
    PHPreloader *_preloader;
    NSArray *_cachedFiles;
    PHBeaconObject *_beaconObject;
    PHBeaconManager *_beaconManager;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UITextView *textView;
@property (nonatomic, strong) IBOutlet UITextField *urlTextField;
@property (nonatomic, strong) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) IBOutlet UILabel *fileDownloading;

@end

@implementation PreloadingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _preloader = [PHPreloader sharedPreloader];
    
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(itemDidStartPreloading:)
                                                 name:PHDidStartPreloadingNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(itemDidFinishPreloading:)
                                                 name:PHDidFinishPreloadingNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(itemDidReceiveData:)
                                                 name:PHDidReceiveDataNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(itemDidFailToPreloading:)
                                                 name:PHDidFailToPreloadNotification
                                               object:nil];
    
    [self getCachedFiles];
}

- (void)getCachedFiles {
    _cachedFiles = [PHPreloader newSavedFilesArray];
    [self.tableView reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startCacheCreative:(id)sender {
    self.request = [[PHCacheCreativeRequest alloc] initWithApp:@"zombie1" secret:@"haven1" delegate:self];
    [self.request send];
}

- (IBAction)downloadFile1:(id)sender {
    [self downloadFileWithURL:[NSURL URLWithString:FILE_1_URL] creativeId:123];
}

- (IBAction)downloadFile2:(id)sender {
    [self downloadFileWithURL:[NSURL URLWithString:FILE_2_URL] creativeId:234];
}

- (IBAction)downloadBoth:(id)sender {
    [self downloadFile1:nil];
    [self downloadFile2:nil];
}

- (IBAction)clearCache:(id)sender {
    [self updateLogWithString:[NSString stringWithFormat:@"Deleting %lu file(s)...", (unsigned long)_cachedFiles.count]];
    [_preloader clear];
    [self updateLogWithString:@"Done."];
    [self getCachedFiles];
}

- (void)downloadFileWithURL:(NSURL *)url creativeId:(NSInteger)creativeId {
    _beaconObject = [[PHBeaconObject alloc] init];
    _beaconManager = [[PHBeaconManager alloc] initWithBeaconObject:_beaconObject];
    PHPreloadingObject *preloadingObject = [[PHPreloadingObject alloc] initWithBeaconManager:_beaconManager url:url creativeId:creativeId];
    
    [_preloader startPreloading:preloadingObject];
}

- (void)updateLogWithString:(NSString *)text {
    self.textView.text = [NSString stringWithFormat:@"%@%@%@", text, LOG_SPACER, self.textView.text];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark PHPreloader delegate methods

- (void)itemDidStartProcessing:(PHPreloadingObject *)item sender:(id)sender {
    [self updateLogWithString:[NSString stringWithFormat:@"Started downloading %@ (%@)", item.cacheObject.fileName, [item.cacheObject.url absoluteString]]];
    self.fileDownloading.text = item.cacheObject.fileName;
}

- (void)itemDidFinishProcessing:(PHPreloadingObject *)item sender:(id)sender {
    [self updateLogWithString:[NSString stringWithFormat:@"Finished downloading %@", item.cacheObject.fileName]];
    [self getCachedFiles];
    self.fileDownloading.text = @"";
    self.progressView.progress = 0.0;
}

- (void)itemDidFailToProcess:(PHPreloadingObject *)item error:(NSError *)error sender:(id)sender {
    [self updateLogWithString:[NSString stringWithFormat:@"Failed to download %@: %@", item.cacheObject.fileName, error]];
    self.fileDownloading.text = @"";
    self.progressView.progress = 0.0;
}

- (void)itemDidReceiveData:(PHPreloadingObject *)item sender:(id)sender {
    self.progressView.progress = item.percentLoaded / 100.0;
}

#pragma mark -
#pragma mark UITableView delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _cachedFiles.count;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        PHCacheObject *cacheObject = [_cachedFiles objectAtIndex:indexPath.row];
        [_preloader removeFileWithId:cacheObject.creativeId];
        [self updateLogWithString:[NSString stringWithFormat:@"%@ deleted! (ID: %li)", cacheObject.fileName, (long)cacheObject.creativeId]];
        [self getCachedFiles];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Set the data for this cell:
    
    PHCacheObject *cacheObject = [_cachedFiles objectAtIndex:indexPath.row];
    cell.textLabel.text = cacheObject.fileName;
    cell.detailTextLabel.font = [UIFont systemFontOfSize:10];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"ID: %li (%@)", (long)cacheObject.creativeId, [PHPreloader getFullPathFromCreativeId:cacheObject.creativeId]];
    
    // set the accessory view:
    // cell.accessoryType =  UITableViewCellEditingStyleDelete;
    
    return cell;
}

#pragma mark -
#pragma mark PHCacheCreativeRequest delegate methods

- (void)cacheRequestDidFinishLoading:(id)sender request:(PHAPIRequest *)request {
    NSLog(@"cacheRequestDidFinishLoading: %@", request);
}

- (void)cacheRequest:(id)sender request:(PHAPIRequest *)request didSucceedWithResponse:(NSDictionary *)responseData {
    [self updateLogWithString:[NSString stringWithFormat:@"cacheCreative response received: %@", responseData]];
   
    NSMutableArray *currentCacheIds = [[NSMutableArray alloc] init];
    for (NSDictionary *cacheItem in [responseData objectForKey:@"cache"]) {
        if ([cacheItem objectForKey:@"url"]) {
            [currentCacheIds addObject:[cacheItem objectForKey:@"creative_id"]];
        }
    }
    
    [self updateLogWithString:[NSString stringWithFormat:@"Cache should include the id(s): %@", [currentCacheIds componentsJoinedByString:@", "]]];
    
    NSArray *savedFiles = [PHPreloader newSavedFilesArray];
    NSMutableArray *staleCacheItems = [[NSMutableArray alloc] init];
    for (PHCacheObject *cacheObject in savedFiles) {
        if (![currentCacheIds containsObject:[NSNumber numberWithInteger:cacheObject.creativeId]]) {
            [staleCacheItems addObject:[NSNumber numberWithInteger:cacheObject.creativeId]];
        }
    }
    
    [self updateLogWithString:[NSString stringWithFormat:@"Deleting cache item(s): %@", [staleCacheItems componentsJoinedByString:@", "]]];
    
    [self getCachedFiles];
}

- (void)cacheRequest:(id)sender request:(PHAPIRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError: %@", error);
}

#pragma mark -
#pragma mark PHPreloadingObject notifications

- (void)itemDidStartPreloading:(NSNotification *)notification {
    PHPreloadingObject *preloadingObject = notification.object;
    [self updateLogWithString:[NSString stringWithFormat:@"Started downloading: %@ (%li)", preloadingObject.cacheObject.fileName, (long)preloadingObject.cacheObject.creativeId]];
}

- (void)itemDidFinishPreloading:(NSNotification *)notification {
    PHPreloadingObject *preloadingObject = notification.object;
    self.progressView.progress = 0.0;
    [self updateLogWithString:[NSString stringWithFormat:@"Finished downloading: %@ (%li)", preloadingObject.cacheObject.fileName, (long)preloadingObject.cacheObject.creativeId]];
    [self getCachedFiles];
}

- (void)itemDidFailToPreloading:(NSNotification *)notification {
    PHPreloadingObject *preloadingObject = notification.object;
    self.fileDownloading.text = @"";
    self.progressView.progress = 0.0;
    [self updateLogWithString:[NSString stringWithFormat:@"Failed to download %@ (%li): %@", preloadingObject.cacheObject.fileName, (long)preloadingObject.cacheObject.creativeId, preloadingObject.error]];
}

- (void)itemDidReceiveData:(NSNotification *)notification {
    PHPreloadingObject *preloadingObject = notification.object;
    self.fileDownloading.text = preloadingObject.cacheObject.fileName;
    self.progressView.progress = preloadingObject.percentLoaded / 100.0;
}

#pragma mark -
#pragma mark UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self downloadFileWithURL:[NSURL URLWithString:self.urlTextField.text] creativeId:345];
    [textField resignFirstResponder];
    return YES;
}

@end
