//
//  MapsPopupVC.m
//  Dorm-a-Shop
//
//  Created by mloirraqi on 8/04/2019.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "MapsPopupVC.h"
#import "CardItemCollectionViewCell.h"
#import "ProfileViewController.h"

@interface MapsPopupVC ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *noItemsToShowLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@end

@implementation MapsPopupVC {
    NSArray* postsArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    [self setupCollectionView];
    
    postsArray = [self.userCoreData.post allObjects];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)tapped:(UITapGestureRecognizer *)recognizer {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)titleLabelTapped:(UITapGestureRecognizer *)sender {
    NSLog(@"tit tapped");
    
    UINavigationController* profileViewNavController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"profilePageNav"];
    ProfileViewController* profileViewController = [[profileViewNavController viewControllers] firstObject];
    profileViewController.user = _userCoreData;
    [self presentViewController:profileViewNavController animated:YES completion:nil];
}

//Labels & Views
-(void)setupViews {
    [self.titleLabel    setText:_userCoreData.username];
    [self.subtitleLabel setText:_userCoreData.address];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    tapGestureRecognizer.delegate = self;

    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    self.containerView.layer.cornerRadius = 8;
    self.containerView.layer.masksToBounds = NO;
    self.containerView.layer.borderWidth = 1.0;
    self.containerView.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.containerView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.containerView.layer.shadowOffset = CGSizeMake(0, 0);
    self.containerView.layer.shadowOpacity = 0.4;
    self.containerView.layer.shadowRadius = 4;
}

//Collection View
-(void)setupCollectionView {
    CGRect collectionViewFrame = self.collectionView.frame;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(collectionViewFrame.size.width/3, collectionViewFrame.size.width/3);
    flowLayout.minimumLineSpacing = 0;
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.sectionInset = UIEdgeInsetsZero;
    
    self.collectionView.collectionViewLayout = flowLayout;
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"CardItemCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"cardItemCell"];
    
    self.collectionView.allowsSelection = NO;
    
    [self.collectionView reloadData];
    
}

//Delegate & Datasource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSUInteger count = postsArray.count;
    [self.noItemsToShowLabel setHidden:(count > 0)];
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *kCardItemCell = @"cardItemCell";
    CardItemCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCardItemCell forIndexPath:indexPath];
    cell.post = postsArray[indexPath.row];
    return cell;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isEqual:self.view]) {
        return YES;
    }
    return NO;
}

@end
