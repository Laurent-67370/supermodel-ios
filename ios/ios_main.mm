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

// The game's touch controls: none on iOS yet (a game controller or a mouse)
void SupermodelMobileGame(const char *, unsigned)
{
}
