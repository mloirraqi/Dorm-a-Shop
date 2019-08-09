//
//  MapsVC.m
//  Dorm-a-Shop
//
//  Created by mloirraqi on 8/04/2019.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "MapsVC.h"
#import "MapsPopupVC.h"
#import "CoreDataManager.h"
#import "ParseDatabaseManager.h"
@import Parse;

@interface MapsVC ()
@property (weak, nonatomic) IBOutlet UIView *mapView;
@property (strong, nonatomic) NSMutableArray *users;
@property (strong, nonatomic) GMSCameraPosition *camera;
@end

@implementation MapsVC {
    GMSMapView *gmapView;
    NSMutableSet* addedMarkers;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    addedMarkers = [[NSMutableSet alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupMaps];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self fetchUsers];
}

- (void)setupMaps {
    
    User *currentUser = (User *)[PFUser currentUser];
    
    CGFloat lat = currentUser.Location.latitude;
    CGFloat lng = currentUser.Location.longitude;
    
    self.camera = [GMSCameraPosition cameraWithLatitude:lat longitude:lng zoom:4];
    gmapView = [GMSMapView mapWithFrame:self.mapView.bounds camera:_camera];
    gmapView.myLocationEnabled = YES;
    gmapView.delegate = self;
    [self.mapView addSubview:gmapView];
    
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(lat, lng);
    
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(lat, lng);
    
    GMSCircle *circ = [GMSCircle circleWithPosition:center radius:2.5 * 1000]; //5km
    circ.fillColor = [UIColor clearColor];
    circ.strokeColor = [UIColor redColor];
    circ.strokeWidth = 2.6;
    circ.map = gmapView;
    
}

- (void)fetchUsers {
    __weak MapsVC *weakSelf = self;
    [[ParseDatabaseManager shared] queryAllUsersWithinKilometers:5.0 withCompletion:^(NSMutableArray<UserCoreData *> * users, NSError * error) {
        if (users) {
            weakSelf.users = [NSMutableArray arrayWithArray:users];
            [weakSelf populateMarkers];
        } else {
            NSLog(@"😫😫😫 Error getting home timeline: %@", error.localizedDescription);
        }
    }];
}

- (void)populateMarkers {
    
    NSLog(@"users count: %lu", (unsigned long)self.users.count);
    
    NSCharacterSet* mySet = [NSCharacterSet characterSetWithCharactersInString:@",-.0123456789"];
    
    NSMutableArray *markers = [[NSMutableArray alloc] init];
    
    for (UserCoreData* user in self.users) {
        
        NSString *latLongStr = [[user.location componentsSeparatedByCharactersInSet:[mySet invertedSet]] componentsJoinedByString:@""];
        NSArray *latLong = [latLongStr componentsSeparatedByString:@","];
        CGFloat lat = [latLong[0] doubleValue];
        CGFloat lng = [latLong[1] doubleValue];
        
        //if same lat long obj exists, add a minor offset so markers do not overlap
        if ([addedMarkers containsObject:latLongStr]) {
            CGFloat r = arc4random_uniform(999) - 500; //random from -499 to 499
            lat = lat + (r*0.0000001);
            lng = lng + (r*0.0000001);
        } else {
            [addedMarkers addObject:latLongStr];
        }
        
        UIImageView* imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40.0f, 40.0f)];
        [imgView setImage:[UIImage imageWithData:user.profilePic]];
        [imgView setContentMode:UIViewContentModeScaleAspectFill];
        [imgView setClipsToBounds:YES];
        imgView.layer.cornerRadius = 20.0f;
        
        GMSMarker *marker = [[GMSMarker alloc] init];
        marker.position = CLLocationCoordinate2DMake(lat, lng);
        marker.iconView = imgView;
        marker.map = gmapView;
        marker.userData = user;
        
        [markers addObject:marker];
    }
    CLLocationCoordinate2D myLocation = ((GMSMarker *)markers.firstObject).position;
    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:myLocation coordinate:myLocation];
    
    for (GMSMarker *marker in markers)
        bounds = [bounds includingCoordinate:marker.position];
    
    [gmapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:bounds withPadding:15.0f]];
}


//Delegates
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    //NSLog(@"Updated Location");
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker {
    
    UserCoreData* user = (UserCoreData*)marker.userData;
    
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    MapsPopupVC* controller = [storyboard instantiateViewControllerWithIdentifier:@"MapsPopupVC"];
    controller.userCoreData = user;
    
    controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [controller setModalTransitionStyle: UIModalTransitionStyleCrossDissolve];
    
    [self presentViewController:controller animated:YES completion:nil];
    
    return YES;
}


@end
