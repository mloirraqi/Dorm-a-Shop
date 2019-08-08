//
//  SwipePopupVC.m
//  Dorm-a-Shop
//
//  Created by mloirraqi on 8/8/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "SwipePopupVC.h"
#import "CardItemCollectionViewCell.h"

@interface SwipePopupVC ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *profilePicture;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIButton *viewProfileButton;


@end

@implementation SwipePopupVC {
    NSArray* postsArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    
    postsArray = [self.userCoreData.post allObjects];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)tapped:(UITapGestureRecognizer *)recognizer {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//Labels & Views
-(void)setupViews {
    [self.titleLabel    setText:_userCoreData.username];
    [self.subtitleLabel setText:_userCoreData.address];
    [self.profilePicture setImage:[UIImage imageWithData:self.userCoreData.profilePic]];
    self.profilePicture.layer.cornerRadius = 50;
    self.profilePicture.layer.masksToBounds = YES;


    
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
    self.backgroundView.layer.backgroundColor = [[UIColor blueColor]CGColor];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([segue.identifier isEqualToString:@"userDetails"]) {
//        UserCollectionCell *tappedCell = sender;
//        ProfileViewController *profileViewController = [segue destinationViewController];
//        profileViewController.user = (UserCoreData *)tappedCell.user;
//        NSIndexPath *indexPath = [self.collectionView indexPathForCell:tappedCell];
//        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
//    }
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isEqual:self.view]) {
        return YES;
    }
    return NO;
}

@end
