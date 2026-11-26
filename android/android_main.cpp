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
 * The menu turns with the phone (portrait or landscape); the game is in
 * landscape, the phone turned before its window is made (Supermodel sizes
 * its picture once, from the window it creates).
 *
 * The menu (the list of the games) scaled as Android scales its own apps:
 * the screen's density over 160 dpi (an ImGui pixel is an Android dp), at
 * most the screen's height over 400 pixels, so that it still fits.
 *
 * This file is part of supermodel-ios, under the GNU General Public License
 * version 3 or later, as Supermodel.
 */

#include <SDL.h>
#include <SDL_system.h>

#include <jni.h>

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
	float density = 0.0f, scale = 3.0f;
	SDL_Rect screen;

	if (SDL_GetDisplayDPI(0, &density, nullptr, nullptr) == 0 && density > 0.0f)
		scale = density / 160.0f;
	if (SDL_GetDisplayBounds(0, &screen) == 0)
		scale = std::min(scale, float(std::min(screen.w, screen.h)) / 400.0f);
	__android_log_print(ANDROID_LOG_INFO, "Supermodel", "menu scale %.2f (density %.0f dpi)", scale, density);
	return std::max(1.0f, scale);
}

namespace
{
	// ActivityInfo.SCREEN_ORIENTATION_*
	const int kSensorLandscape = 6;
	const int kFullUser = 13;

	void RequestOrientation(int orientation)
	{
		JNIEnv *env = (JNIEnv *) SDL_AndroidGetJNIEnv();
		jobject activity = (jobject) SDL_AndroidGetActivity();
		if (!env || !activity)
			return;
		jclass type = env->GetObjectClass(activity);
		jmethodID method = env->GetMethodID(type, "setRequestedOrientation", "(I)V");
		if (method)
			env->CallVoidMethod(activity, method, orientation);
		if (env->ExceptionCheck())
			env->ExceptionClear();
		env->DeleteLocalRef(type);
		env->DeleteLocalRef(activity);
	}

	bool Landscape()
	{
		SDL_DisplayMode mode;
		return SDL_GetDesktopDisplayMode(0, &mode) == 0 && mode.w > mode.h;
	}
}

void SupermodelMobileMenu(bool shown)
{
	if (shown)
	{
		// The menu: any way up, as the phone is held (unless its rotation is
		// locked); SDL asks it again from this hint when it makes the window
		SDL_SetHint(SDL_HINT_ORIENTATIONS, "LandscapeLeft LandscapeRight Portrait PortraitUpsideDown");
		RequestOrientation(kFullUser);
		return;
	}

	// The game: landscape, the phone turned before the game's window is made
	SDL_SetHint(SDL_HINT_ORIENTATIONS, "LandscapeLeft LandscapeRight");
	RequestOrientation(kSensorLandscape);
	for (int waited = 0; !Landscape() && waited < 2000; waited += 20)
	{
		SDL_PumpEvents();
		SDL_Delay(20);
	}
	__android_log_print(ANDROID_LOG_INFO, "Supermodel", "game in %s", Landscape() ? "landscape" : "portrait (not turned)");
}
