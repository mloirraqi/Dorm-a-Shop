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
    GMSCircle *circ;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    addedMarkers = [[NSMutableSet alloc] init];
    self.navigationItem.title = @"Nearby Users";
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
    
    circ = [GMSCircle circleWithPosition:center radius:2.5 * 1000]; //5km
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
    }

[gmapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:[self boundsOfCircle] withPadding:0.0f]];}

- (GMSCoordinateBounds*)boundsOfCircle {
    CLLocationCoordinate2D c1 = [self coordinatesMaxMin:YES];
    CLLocationCoordinate2D c2 = [self coordinatesMaxMin:NO];
    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc]
                                   initWithCoordinate:c1
                                   coordinate:c2];
    return bounds;
}

- (CLLocationCoordinate2D)coordinatesMaxMin:(BOOL)flag {
    CGFloat radius = circ.radius;
    CGFloat sign = flag ? 1 : -1;
    CGFloat dx = sign * radius / 6378000 * (180/M_PI); //6378000 is the radius of circle with string around Earth
    CGFloat lat = circ.position.latitude + dx;
    CGFloat lng = circ.position.longitude + dx / cos(circ.position.latitude * M_PI/180);
    return CLLocationCoordinate2DMake(lat, lng);
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
