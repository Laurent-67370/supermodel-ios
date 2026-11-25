/*
 * Supermodel for Android: the app's folder and the menu's size.
 *
 * Supermodel reads and writes its files relative to the current directory
 * (Config/Supermodel.ini, Config/Games.xml, ROMs/, NVRAM/, Saves/, Assets/,
 * Supermodel.log). On Android it is the folder SUPERMODEL_HOME that the app
 * (SetupActivity of supermodel-android) chose and filled with Config/ and
 * Assets/ from the APK: Supermodel/ of the phone's storage, or the app's own
 * folder; the games are put in its ROMs folder.
 *
 * The menu (the list of the games) scaled to the screen, as on an iPad
 * (1.5 there): the screen's height over 720 pixels.
 *
 * This file is part of supermodel-ios, under the GNU General Public License
 * version 3 or later, as Supermodel.
 */

#include <SDL.h>

#include <android/log.h>
#include <sys/stat.h>
#include <unistd.h>

#include <algorithm>
#include <cstdlib>
#include <string>

void SupermodelMobilePrepare()
{
	const char *home = getenv("SUPERMODEL_HOME");
	if (!home || !*home)
		home = SDL_AndroidGetExternalStoragePath();
	if (!home)
	{
		__android_log_print(ANDROID_LOG_ERROR, "Supermodel", "no folder: %s", SDL_GetError());
		return;
	}
	for (const char *name : { "Config", "ROMs", "NVRAM", "Saves", "Assets" })
		mkdir((std::string(home) + "/" + name).c_str(), 0775);
	if (chdir(home) != 0)
		__android_log_print(ANDROID_LOG_ERROR, "Supermodel", "cannot enter %s", home);
	__android_log_print(ANDROID_LOG_INFO, "Supermodel", "folder %s", home);

	// Landscape, either way up
	SDL_SetHint(SDL_HINT_ORIENTATIONS, "LandscapeLeft LandscapeRight");
}

float SupermodelMobileUIScale()
{
	SDL_Rect screen;
	if (SDL_GetDisplayBounds(0, &screen) != 0)
		return 2.0f;
	return std::max(1.0f, float(std::min(screen.w, screen.h)) / 720.0f);
}
