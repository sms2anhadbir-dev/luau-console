#import "LuauConsoleButton.h"
#import "LuauConsoleViewController.h"

@interface LuauConsoleButton ()
@property (nonatomic, weak) UIViewController *parentViewController;
@property (nonatomic, strong) LuauConsoleViewController *consoleViewController;
@end

@implementation LuauConsoleButton

- (instancetype)initWithViewController:(UIViewController *)viewController {
    self = [super initWithFrame:CGRectMake(0, 0, 50, 50)];
    if (self) {
        self.parentViewController = viewController;

        // Styling
        self.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.4 alpha:0.9];
        self.layer.cornerRadius = 25;
        [self setTitle:@"W" forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:24];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

        // Position: top-center of parent's view
        [self updatePosition];

        // Tap action
        [self addTarget:self action:@selector(openConsole) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)updatePosition {
    if (!self.parentViewController) return;

    CGSize parentSize = self.parentViewController.view.bounds.size;
    self.center = CGPointMake(parentSize.width / 2.0, 40);
}

- (void)openConsole {
    if (!self.consoleViewController) {
        self.consoleViewController = [[LuauConsoleViewController alloc] init];
    }
    [self.consoleViewController presentFromViewController:self.parentViewController];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updatePosition];
}

@end
