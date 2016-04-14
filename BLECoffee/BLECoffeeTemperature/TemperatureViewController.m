//
//  TemperatureViewController.m
//  BLETemperatureReader
//
//  Created by Evan Stone on 8/7/15.
//  Copyright (c) 2015 Cloud City. All rights reserved.
//

#import "TemperatureViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "AppDelegate.h"
#import "Constants.h"

#define TIMER_PAUSE_INTERVAL 10.0
#define TIMER_SCAN_INTERVAL  2.0
#define SENSOR_DATA_INDEX_TEMP_INFRARED 0
#define SENSOR_DATA_INDEX_TEMP_AMBIENT  1
#define DEFAULT_INITIAL_TEMP -9999

// This could be simplified to "SensorTag" and check if it's a substring.
// (Probably a good idea to do that if you're using a different model of the SensorTag.)
#define SENSOR_TAG_NAME @"CC2650 SensorTag"

@interface TemperatureViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>

// Properties for Background Swapping
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView1;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView2;
@property (nonatomic, strong) NSArray *backgroundImageViews;
@property (nonatomic, assign) NSInteger visibleBackgroundIndex;
@property (nonatomic, assign) NSInteger invisibleBackgroundIndex;
@property (nonatomic, assign) NSInteger lastTemperatureTens;
@property (nonatomic, assign) NSInteger lastTemperature;

@property (weak, nonatomic) IBOutlet UIView *controlContainerView;
@property (weak, nonatomic) IBOutlet UIView *circleView;
@property (weak, nonatomic) IBOutlet UILabel *captionLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *sensorTag;
@property (nonatomic, assign) BOOL keepScanning;

@end

@implementation TemperatureViewController {
    BOOL circleDrawn;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.lastTemperature = DEFAULT_INITIAL_TEMP;

    // presentation
    // Create the CBCentralManager.
    // NOTE: Creating the CBCentralManager with initWithDelegate will immediately call centralManagerDidUpdateState.
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    
    // configure our initial UI
    self.captionLabel.hidden = YES;
    self.temperatureLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:56];
    self.temperatureLabel.text = @"Searching";

    circleDrawn = NO;
    self.circleView.hidden = YES;
    self.lastTemperatureTens = 0;
    self.visibleBackgroundIndex = 0;
    self.invisibleBackgroundIndex = 1;
    self.backgroundImageViews = [NSArray arrayWithObjects:self.backgroundImageView1, self.backgroundImageView2, nil];
    [self.view bringSubviewToFront:(UIView *)self.backgroundImageViews[self.visibleBackgroundIndex]];
    ((UIView *)self.backgroundImageViews[self.visibleBackgroundIndex]).alpha = 1;
    ((UIView *)self.backgroundImageViews[self.invisibleBackgroundIndex]).alpha = 0;
    [self.view bringSubviewToFront:self.controlContainerView];
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.lastTemperature != DEFAULT_INITIAL_TEMP) {
        [self updateTemperatureDisplay];
    }
}

- (void)pauseScan {
    // Scanning uses up battery on phone, so pause the scan process for the designated interval.
    NSLog(@"*** PAUSING SCAN...");
    [NSTimer scheduledTimerWithTimeInterval:TIMER_PAUSE_INTERVAL target:self selector:@selector(resumeScan) userInfo:nil repeats:NO];
    [self.centralManager stopScan];
}

- (void)resumeScan {
    if (self.keepScanning) {
        // Start scanning again...
        NSLog(@"*** RESUMING SCAN!");
        [NSTimer scheduledTimerWithTimeInterval:TIMER_SCAN_INTERVAL target:self selector:@selector(pauseScan) userInfo:nil repeats:NO];
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    }
}


#pragma mark - Updating UI

- (void)updateTemperatureDisplay {
    if (!circleDrawn) {
        [self drawCircle];
    }
    
    // Use the IR Temperature reading for our label
    [self setBackgroundImageForTemperature:self.lastTemperature];
    self.captionLabel.hidden = NO;
    self.temperatureLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:81];
    self.temperatureLabel.text = [NSString stringWithFormat:@" %ld°", (long)self.lastTemperature];
}

- (void)drawCircle {
    self.circleView.hidden = NO;
    CAShapeLayer *circleLayer = [CAShapeLayer layer];
    [circleLayer setPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, self.circleView.bounds.size.width, self.circleView.bounds.size.height)] CGPath]];
    [[self.circleView layer] addSublayer:circleLayer];
    [circleLayer setLineWidth:2];
    [circleLayer setStrokeColor:[UIColor whiteColor].CGColor];
    [circleLayer setFillColor:[UIColor clearColor].CGColor];
    circleDrawn = YES;
}

- (void)setBackgroundImageForTemperature:(NSInteger)temperature {
    NSInteger temperatureToTens = 10;
    if (temperature > 19) {
        if (temperature > 99) {
            temperatureToTens = 100;
        } else {
            temperatureToTens = 10 * floor( temperature / 10 + 0.5 );
        }
    }
    
    if (temperatureToTens != self.lastTemperatureTens) {
        NSString *temperatureFilename = [NSString stringWithFormat:@"temp-%ld", temperatureToTens];
        NSLog(@"*** BACKGROUND FILENAME: %@", temperatureFilename);
        
        // fade out old, fade in new.
        UIImageView *visibleBackground = self.backgroundImageViews[self.visibleBackgroundIndex];
        UIImageView *invisibleBackground = self.backgroundImageViews[self.invisibleBackgroundIndex];
        invisibleBackground.image = [UIImage imageNamed:temperatureFilename];
        invisibleBackground.alpha = 0;
        [self.view bringSubviewToFront:invisibleBackground];
        [self.view bringSubviewToFront:self.controlContainerView];
        
        [UIView animateWithDuration:0.5 animations:^{
            // "crossfade" the two images
            invisibleBackground.alpha = 1;
        } completion:^(BOOL finished) {
            // rotate the indices: if it was 1 before now it's 0 and vice versa...
            visibleBackground.alpha = 0;
            NSInteger indexTemp = self.visibleBackgroundIndex;
            self.visibleBackgroundIndex = self.invisibleBackgroundIndex;
            self.invisibleBackgroundIndex = indexTemp;
            NSLog(@"**** NEW INDICES - visible: %ld - invisible: %ld", (long)self.visibleBackgroundIndex, (long)self.invisibleBackgroundIndex);
        }];
    }
}


#pragma mark - CBCentralManagerDelegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    BOOL showAlert = YES;
    NSString *state = @"";
    switch ([central state])
    {
        case CBCentralManagerStateUnsupported:
            state = @"This device does not support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"This app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth on this device is currently powered off.";
            break;
        case CBCentralManagerStateResetting:
            state = @"The BLE Manager is resetting; a state update is pending.";
            break;
        // presentation
        case CBCentralManagerStatePoweredOn:
        {
            showAlert = NO;
            state = @"Bluetooth LE is turned on and ready for communication.";
            NSLog(@"%@", state);
            self.keepScanning = YES;
            [NSTimer scheduledTimerWithTimeInterval:TIMER_SCAN_INTERVAL target:self selector:@selector(pauseScan) userInfo:nil repeats:NO];
            
            // Initiate Scan for Peripherals
            //Option 1: Scan for all devices
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
            
            // Option 2: Scan for devices that have the service you're interested in...
            //CBUUID *temperatureServiceUUID = [CBUUID UUIDWithString:UUID_TEMPERATURE_SERVICE];
            //[self.centralManager scanForPeripheralsWithServices:@[temperatureServiceUUID] options:nil];
            
            break;
        }
        case CBCentralManagerStateUnknown:
            state = @"The state of the BLE Manager is unknown.";
            break;
        default:
            state = @"The state of the BLE Manager is unknown.";
            
    }
    
    if (showAlert) {
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Central Manager State"
                                                                    message:state
                                                             preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
        [ac addAction:okAction];
        [self presentViewController:ac animated:YES completion:nil];
    }
    
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {

    // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
    NSString *peripheralName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
    NSLog(@"NEXT PERIPHERAL: %@", peripheral.identifier.UUIDString);
    NSLog(@"NEXT PERIPHERAL NAME: %@", peripheralName);
    
    if (peripheralName) {
        if ([peripheralName isEqualToString:SENSOR_TAG_NAME]) {
            NSLog(@"SENSOR TAG FOUND! ADDING NOW!!!");
            self.keepScanning = NO;
            
            // save a reference to the sensor tag
            self.sensorTag = peripheral;
            self.sensorTag.delegate = self;
            
            // Request a connection to the peripheral
            [self.centralManager connectPeripheral:self.sensorTag options:nil];
        }
    }
}


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"**** SUCCESSFULLY CONNECTED TO SENSOR TAG!!!");

    self.temperatureLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:56];
    self.temperatureLabel.text = @"Connected";

    // Now that we've successfully connected to the SensorTag, let's discover the services.
    // - NOTE:  we pass nil here to request ALL services be discovered.
    //          If there was a subset of services we were interested in, we could pass the UUIDs here.
    //          Doing so saves battery life and saves time.
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"**** CONNECTION FAILED!!!");
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"**** DISCONNECTED FROM SENSOR TAG!!!");
    if (error) {
        NSLog(@"****** DISCONNECTION DETAILS: %@", error.localizedDescription);
    }
}


#pragma mark - CBPeripheralDelegate methods

// When the specified services are discovered, the peripheral calls the peripheral:didDiscoverServices: method of its delegate object.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service %@", service);
        if ([service.UUID isEqual:[CBUUID UUIDWithString:UUID_TEMPERATURE_SERVICE]]) {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    for (CBCharacteristic *characteristic in service.characteristics) {
        // Temperature Data Characteristic
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_TEMPERATURE_DATA]]) {
            // Enable the IR Temperature Sensor notifications
            [self.sensorTag setNotifyValue:YES forCharacteristic:characteristic];
        }

        // Temperature Configuration Characteristic
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_TEMPERATURE_CONFIG]]) {
            // Enable IR Temperature Sensor
            uint8_t enableValue = 1;
            NSData *enableBytes = [NSData dataWithBytes:&enableValue length:sizeof(uint8_t)];
            [self.sensorTag writeValue:enableBytes forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        }
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error changing notification state: %@", [error localizedDescription]);
    } else {
        // extract the data from the characteristic's value property and display the value based on the characteristic type
        NSData *dataBytes = characteristic.value;
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_TEMPERATURE_DATA]]) {
            [self calculateTemperature:dataBytes];
        }
    }
}


#pragma mark - TI Sensor Tag Utility Methods

- (double)fahrenheitFromCelsius:(double)celsius {
    double fahrenheit = (celsius * 1.8) + 32;
    return fahrenheit;
}

- (void)calculateTemperature:(NSData *)dataBytes {

    // We'll get four bytes of data back, so we divide the byte count by two
    // because we're creating an array that holds two 16-bit (two-byte) values
    NSUInteger dataLength = dataBytes.length / 2;
    int16_t dataArray[dataLength];
    for (int i = 0; i < dataLength; i++) {
        dataArray[i] = 0;
    }
    [dataBytes getBytes:&dataArray length:dataLength * sizeof(uint16_t)];
    
    // log the bytes
    for (int i=0; i < dataLength; i++) {
        uint16_t nextInt = dataArray[i];
        NSLog(@"NEXT BYTE: %d", nextInt);
    }
    
    uint16_t rawAmbientTemp = dataArray[SENSOR_DATA_INDEX_TEMP_AMBIENT];
    double ambientTempC = ((double)rawAmbientTemp)/128;
    double ambientTempF = [self fahrenheitFromCelsius:ambientTempC];
    NSLog(@"*** AMBIENT TEMPERATURE SENSOR (C/F): %f/%f", ambientTempC, ambientTempF);
    
    uint16_t rawInfraredTemp = dataArray[SENSOR_DATA_INDEX_TEMP_INFRARED];
    double infraredTempC = ((double)rawInfraredTemp)/128;
    double infraredTempF = [self fahrenheitFromCelsius:infraredTempC];
    NSLog(@"*** INFRARED TEMPERATURE SENSOR (C/F): %f/%f", infraredTempC, infraredTempF);
    
    NSInteger temp = (NSInteger)infraredTempF;
    self.lastTemperature = temp;
    NSLog(@"*** LAST TEMPERATURE CAPTURED: %d F", temp);

    // check to see if the app is active - if so, then update UI...
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if ((appDelegate.isActive) && (!appDelegate.isBackgrounded)) {
        [self updateTemperatureDisplay];
    }
}






@end
