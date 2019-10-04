//
//  Termite.m
//  Termite
//
//  Created by Jeremy Legendre on 10/2/19.
//  Copyright © 2019 Jeremy Legendre. All rights reserved.
//

#import "Termite.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface Termite()
@end


@implementation Termite

/**
 * @return the single static instance of the plugin object
 */
+ (instancetype)sharedInstance {
    static Termite *plugin = nil;
    @synchronized(self) {
        if (!plugin) {
            plugin = [[self alloc] init];
        }
    }
    return plugin;
}

void mouse_entered(id self, SEL cmd, NSEvent *event) {
    CGPoint p = CGEventGetLocation([event CGEvent]);
    CGEventRef leftDown = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, CGPointMake(p.x, p.y), kCGMouseButtonLeft);
    CGEventPost(kCGHIDEventTap, leftDown);
    CFRelease(leftDown);
    
    usleep(10);

    CGEventRef leftUp = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, CGPointMake(p.x, p.y), kCGMouseButtonLeft);
    CGEventPost(kCGHIDEventTap, leftUp);
    CFRelease(leftUp);
}

- (NSWindow *)getBTWindow {
    CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID);
    NSArray *myArray=[(__bridge NSArray *)windowList copy];
    for (int i = 0; i < myArray.count; i++) {
        NSDictionary *winInfo = [myArray objectAtIndex:i];
        if ([[winInfo objectForKey:@"kCGWindowLayer"] integerValue] == 25) {
            NSString* appName = [winInfo objectForKey:@"kCGWindowOwnerName"];
            if ([appName isEqualToString:@"Bartender 3"]) {
                NSNumber *winNumber = [winInfo objectForKey:@"kCGWindowNumber"];
                return [NSApp windowWithWindowNumber:[winNumber integerValue]];
            }
        }
    }
    
    return NULL;
}

- (void)addMouseEnterTrackingToWindow:(NSWindow *)window callback:(IMP)callback {
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:[window.contentView frame] options:NSTrackingMouseEnteredAndExited | NSTrackingInVisibleRect | NSTrackingActiveAlways owner:window.contentView userInfo:nil];
    [window.contentView addTrackingArea:area];
    Class btWindowClass = object_getClass(window);
    class_addMethod(btWindowClass, sel_registerName("mouseEntered:"), (IMP)callback, "v@:@");
}

/**
 * A special method called by MacForge once the application has started and all classes are initialized.
 */
+ (void)load {
    Termite *plugin = [Termite sharedInstance];
    NSUInteger osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    NSLog(@"%@ loaded into %@ on macOS 10.%ld", [self class], [[NSBundle mainBundle] bundleIdentifier], (long)osx_ver);
    
    NSWindow *btWindow = [plugin getBTWindow];
    if(btWindow)
        [plugin addMouseEnterTrackingToWindow:btWindow callback:(IMP)mouse_entered];
}


@end
