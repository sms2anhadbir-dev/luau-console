#import "LuauConsoleViewController.h"
#include "../include/LuauConsole.h"
#include <sstream>

@interface LuauConsoleViewController () <UITextViewDelegate>
@property (nonatomic, strong) UITextView *codeEditor;
@property (nonatomic, strong) UITextView *outputConsole;
@property (nonatomic, strong) UIButton *runButton;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, assign) LuauConsole *console;
@end

@implementation LuauConsoleViewController

- (void)dealloc {
    if (self.console) delete self.console;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:0.95];

    // Create the Luau console (C++ object)
    self.console = new LuauConsole();

    // Weak ref to self for the callback lambda
    __weak typeof(self) weakSelf = self;
    self.console->SetOutputCallback([weakSelf](const std::string& msg, bool isError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!weakSelf) return;
            NSString *nsMsg = [NSString stringWithUTF8String:msg.c_str()];
            NSAttributedString *attr = [[NSAttributedString alloc]
                initWithString:nsMsg
                attributes:@{
                    NSForegroundColorAttributeName: isError ? [UIColor redColor] : [UIColor greenColor],
                    NSFontAttributeName: [UIFont fontWithName:@"Menlo" size:12]
                }];
            NSMutableAttributedString *mutable = [[NSMutableAttributedString alloc]
                initWithAttributedString:weakSelf.outputConsole.attributedText];
            [mutable appendAttributedString:attr];
            [mutable appendAttributedString:[[NSAttributedString alloc]
                initWithString:@"\n"
                attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Menlo" size:12]}]];
            weakSelf.outputConsole.attributedText = mutable;
            [weakSelf.outputConsole scrollRangeToVisible:NSMakeRange(
                weakSelf.outputConsole.attributedText.length, 0)];
        });
    });

    // Code editor
    self.codeEditor = [[UITextView alloc] initWithFrame:CGRectZero];
    self.codeEditor.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.25 alpha:1];
    self.codeEditor.textColor = [UIColor whiteColor];
    self.codeEditor.font = [UIFont fontWithName:@"Menlo" size:14];
    self.codeEditor.autocorrectionType = UITextAutocorrectionTypeNo;
    self.codeEditor.spellCheckingType = UITextSpellCheckingTypeNo;
    self.codeEditor.delegate = self;
    [self.view addSubview:self.codeEditor];

    // Output console (read-only)
    self.outputConsole = [[UITextView alloc] initWithFrame:CGRectZero];
    self.outputConsole.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.18 alpha:1];
    self.outputConsole.textColor = [UIColor whiteColor];
    self.outputConsole.font = [UIFont fontWithName:@"Menlo" size:11];
    self.outputConsole.editable = NO;
    [self.view addSubview:self.outputConsole];

    // Run button
    self.runButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.runButton setTitle:@"Run" forState:UIControlStateNormal];
    self.runButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    self.runButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.5 blue:0.2 alpha:1];
    [self.runButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.runButton.layer.cornerRadius = 6;
    [self.runButton addTarget:self action:@selector(runCode) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.runButton];

    // Clear button
    self.clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.clearButton setTitle:@"Clear" forState:UIControlStateNormal];
    self.clearButton.titleLabel.font = [UIFont systemFontOfSize:12];
    self.clearButton.backgroundColor = [UIColor colorWithRed:0.4 green:0.2 blue:0.2 alpha:1];
    [self.clearButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.clearButton.layer.cornerRadius = 4;
    [self.clearButton addTarget:self action:@selector(clearOutput) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.clearButton];

    // Close button (X)
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton setTitle:@"✕" forState:UIControlStateNormal];
    self.closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.closeButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeButton];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGFloat padding = 8;
    CGFloat buttonHeight = 32;
    CGFloat editorHeight = self.view.bounds.size.height * 0.4;

    // Close button (top-right)
    self.closeButton.frame = CGRectMake(
        self.view.bounds.size.width - 40,
        padding,
        32, 32);

    // Code editor (top half)
    self.codeEditor.frame = CGRectMake(
        padding,
        padding + 40,
        self.view.bounds.size.width - 2 * padding,
        editorHeight);

    // Run button (below editor, left)
    self.runButton.frame = CGRectMake(
        padding,
        self.codeEditor.frame.origin.y + self.codeEditor.frame.size.height + 8,
        80, buttonHeight);

    // Clear button (next to Run)
    self.clearButton.frame = CGRectMake(
        self.runButton.frame.origin.x + self.runButton.frame.size.width + 8,
        self.runButton.frame.origin.y,
        60, buttonHeight);

    // Output console (bottom half)
    self.outputConsole.frame = CGRectMake(
        padding,
        self.runButton.frame.origin.y + buttonHeight + 8,
        self.view.bounds.size.width - 2 * padding,
        self.view.bounds.size.height - (self.runButton.frame.origin.y + buttonHeight + 8) - padding);
}

- (void)runCode {
    NSString *source = self.codeEditor.text;
    if (!source.length) {
        self.console->Execute("print('[empty]')", "console");
        return;
    }
    self.console->Execute([source UTF8String], "console");
}

- (void)clearOutput {
    self.outputConsole.text = @"";
}

- (void)presentFromViewController:(UIViewController *)parent {
    self.modalPresentationStyle = UIModalPresentationFormSheet;
    self.preferredContentSize = CGSizeMake(parent.view.bounds.size.width * 0.9,
                                            parent.view.bounds.size.height * 0.8);
    [parent presentViewController:self animated:YES completion:nil];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)executeScript:(NSString *)source {
    if (self.console) {
        self.console->Execute([source UTF8String], "programmatic");
    }
}

@end
