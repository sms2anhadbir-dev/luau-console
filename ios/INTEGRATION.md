# Integrating LuauConsole into Your iOS Game

## Files

- `LuauConsoleViewController.h/mm` — the popup console UI (modal, text editor, output view)
- `LuauConsoleButton.h/mm` — the floating "W" button at top-center that opens the console

## Integration Steps

### 1. Add to your game's main view controller

In your game's primary `UIViewController` (e.g., `GameViewController.h`):

```objc
#import "LuauConsoleButton.h"

@interface GameViewController : UIViewController
@property (nonatomic, strong) LuauConsoleButton *luauButton;
@end
```

### 2. Initialize in `viewDidLoad`

```objc
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // ... your other setup ...
    
    // Add the Luau console button
    self.luauButton = [[LuauConsoleButton alloc] initWithViewController:self];
    [self.view addSubview:self.luauButton];
}
```

### 3. Link the C++ LuauConsole to your engine's game objects

In your C++ game code, instantiate one shared `LuauConsole` and populate it with your engine's actual scene objects:

```cpp
LuauConsole console;

// Wire your engine's root scene nodes into game/workspace
for (auto& gameObject : myEngine.GetRootObjects()) {
    console.Workspace().GetChildren().push_back(gameObject);
    // or: console.RegisterService(gameObject->Name, *gameObject);
}
```

Pass this console instance to the iOS ViewController via a bridge (or use a singleton pattern — just ensure both your C++ engine and Obj-C UI are talking to the same `LuauConsole` instance).

## What the User Sees

1. **W button** at top-center of screen
2. **Tap → popup appears** with:
   - **Code editor** (top half): type Luau code
   - **Output console** (bottom half): prints, errors, results
   - **Run button**: execute the code
   - **Clear button**: clear output
   - **✕ button** (top-right): close the console

## Example Scripts the User Can Run

```lua
print(game.Name, workspace.Name)
print(#workspace:GetChildren())

local found = workspace:FindFirstChild("Player")
if found then
  print("Found:", found.Name, found.ClassName)
end

for _, child in ipairs(workspace:GetChildren()) do
  print(child.Name)
end
```

## Customization

- **Button color**: Edit `LuauConsoleButton.mm`, line with `UIColor colorWithRed:0.3...`
- **Console window size**: Edit `LuauConsoleViewController.mm`, `preferredContentSize`
- **Editor font size**: Change `[UIFont fontWithName:@"Menlo" size:14]`
- **Output colors**: Modify the `NSForegroundColorAttributeName` assignments in `outputConsole` callback

## Notes

- The console does **not** auto-update when your game's scene changes — it takes a snapshot at console-open time of whatever `game` and `workspace` contain.
- To expose more of your engine's API, extend the C++ bindings in `src/LuauConsole.cpp` (e.g., add more Lua metamethods for your custom classes).
