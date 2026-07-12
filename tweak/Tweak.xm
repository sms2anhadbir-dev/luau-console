// LuauConsole Theos tweak — injects a "W" button + Luau console popup into
// YOUR OWN app. Hooks the app's key window at launch, drops a floating button
// at top-center, and opens a code editor / output console when tapped.
//
// The console runs the real open-source Luau VM linked into this dylib. It is
// injected into your own app's process via the standard Theos/LC_LOAD_DYLIB
// pipeline — nothing here touches any other process.

#import <UIKit/UIKit.h>
#include "../include/LuauConsole.h"

// ─────────────────────────────────────────────────────────────────────────
// Console popup view controller
// ─────────────────────────────────────────────────────────────────────────
@interface LCConsoleViewController : UIViewController
@property (nonatomic, strong) UITextView *codeEditor;
@property (nonatomic, strong) UITextView *outputConsole;
@property (nonatomic, assign) LuauConsole *console;
@end

@implementation LCConsoleViewController

- (void)dealloc {
    if (self.console) delete self.console;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:0.97];

    self.console = new LuauConsole();
    __weak typeof(self) weakSelf = self;
    self.console->SetOutputCallback([weakSelf](const std::string &msg, bool isError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!weakSelf) return;
            NSString *line = [NSString stringWithUTF8String:msg.c_str()];
            NSDictionary *attrs = @{
                NSForegroundColorAttributeName: isError ? [UIColor systemRedColor] : [UIColor systemGreenColor],
                NSFontAttributeName: [UIFont fontWithName:@"Menlo" size:12] ?: [UIFont systemFontOfSize:12]
            };
            NSMutableAttributedString *m = [weakSelf.outputConsole.attributedText mutableCopy] ?: [NSMutableAttributedString new];
            [m appendAttributedString:[[NSAttributedString alloc] initWithString:[line stringByAppendingString:@"\n"] attributes:attrs]];
            weakSelf.outputConsole.attributedText = m;
            [weakSelf.outputConsole scrollRangeToVisible:NSMakeRange(m.length, 0)];
        });
    });

    // Code editor
    self.codeEditor = [UITextView new];
    self.codeEditor.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.25 alpha:1];
    self.codeEditor.textColor = [UIColor whiteColor];
    self.codeEditor.font = [UIFont fontWithName:@"Menlo" size:14] ?: [UIFont systemFontOfSize:14];
    self.codeEditor.autocorrectionType = UITextAutocorrectionTypeNo;
    self.codeEditor.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.codeEditor.spellCheckingType = UITextSpellCheckingTypeNo;
    self.codeEditor.text = @"print(game.Name, workspace.Name)";
    [self.view addSubview:self.codeEditor];

    // Output console
    self.outputConsole = [UITextView new];
    self.outputConsole.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.18 alpha:1];
    self.outputConsole.editable = NO;
    [self.view addSubview:self.outputConsole];

    // Run
    UIButton *run = [UIButton buttonWithType:UIButtonTypeSystem];
    [run setTitle:@"Run" forState:UIControlStateNormal];
    run.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    run.backgroundColor = [UIColor colorWithRed:0.2 green:0.5 blue:0.2 alpha:1];
    [run setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    run.layer.cornerRadius = 6;
    run.tag = 100;
    [run addTarget:self action:@selector(runCode) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:run];

    // Clear
    UIButton *clear = [UIButton buttonWithType:UIButtonTypeSystem];
    [clear setTitle:@"Clear" forState:UIControlStateNormal];
    clear.backgroundColor = [UIColor colorWithRed:0.4 green:0.2 blue:0.2 alpha:1];
    [clear setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    clear.layer.cornerRadius = 6;
    clear.tag = 101;
    [clear addTarget:self action:@selector(clearOutput) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:clear];

    // Close
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    [close setTitle:@"✕" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [close setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    close.tag = 102;
    [close addTarget:self action:@selector(closeConsole) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:close];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat pad = 10, w = self.view.bounds.size.width, h = self.view.bounds.size.height;
    CGFloat top = self.view.safeAreaInsets.top + 8;

    [self.view viewWithTag:102].frame = CGRectMake(w - 44, top, 36, 36);
    self.codeEditor.frame = CGRectMake(pad, top + 44, w - 2*pad, h * 0.35);
    CGFloat by = CGRectGetMaxY(self.codeEditor.frame) + 8;
    [self.view viewWithTag:100].frame = CGRectMake(pad, by, 90, 36);
    [self.view viewWithTag:101].frame = CGRectMake(pad + 98, by, 70, 36);
    CGFloat oy = by + 44;
    self.outputConsole.frame = CGRectMake(pad, oy, w - 2*pad, h - oy - pad - self.view.safeAreaInsets.bottom);
}

- (void)runCode {
    NSString *src = self.codeEditor.text ?: @"";
    self.console->Execute([src UTF8String], "console");
}
- (void)clearOutput { self.outputConsole.attributedText = [NSAttributedString new]; }
- (void)closeConsole { [self dismissViewControllerAnimated:YES completion:nil]; }

@end

// ─────────────────────────────────────────────────────────────────────────
// Floating "W" button, added to the key window at launch
// ─────────────────────────────────────────────────────────────────────────
static UIViewController *LCTopViewController(void) {
    UIWindow *key = nil;
    for (UIWindow *w in UIApplication.sharedApplication.windows) {
        if (w.isKeyWindow) { key = w; break; }
    }
    if (!key) key = UIApplication.sharedApplication.windows.firstObject;
    UIViewController *vc = key.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    return vc;
}

@interface LCButtonHandler : NSObject
+ (instancetype)shared;
- (void)openConsole;
@end

@implementation LCButtonHandler
+ (instancetype)shared {
    static LCButtonHandler *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [LCButtonHandler new]; });
    return s;
}
- (void)openConsole {
    LCConsoleViewController *console = [LCConsoleViewController new];
    console.modalPresentationStyle = UIModalPresentationFormSheet;
    [LCTopViewController() presentViewController:console animated:YES completion:nil];
}
@end

static void LCInstallButton(UIWindow *window) {
    if (!window || [window viewWithTag:0x5700]) return;

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag = 0x5700;
    btn.frame = CGRectMake(0, 0, 50, 50);
    btn.center = CGPointMake(window.bounds.size.width / 2.0, window.safeAreaInsets.top + 30);
    btn.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.4 alpha:0.9];
    btn.layer.cornerRadius = 25;
    [btn setTitle:@"W" forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:[LCButtonHandler shared] action:@selector(openConsole) forControlEvents:UIControlEventTouchUpInside];
    [window addSubview:btn];
    [window bringSubviewToFront:btn];
}

// ─────────────────────────────────────────────────────────────────────────
// Bootstrap — NO Substrate required.
//
// This dylib is injected via plain LC_LOAD_DYLIB (Scarlet / Sideloadly /
// TrollStore etc.), so there is no MobileSubstrate to %hook with. Instead we
// register an NSNotificationCenter observer from a constructor: when the app
// becomes active we install the W button into the key window. Works on any
// non-jailbroken sideload.
// ─────────────────────────────────────────────────────────────────────────
@interface LCBootstrap : NSObject
@end

@implementation LCBootstrap
+ (void)appBecameActive:(NSNotification *)note {
    // Delay slightly so the app's own UI has finished setting up its window.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIApplication *app = UIApplication.sharedApplication;
        UIWindow *window = app.keyWindow ?: app.windows.firstObject;
        LCInstallButton(window);
    });
}
@end

__attribute__((constructor))
static void LCInit(void) {
    [NSNotificationCenter.defaultCenter
        addObserver:[LCBootstrap class]
           selector:@selector(appBecameActive:)
               name:UIApplicationDidBecomeActiveNotification
             object:nil];
}
