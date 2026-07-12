#pragma once

#ifdef __OBJC__
#import <UIKit/UIKit.h>

@class LuauConsoleViewController;

// A floating "W" button at the top-middle of the screen that opens the Luau console popup.
// Integrate into your game's main view controller:
//
//   @property (nonatomic, strong) LuauConsoleButton *luauButton;
//
//   - (void)viewDidLoad {
//       self.luauButton = [[LuauConsoleButton alloc] initWithViewController:self];
//       [self.view addSubview:self.luauButton];
//   }
@interface LuauConsoleButton : UIButton

- (instancetype)initWithViewController:(UIViewController *)viewController;

@end

#endif  // __OBJC__
