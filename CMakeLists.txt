# Supermodel (Sega Model 3) for iOS and Android, and the same OpenGL ES 3.0
# build on Linux to try it.
#
#   ./fetch-supermodel.sh
#   cmake -S . -B build [-DCMAKE_SYSTEM_NAME=iOS ...]
#
# Android: libmain.so, which SDL's activity loads (the app, its Java side and
# its Gradle build are in supermodel-android, which builds this file).
#
# SUPERMODEL_SRC: Supermodel's sources with patches/*.patch applied, and
# MUSASHI_GEN, the 68K emulator's sources made by Musashi's m68kmake (run on
# the machine that builds): both made by fetch-supermodel.sh.
#
# The list of sources is Supermodel's own (Makefiles/Rules.inc, SRC_FILES),
# read here so that a new version of Supermodel brings its new files.

cmake_minimum_required(VERSION 3.20)
project(Supermodel C CXX)
if(IOS)
	enable_language(OBJC OBJCXX)
endif()

set(SUPERMODEL_SRC "${CMAKE_SOURCE_DIR}/supermodel-src" CACHE PATH "Supermodel's sources, patched")
set(MUSASHI_GEN "${SUPERMODEL_SRC}/musashi" CACHE PATH "Musashi's generated sources")
set(SUPERMODEL_VERSION "ios" CACHE STRING "Version shown by the app")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)
if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE Release)
endif()
set(CMAKE_C_FLAGS_RELEASE "-O3")
set(CMAKE_CXX_FLAGS_RELEASE "-O3")

# Supermodel's sources, from its Makefile
file(READ "${SUPERMODEL_SRC}/Makefiles/Rules.inc" rules)
string(FIND "${rules}" "\nSRC_FILES = " first)
string(FIND "${rules}" "$(PLATFORM_SRC_FILES)" last)
if(first LESS 0 OR last LESS first)
	message(FATAL_ERROR "No SRC_FILES in ${SUPERMODEL_SRC}/Makefiles/Rules.inc")
endif()
math(EXPR length "${last} - ${first}")
string(SUBSTRING "${rules}" ${first} ${length} rules)
string(REGEX MATCHALL "Src/[A-Za-z0-9_./-]+" files "${rules}")
set(sources "")
foreach(file IN LISTS files)
	# GLEW is not used (OpenGL ES); the Makefile names some C files .cpp
	if(file MATCHES "Pkgs/glew")
		continue()
	endif()
	# make finds each file by its name in the directories of the others
	# (VPATH): the same here
	if(NOT EXISTS "${SUPERMODEL_SRC}/${file}")
		get_filename_component(name "${file}" NAME_WE)
		file(GLOB_RECURSE found "${SUPERMODEL_SRC}/Src/${name}.cpp" "${SUPERMODEL_SRC}/Src/${name}.c")
		list(FILTER found EXCLUDE REGEX "/OSD/Windows/")
		list(LENGTH found how_many)
		if(NOT how_many EQUAL 1)
			message(FATAL_ERROR "${file}: found ${how_many} times (${found})")
		endif()
		list(APPEND sources "${found}")
		continue()
	endif()
	list(APPEND sources "${SUPERMODEL_SRC}/${file}")
endforeach()
list(LENGTH sources count)
if(count LESS 50)
	message(FATAL_ERROR "Supermodel's sources not found in ${SUPERMODEL_SRC}/Makefiles/Rules.inc")
endif()
message(STATUS "Supermodel: ${count} source files")

# The 68K emulator (Musashi), generated
set(musashi
	"${SUPERMODEL_SRC}/Src/CPU/68K/Musashi/m68kcpu.c"
	"${MUSASHI_GEN}/m68kopnz.c"
	"${MUSASHI_GEN}/m68kopdm.c"
	"${MUSASHI_GEN}/m68kopac.c"
	"${MUSASHI_GEN}/m68kops.c")
set_source_files_properties(${musashi} PROPERTIES
	COMPILE_DEFINITIONS "INLINE=static inline"
	COMPILE_OPTIONS "-Wno-unused-variable;-fno-common")
if(ANDROID)
	# Android's sys/types.h has a type uint, which m68kcpu.h makes a macro
	# before m68kcpu.c includes stdio.h: the type first
	set_property(SOURCE ${musashi} APPEND PROPERTY COMPILE_OPTIONS "-include;sys/types.h")
endif()

# OpenGL ES: GL/glew.h of Src/OSD/GLES in the place of GLEW's
list(APPEND sources
	"${SUPERMODEL_SRC}/Src/OSD/GLES/GLES.cpp"
	"${SUPERMODEL_SRC}/Src/OSD/OSX/FileSystemPath.cpp")

# The include directories: those of every source, as the Makefile does
set(includes "${SUPERMODEL_SRC}/Src/OSD/GLES" "${SUPERMODEL_SRC}/Src" "${SUPERMODEL_SRC}" "${MUSASHI_GEN}"
	"${SUPERMODEL_SRC}/Src/CPU/68K/Musashi")
foreach(file IN LISTS sources)
	get_filename_component(dir "${file}" DIRECTORY)
	list(APPEND includes "${dir}")
endforeach()
list(REMOVE_DUPLICATES includes)

# SDL2 and SDL2_net: built here from external/ (iOS, Android;
# SUPERMODEL_BUNDLED_SDL elsewhere), or the system's
if(IOS OR ANDROID)
	set(mobile ON)
else()
	set(mobile OFF)
endif()
option(SUPERMODEL_BUNDLED_SDL "SDL2 and SDL2_net from external/" ${mobile})
if(SUPERMODEL_BUNDLED_SDL AND ANDROID)
	# libSDL2.so and libSDL2_net.so, which SDL's activity loads before
	# libmain.so (SDL's Java side calls into libSDL2.so)
	set(SDL_SHARED ON CACHE BOOL "" FORCE)
	set(SDL_STATIC OFF CACHE BOOL "" FORCE)
	set(SDL_TEST OFF CACHE BOOL "" FORCE)
	set(SDL2NET_INSTALL OFF CACHE BOOL "" FORCE)
	set(SDL2NET_SAMPLES OFF CACHE BOOL "" FORCE)
	set(BUILD_SHARED_LIBS ON CACHE BOOL "" FORCE)
	add_subdirectory(external/SDL)
	add_subdirectory(external/SDL_net)
	set(sdl_libs SDL2_net::SDL2_net SDL2::SDL2)
elseif(SUPERMODEL_BUNDLED_SDL)
	set(SDL_SHARED OFF CACHE BOOL "" FORCE)
	set(SDL_STATIC ON CACHE BOOL "" FORCE)
	set(SDL_TEST OFF CACHE BOOL "" FORCE)
	set(SDL2NET_INSTALL OFF CACHE BOOL "" FORCE)
	set(SDL2NET_SAMPLES OFF CACHE BOOL "" FORCE)
	set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
	add_subdirectory(external/SDL EXCLUDE_FROM_ALL)
	add_subdirectory(external/SDL_net EXCLUDE_FROM_ALL)
	set(sdl_libs SDL2_net::SDL2_net-static SDL2::SDL2-static)
	if(TARGET SDL2::SDL2main)
		list(PREPEND sdl_libs SDL2::SDL2main)
	endif()
else()
	find_package(PkgConfig REQUIRED)
	pkg_check_modules(SDL2 REQUIRED IMPORTED_TARGET sdl2 SDL2_net)
	set(sdl_libs PkgConfig::SDL2)
endif()
if(ANDROID)
	list(APPEND sdl_libs GLESv3 EGL android log)
elseif(NOT IOS)
	find_package(PkgConfig REQUIRED)
	pkg_check_modules(GLES REQUIRED IMPORTED_TARGET glesv2)
	list(APPEND sdl_libs PkgConfig::GLES)
endif()

if(IOS)
	add_executable(supermodel MACOSX_BUNDLE ${sources} ${musashi} "${CMAKE_SOURCE_DIR}/ios/ios_main.mm")
elseif(ANDROID)
	# SDL_main (Supermodel's main, renamed by SDL.h) in libmain.so
	add_library(supermodel SHARED ${sources} ${musashi} "${CMAKE_SOURCE_DIR}/android/android_main.cpp")
	set_target_properties(supermodel PROPERTIES OUTPUT_NAME main)
else()
	add_executable(supermodel ${sources} ${musashi})
endif()

target_include_directories(supermodel PRIVATE ${includes})
target_compile_definitions(supermodel PRIVATE
	SUPERMODEL_GLES
	IMGUI_IMPL_OPENGL_ES3
	SUPERMODEL_GIT_REVISION="${SUPERMODEL_VERSION}")
target_compile_options(supermodel PRIVATE -w)
if(ANDROID)
	# The app's folders and the menu's size (android/android_main.cpp)
	target_compile_definitions(supermodel PRIVATE SUPERMODEL_MOBILE)
	# Android's C library has the threads in it
	target_link_libraries(supermodel PRIVATE ${sdl_libs} z m)
else()
	target_link_libraries(supermodel PRIVATE ${sdl_libs} z m pthread)
endif()

if(IOS)
	target_compile_definitions(supermodel PRIVATE SUPERMODEL_IOS SUPERMODEL_MOBILE GLES_SILENCE_DEPRECATION)
	set_source_files_properties("${CMAKE_SOURCE_DIR}/ios/ios_main.mm" PROPERTIES COMPILE_OPTIONS "-fobjc-arc")
	target_link_libraries(supermodel PRIVATE
		"-framework OpenGLES" "-framework UIKit" "-framework Foundation" "-framework QuartzCore"
		"-framework UniformTypeIdentifiers")
	set_target_properties(supermodel PROPERTIES
		OUTPUT_NAME Supermodel
		MACOSX_BUNDLE_INFO_PLIST "${CMAKE_SOURCE_DIR}/ios/Info.plist.in"
		MACOSX_BUNDLE_GUI_IDENTIFIER "io.github.laurent67370.supermodel"
		MACOSX_BUNDLE_BUNDLE_NAME "Supermodel"
		MACOSX_BUNDLE_SHORT_VERSION_STRING "${SUPERMODEL_VERSION}"
		MACOSX_BUNDLE_BUNDLE_VERSION "${SUPERMODEL_VERSION}"
		XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED NO)
	# Supermodel's Config/ (Games.xml, Supermodel.ini) and Assets/ in the
	# app, copied to its Documents folder at the first launch
	add_custom_command(TARGET supermodel POST_BUILD
		COMMAND ${CMAKE_COMMAND} -E copy_directory "${SUPERMODEL_SRC}/Config" "$<TARGET_BUNDLE_CONTENT_DIR:supermodel>/Config"
		COMMAND ${CMAKE_COMMAND} -E copy_directory "${SUPERMODEL_SRC}/Assets" "$<TARGET_BUNDLE_CONTENT_DIR:supermodel>/Assets")
endif()
