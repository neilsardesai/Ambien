//
//  AppDelegate.m
//  Ambien
//
//  Created by Neil Sardesai on 4/24/19.
//  Copyright © 2019 Neil Sardesai. All rights reserved.
//

#import "AppDelegate.h"
#import "MainWindow.h"

@interface AppDelegate ()
@property (nonatomic, strong) NSStatusItem *statusItem;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self setUpMenuBarExtra];
    [NSApp activateIgnoringOtherApps:YES];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    [self showMainWindow];
    return YES;
}

- (void)setUpMenuBarExtra {
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSSquareStatusItemLength];
    [self.statusItem setVisible:YES];
    self.statusItem.behavior = NSStatusItemBehaviorRemovalAllowed | NSStatusItemBehaviorTerminationOnRemoval;
    self.statusItem.button.image = [NSImage imageNamed:@"StatusItemIcon"];
    NSMenu *menu = [NSMenu new];
    NSMenuItem *preferencesMenuItem = [[NSMenuItem alloc] initWithTitle:@"Preferences…" action:@selector(showMainWindow) keyEquivalent:@""];
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit Ambien" action:@selector(quit) keyEquivalent:@""];
    [menu addItem:preferencesMenuItem];
    [menu addItem:quitMenuItem];
    [self.statusItem setMenu:menu];
}

- (void)showMainWindow {
    [NSApp activateIgnoringOtherApps:YES];
    for (NSWindow *window in NSApp.windows) {
        if ([window isKindOfClass:[MainWindow class]] && !window.isVisible) {
            [window makeKeyAndOrderFront:self];
            break;
        }
    }
}

- (void)quit {
    [NSApp terminate:self];
}

@end
