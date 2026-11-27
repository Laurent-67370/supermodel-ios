/*
 * Supermodel for iOS: the app's folders.
 *
 * Supermodel reads and writes its files relative to the current directory
 * (Config/Supermodel.ini, Config/Games.xml, ROMs/, NVRAM/, Saves/, Assets/).
 * On iOS the current directory is the app's Documents folder, which the
 * Files app shows (On My iPhone/iPad, Supermodel; with LiveContainer,
 * inside its folder): the games are put in its ROMs folder.
 *
 * Config/ and Assets/ come with the app: Games.xml (the list of the games)
 * and Assets/ are replaced at each launch by those of the app, so that a new
 * version brings its new games; Supermodel.ini, the user's settings, is
 * copied only when there is none.
 *
 * The menu (the list of the games) 1.5 times as big as on a computer, big
 * enough to be touched (Gui.cpp of the patch).
 *
 * This file is part of supermodel-ios, under the GNU General Public License
 * version 3 or later, as Supermodel.
 */

#import <Foundation/Foundation.h>

#include <unistd.h>

namespace
{
	void Copy(NSFileManager *files, NSString *from, NSString *to, BOOL replace)
	{
		BOOL folder = NO;

		if (![files fileExistsAtPath:from isDirectory:&folder])
			return;
		if (folder)
		{
			[files createDirectoryAtPath:to withIntermediateDirectories:YES attributes:nil error:nil];
			for (NSString *name in [files contentsOfDirectoryAtPath:from error:nil])
				Copy(files, [from stringByAppendingPathComponent:name], [to stringByAppendingPathComponent:name], replace);
			return;
		}
		if ([files fileExistsAtPath:to])
		{
			if (!replace)
				return;
			[files removeItemAtPath:to error:nil];
		}
		[files copyItemAtPath:from toPath:to error:nil];
	}
}

void SupermodelMobilePrepare()
{
	@autoreleasepool
	{
		NSFileManager *const files = [NSFileManager defaultManager];
		NSString *const documents =
			[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
		NSString *const bundle = [[NSBundle mainBundle] bundlePath];

		for (NSString *name in @[ @"Config", @"ROMs", @"NVRAM", @"Saves", @"Assets" ])
			[files createDirectoryAtPath:[documents stringByAppendingPathComponent:name]
			   withIntermediateDirectories:YES
			                    attributes:nil
			                         error:nil];

		// The list of the games and the pictures: always the app's
		Copy(files, [bundle stringByAppendingPathComponent:@"Assets"], [documents stringByAppendingPathComponent:@"Assets"], YES);
		for (NSString *name in [files contentsOfDirectoryAtPath:[bundle stringByAppendingPathComponent:@"Config"] error:nil])
		{
			NSString *const from = [[bundle stringByAppendingPathComponent:@"Config"] stringByAppendingPathComponent:name];
			NSString *const to = [[documents stringByAppendingPathComponent:@"Config"] stringByAppendingPathComponent:name];
			// The settings, the user's: kept
			Copy(files, from, to, ![name isEqualToString:@"Supermodel.ini"]);
		}

		chdir(documents.fileSystemRepresentation);
		NSLog(@"Supermodel: folder %@", documents);
	}
}

float SupermodelMobileUIScale()
{
	return 1.5f;
}

// The menu's orientation: landscape only on iOS (Info.plist), nothing to do
void SupermodelMobileMenu(bool)
{
}

// ---------------------------------------------------------------------------
// MENU, over the game: Supermodel's keys at a touch (save and load the
// state, pause, reset, the cabinet's Test and Service buttons, quit), as on
// a keyboard: SDL's own key events, each held a moment so that Supermodel,
// which reads the keyboard once a frame, sees it. A game controller or a
// mouse plays; MENU is touched.

#include <SDL.h>
#include <SDL_syswm.h>
#import <UIKit/UIKit.h>

// SDL's (src/events/SDL_keyboard_c.h): a key pressed or released, as a
// keyboard would
extern "C" int SDL_SendKeyboardKey(Uint8 state, SDL_Scancode scancode);

namespace
{
	// The device in French: the menu in French; in English otherwise
	bool French()
	{
		return [[[NSLocale preferredLanguages] firstObject] hasPrefix:@"fr"];
	}

	NSString *T(NSString *english, NSString *french)
	{
		return French() ? french : english;
	}

	// Pressed now (with a modifier, or none), released a moment later
	void Press(SDL_Scancode key, SDL_Scancode modifier = SDL_SCANCODE_UNKNOWN)
	{
		if (modifier != SDL_SCANCODE_UNKNOWN)
			SDL_SendKeyboardKey(SDL_PRESSED, modifier);
		SDL_SendKeyboardKey(SDL_PRESSED, key);
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
			SDL_SendKeyboardKey(SDL_RELEASED, key);
			if (modifier != SDL_SCANCODE_UNKNOWN)
				SDL_SendKeyboardKey(SDL_RELEASED, modifier);
		});
	}
}

@interface SupermodelMenu : NSObject
@property(nonatomic, strong) UIButton *button;
@end

@implementation SupermodelMenu

- (void)show:(UIView *)view
{
	if (self.button.superview == view)
		return;
	[self.button removeFromSuperview];
	UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
	[button setTitle:@"MENU" forState:UIControlStateNormal];
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	button.titleLabel.font = [UIFont boldSystemFontOfSize:15];
	button.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.55];
	button.layer.cornerRadius = 18;
	button.layer.borderWidth = 1.5;
	button.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.6].CGColor;
	button.translatesAutoresizingMaskIntoConstraints = NO;
	[button addTarget:self action:@selector(open:) forControlEvents:UIControlEventTouchUpInside];
	[view addSubview:button];
	// In the top left corner, inside the safe area (clear of the camera)
	[NSLayoutConstraint activateConstraints:@[
		[button.leadingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.leadingAnchor constant:12],
		[button.topAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.topAnchor constant:10],
		[button.widthAnchor constraintEqualToConstant:86],
		[button.heightAnchor constraintEqualToConstant:36],
	]];
	self.button = button;
}

- (void)open:(UIButton *)sender
{
	UIAlertController *menu = [UIAlertController alertControllerWithTitle:@"Supermodel"
	                                                              message:nil
	                                                       preferredStyle:UIAlertControllerStyleActionSheet];
	struct Item { NSString *title; SDL_Scancode key, modifier; };
	const Item items[] = {
		{ T(@"Save state", @"Sauvegarder l'état"), SDL_SCANCODE_F5, SDL_SCANCODE_UNKNOWN },
		{ T(@"Load state", @"Charger l'état"), SDL_SCANCODE_F7, SDL_SCANCODE_UNKNOWN },
		{ T(@"Change save slot", @"Changer d'emplacement de sauvegarde"), SDL_SCANCODE_F6, SDL_SCANCODE_UNKNOWN },
		{ T(@"Pause / resume", @"Pause / reprendre"), SDL_SCANCODE_P, SDL_SCANCODE_LALT },
		{ T(@"Reset the game", @"Redémarrer le jeu"), SDL_SCANCODE_R, SDL_SCANCODE_LALT },
		{ T(@"Test button (the cabinet's menu)", @"Bouton Test (menu de la borne)"), SDL_SCANCODE_6, SDL_SCANCODE_UNKNOWN },
		{ T(@"Service button", @"Bouton Service"), SDL_SCANCODE_5, SDL_SCANCODE_UNKNOWN },
	};
	for (const Item &item : items)
	{
		SDL_Scancode key = item.key, modifier = item.modifier;
		[menu addAction:[UIAlertAction actionWithTitle:item.title
		                                         style:UIAlertActionStyleDefault
		                                       handler:^(UIAlertAction *) { Press(key, modifier); }]];
	}
	// iOS has no way back for an app that quits: it is opened again
	[menu addAction:[UIAlertAction actionWithTitle:T(@"Quit (open the app again for the game list)", @"Quitter (rouvrir l'app pour la liste des jeux)")
	                                         style:UIAlertActionStyleDestructive
	                                       handler:^(UIAlertAction *) { Press(SDL_SCANCODE_ESCAPE); }]];
	[menu addAction:[UIAlertAction actionWithTitle:T(@"Cancel", @"Annuler") style:UIAlertActionStyleCancel handler:nil]];
	// On iPad, the list comes out of the button
	menu.popoverPresentationController.sourceView = sender;
	menu.popoverPresentationController.sourceRect = sender.bounds;
	UIViewController *controller = sender.window.rootViewController;
	while (controller.presentedViewController)
		controller = controller.presentedViewController;
	[controller presentViewController:menu animated:YES completion:nil];
}

@end

// A game starts: MENU over its window (SDL's view, on the main thread, where
// SDL runs on iOS)
void SupermodelMobileGame(const char *, unsigned)
{
	static SupermodelMenu *menu = [SupermodelMenu new];
	SDL_Window *window = SDL_GL_GetCurrentWindow();
	SDL_SysWMinfo info;
	SDL_VERSION(&info.version);
	if (!window || !SDL_GetWindowWMInfo(window, &info) || info.subsystem != SDL_SYSWM_UIKIT)
	{
		NSLog(@"Supermodel: no window for MENU");
		return;
	}
	UIView *view = info.info.uikit.window.rootViewController.view;
	if (view)
		[menu show:view];
}
