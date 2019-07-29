//
//  LocationManager.h
//  
//
//  Created by mloirraqi on 7/23/19.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LocationManager : NSObject <CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
}

@property (strong, nonatomic) NSString *longitude;
@property (strong, nonatomic) NSString *latitude;
@property (strong, nonatomic) CLLocation *currentLocation;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
