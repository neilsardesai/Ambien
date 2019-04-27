//
//  ViewController.m
//  Ambien
//
//  Created by Neil Sardesai on 4/24/19.
//  Copyright © 2019 Neil Sardesai. All rights reserved.
//

#import "ViewController.h"
#include <mach/mach.h>
#import <IOKit/IOKitLib.h>
#import <CoreFoundation/CoreFoundation.h>

static double updateInterval = 0.1;
static io_connect_t dataPort = 0;
static NSString *switchingThresholdKey = @"switchingThresholdKey";

@interface ViewController()
@property (weak) IBOutlet NSTextField *ambientLightSensorReadingLabel;
@property (weak) IBOutlet NSTextField *switchingThresholdTextField;
@property (nonatomic, assign) BOOL isInDarkMode;
@end

@implementation ViewController

id thisClass;
NSInteger switchingThreshold = -1;

// MARK: Lifecycle

- (IBAction)updateSwitchingThreshold:(NSTextField *)sender {
    switchingThreshold = sender.integerValue;
    [[NSUserDefaults standardUserDefaults] setInteger:switchingThreshold forKey:switchingThresholdKey];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self performInitialSetup];
}

- (void)performInitialSetup {
    thisClass = self;
    
    NSString *currentInterfaceStyle = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    if ([currentInterfaceStyle isEqualToString:@"Dark"]) {
        self.isInDarkMode = YES;
    }
    else {
        self.isInDarkMode = NO;
    }
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:switchingThresholdKey] == 0) {
        [[NSUserDefaults standardUserDefaults] setInteger:1500000 forKey:switchingThresholdKey];
    }
    switchingThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:switchingThresholdKey];
    self.switchingThresholdTextField.stringValue = [NSString stringWithFormat:@"%ld", (long)switchingThreshold];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        beginMonitoringAmbientLight();
    });
}

- (void)setDarkMode {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isInDarkMode) { return; }
        NSLog(@"Switching to dark mode");
        NSString *script = @"tell application \"System Events\"\ntell appearance preferences\nset dark mode to true\nend tell\nend tell";
        [[[NSAppleScript alloc] initWithSource:script] executeAndReturnError:nil];
        self.isInDarkMode = YES;
    });
}

- (void)setLightMode {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isInDarkMode) { return; }
        NSLog(@"Switching to light mode");
        NSString *script = @"tell application \"System Events\"\ntell appearance preferences\nset dark mode to false\nend tell\nend tell";
        [[[NSAppleScript alloc] initWithSource:script] executeAndReturnError:nil];
        self.isInDarkMode = NO;
    });
}

- (void)updateAmbientLightSensorReadingLabelWithSensorReading:(uint64_t)sensorReading {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *formattedSensorReading = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithUnsignedLongLong:sensorReading] numberStyle:NSNumberFormatterDecimalStyle];
        self.ambientLightSensorReadingLabel.stringValue = [NSString stringWithFormat:@"Ambient light: %@", formattedSensorReading];
    });
}

// MARK: Scary C Stuff

void beginMonitoringAmbientLight() {
    kern_return_t kr;
    io_service_t serviceObject;
    CFRunLoopTimerRef updateTimer;
    
    serviceObject = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleLMUController"));
    if (!serviceObject) {
        fprintf(stderr, "failed to find ambient light sensors\n");
        exit(1);
    }
    
    kr = IOServiceOpen(serviceObject, mach_task_self(), 0, &dataPort);
    IOObjectRelease(serviceObject);
    if (kr != KERN_SUCCESS) {
        mach_error("IOServiceOpen:", kr);
        exit(kr);
    }
    
    setbuf(stdout, NULL);
    printf("%8ld %8ld", 0L, 0L);
    
    updateTimer = CFRunLoopTimerCreate(kCFAllocatorDefault,
                                       CFAbsoluteTimeGetCurrent() + updateInterval, updateInterval,
                                       0, 0, updateTimerCallBack, NULL);
    CFRunLoopAddTimer(CFRunLoopGetCurrent(), updateTimer, kCFRunLoopDefaultMode);
    CFRunLoopRun();
}

void updateTimerCallBack(CFRunLoopTimerRef timer, void *info) {
    kern_return_t kr;
    uint32_t outputs = 2;
    uint64_t values[outputs];
    
    kr = IOConnectCallMethod(dataPort, 0, nil, 0, nil, 0, values, &outputs, nil, 0);
    if (kr == KERN_SUCCESS) {
        //printf("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b%8lld %8lld", values[0], values[1]);
        uint64_t average = (values[0] + values[1])/2;
        if (average > switchingThreshold) {
            setLightMode(thisClass, average);
        }
        else {
            setDarkMode(thisClass, average);
        }
        return;
    }
    
    if (kr == kIOReturnBusy) {
        return;
    }
    
    mach_error("I/O Kit error:", kr);
    exit(kr);
}

void setDarkMode(id param, uint64_t sensorReading) {
    [param updateAmbientLightSensorReadingLabelWithSensorReading:sensorReading];
    [param setDarkMode];
}

void setLightMode(id param, uint64_t sensorReading) {
    [param updateAmbientLightSensorReadingLabelWithSensorReading:sensorReading];
    [param setLightMode];
}

@end
