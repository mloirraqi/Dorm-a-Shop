//
//  SearchViewController.m
//  Dorm-a-Shop
//
//  Created by addisonz on 7/22/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "SearchViewController.h"
#import "ProfileViewController.h"
#import "ParseDatabaseManager.h"
#import "CoreDataManager.h"
#import "UserCollectionCell.h"
@import Parse;

@interface SearchViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UIButton *mapButton;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UITextField *searchField;
@property (weak, nonatomic) IBOutlet UILabel *searchPlaceholder;

@property (strong, nonatomic) NSMutableArray *users;
@property (strong, nonatomic) NSMutableArray *filteredUsers;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end

@implementation SearchViewController

//View Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];

// TO DO! Gradient needs changing
//    CAGradientLayer *gradient = [CAGradientLayer layer];
//    gradient.frame = self.view.bounds;
//    UIColor* gradient1 = [UIColor colorWithRed:58.0f/255.0f green:95.0f/255.0f blue:236.0f/255.0f alpha:1.0f];
//    UIColor* gradient2 = [UIColor colorWithRed:141.0f/255.0f green:61.0f/255.0f blue:244.0f/255 alpha:1.0f];
//    gradient.colors = @[(id)gradient1.CGColor, (id)gradient2.CGColor];
//    [self.view.layer insertSublayer:gradient atIndex:0];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.alwaysBounceVertical = YES;

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(queryUsersFromParse) forControlEvents:UIControlEventValueChanged];
    [self.collectionView insertSubview:self.refreshControl atIndex:0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"DoneSavingUsers" object:nil];
    
    [self.searchField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    self.searchField.layer.cornerRadius = 20.0f;
    self.searchField.layer.masksToBounds = YES;
    self.searchField.delegate = self;
    self.searchField.layer.borderWidth = 1.0f;
    self.searchField.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    
    self.searchField.leftViewMode = UITextFieldViewModeAlways;
    UIView* searchRightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 28, 40)];
    UIImageView* searchIcon = [[UIImageView alloc] initWithFrame:CGRectMake(8, 10, 20, 20)];
    searchIcon.image = [UIImage imageNamed:@"search_bar_search"];
    searchIcon.contentMode = UIViewContentModeScaleAspectFit;
    [searchRightView addSubview:searchIcon];
    self.searchField.leftView = searchRightView;
    
    self.searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    self.mapButton.layer.cornerRadius = 20.0f;
    
    [self fetchUsersFromCoreData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self navigationController] setNavigationBarHidden:YES animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.collectionView reloadData];
    [self fetchUsersFromCoreData];
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([[notification name] isEqualToString:@"DoneSavingUsers"]) {
        [self fetchUsersFromCoreData];
    }
}

- (void)fetchUsersFromCoreData {
    self.users = [[CoreDataManager shared] getAllUsersInRadiusFromCoreData];
    [self filterUsers];
    [self.collectionView reloadData];
}

- (void)queryUsersFromParse {
    __weak SearchViewController *weakSelf = self;
    [[ParseDatabaseManager shared] queryAllUsersWithinKilometers:5.0 withCompletion:^(NSMutableArray<UserCoreData *> * users, NSError * error) {
        if (users) {
            weakSelf.users = [NSMutableArray arrayWithArray:users];
            [weakSelf filterUsers];
            [weakSelf.collectionView reloadData];
            [weakSelf.refreshControl endRefreshing];
        } else {
            NSLog(@"😫😫😫 Error getting home timeline: %@", error.localizedDescription);
        }
    }];
}

- (void)filterUsers {
    self.filteredUsers = self.users;
    if (self.searchField.text.length != 0) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(UserCoreData *user, NSDictionary *bindings) {
            return ([user.username localizedCaseInsensitiveContainsString:self.searchField.text]);
        }];
        self.filteredUsers = [NSMutableArray arrayWithArray:[self.filteredUsers filteredArrayUsingPredicate:predicate]];
    }
    [self.collectionView reloadData];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UserCollectionCell* cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"UserCollectionCell" forIndexPath:indexPath];
    UserCoreData *user = self.filteredUsers[indexPath.item];
    cell.user = user;
    [cell setUser];
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.filteredUsers.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = collectionView.frame.size.width/3;
    return CGSizeMake(width, width + 70); //70 is size of two labels
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionView *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

//Textfield
- (BOOL) textField: (UITextField *)theTextField shouldChangeCharactersInRange: (NSRange)range replacementString: (NSString *)string {
    
    NSRange textFieldRange = NSMakeRange(0, [self.searchField.text length]);
    // Check If textField is empty. If empty align your text field to center, so that placeholder text will show center aligned
    if (NSEqualRanges(range, textFieldRange) && [string length] == 0) {
        [self.searchPlaceholder setHidden:NO];
    }
    else //else align textfield to left.
    {
        [self.searchPlaceholder setHidden:YES];
    }
    return YES;
}

- (void)textFieldDidChange:(UITextField *)textField {
    [self filterUsers];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.searchField resignFirstResponder];
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"userDeets"]) {
        UserCollectionCell *tappedCell = sender;
        ProfileViewController *profileViewController = [segue destinationViewController];
        profileViewController.user = (UserCoreData *)tappedCell.user;
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:tappedCell];
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
}

@end
