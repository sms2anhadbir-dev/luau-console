#pragma once

#ifdef __OBJC__
#import <UIKit/UIKit.h>

@class LuauConsoleViewController;

// Obj-C++ bridge: wraps the C++ LuauConsole for iOS.
// Instantiate and present as a modal; the console is owned by this controller.
@interface LuauConsoleViewController : UIViewController

// Show the console UI (call this from your app when the user taps the W button).
- (void)presentFromViewController:(UIViewController *)parent;

// Close the console.
- (void)dismiss;

// Execute a script directly (programmatically, not via the UI).
- (void)executeScript:(NSString *)source;

@end

#endif  // __OBJC__
