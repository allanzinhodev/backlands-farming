//////////////////////////////////////////////////////////////////////
// This file is part of Remere's Map Editor
//////////////////////////////////////////////////////////////////////
// Remere's Map Editor is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Remere's Map Editor is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.
//////////////////////////////////////////////////////////////////////

#ifndef RME_DEFINITIONS_H_
#define RME_DEFINITIONS_H_

#include "version_info.h"

#define __W_RME_APPLICATION_NAME__ wxString(NEXAMAP_APPLICATION_NAME)
#define __RME_APPLICATION_NAME__ std::string(NEXAMAP_APPLICATION_NAME)

// Version info
// xxyyzzt (major, minor, subversion)
#define __RME_VERSION_MAJOR__ NEXAMAP_VERSION_MAJOR
#define __RME_VERSION_MINOR__ NEXAMAP_VERSION_MINOR
#define __RME_SUBVERSION__ NEXAMAP_VERSION_PATCH

#define MAKE_VERSION_ID(major, minor, subversion) \
	((major) * 10000000 + (minor) * 100000 + (subversion) * 1000)

#define __RME_VERSION_ID__ MAKE_VERSION_ID( \
	__RME_VERSION_MAJOR__,                  \
	__RME_VERSION_MINOR__,                  \
	__RME_SUBVERSION__                      \
)

#define __SITE_URL__ "https://github.com/Skyyzyy/RME-ZONES"

// #define __PRERELEASE__ 1

#ifdef __EXPERIMENTAL__
	#define __RME_VERSION__ std::string(i2s(__RME_VERSION_MAJOR__) + "." + i2s(__RME_VERSION_MINOR__) + "." + i2s(__RME_SUBVERSION__) + " BETA")
	#define __W_RME_VERSION__ (wxString() << __RME_VERSION_MAJOR__ << "." << __RME_VERSION_MINOR__ << "." << __RME_SUBVERSION__ << " BETA")
#elif __SNAPSHOT__
	#define __RME_VERSION__ std::string(i2s(__RME_VERSION_MAJOR__) + "." + i2s(__RME_VERSION_MINOR__) + "." + i2s(__RME_SUBVERSION__) + " - SNAPSHOT")
	#define __W_RME_VERSION__ (wxString() << __RME_VERSION_MAJOR__ << "." << __RME_VERSION_MINOR__ << "." << __RME_SUBVERSION__ << " - SNAPSHOT")
#elif __PRERELEASE__
	#define __RME_VERSION__ std::string(i2s(__RME_VERSION_MAJOR__) + "." + i2s(__RME_VERSION_MINOR__) + "." + i2s(__RME_SUBVERSION__) + " (Pre-release)")
	#define __W_RME_VERSION__ (wxString() << __RME_VERSION_MAJOR__ << "." << __RME_VERSION_MINOR__ << "." << __RME_SUBVERSION__ << " (Pre-release)")
#else
	#define __RME_VERSION__ std::string(i2s(__RME_VERSION_MAJOR__) + "." + i2s(__RME_VERSION_MINOR__) + "." + i2s(__RME_SUBVERSION__))
	#define __W_RME_VERSION__ (wxString() << __RME_VERSION_MAJOR__ << "." << __RME_VERSION_MINOR__ << "." << __RME_SUBVERSION__)
#endif
// OS


#define ASSETS_NAME "Tibia"

#ifdef __VISUALC__
	#pragma warning(disable : 4996) // Stupid MSVC complaining 'bout "unsafe" functions
	#pragma warning(disable : 4800) // Bool conversion warning
	#pragma warning(disable : 4100) // Unused parameter warning ( I like to name unused stuff... )
	#pragma warning(disable : 4706) // Assignment within conditional expression
#endif

#ifndef FORCEINLINE
	#ifdef __VISUALC__
		#define FORCEINLINE __forceinline
	#else
		#define FORCEINLINE inline
	#endif
#endif

// Debug mode?
#if defined __DEBUG__ || defined _DEBUG || defined __DEBUG_MODE__
	#undef __DEBUG_MODE__
	#define __DEBUG_MODE__ 1
	#undef __DEBUG__
	#define __DEBUG__ 1
#else
	#ifndef __RELEASE__
		#define __RELEASE__ 1
	#endif
#endif

#ifdef __RELEASE__
	#ifdef __VISUALC__
		#define _SCL_SECURE 0
		#define _SECURE_SCL 0 // They can't even decide on a coherent define interface!
		#define _HAS_ITERATOR_DEBUGGING 0
	#endif
#endif

#ifndef _DONT_USE_PROCESS_COM
	#if defined __WINDOWS__ && !defined _USE_PROCESS_COM
		#define _USE_PROCESS_COM
	#endif
#endif

// Mathematical constants
#define PI 3.14159265358979323846264338327950288419716939937510

// The height of the map (there should be more checks for this...)
#define MAP_LAYERS 16

#define MAP_MAX_WIDTH 65000
#define MAP_MAX_HEIGHT 65000
#define MAP_MAX_LAYER 15

// Pixels per tile and per sprite. Chosen at build time with the CMake option
// NEXAMAP_SPRITE_PIXELS (32 = classic Tibia assets, 16 = Backlands assets).
// The .spr format does not store sprite dimensions, so every sprite in the
// loaded .spr must have exactly this size.
#ifndef NEXAMAP_SPRITE_PIXELS
	#define NEXAMAP_SPRITE_PIXELS 32
#endif
static_assert(NEXAMAP_SPRITE_PIXELS == 16 || NEXAMAP_SPRITE_PIXELS == 32, "NEXAMAP_SPRITE_PIXELS must be 16 or 32");

// The size of the tile in pixels
constexpr int TileSize = NEXAMAP_SPRITE_PIXELS;

// The default size of sprites
#define SPRITE_PIXELS NEXAMAP_SPRITE_PIXELS
#define SPRITE_PIXELS_SIZE (SPRITE_PIXELS * SPRITE_PIXELS)

// Initial map zoom: 16px builds start zoomed in so tiles appear at 32px on screen.
constexpr double DefaultMapZoom = SPRITE_PIXELS / 32.0;

// Floor perspective. Top-down (Backlands): each floor above ground is drawn one tile
// higher, with no horizontal shift. Classic Tibia shifts floors diagonally (up and left).
// Must match FLOOR_SHIFT_X in the server and the client. CMake option NEXAMAP_TOPDOWN_FLOORS.
#ifndef NEXAMAP_TOPDOWN_FLOORS
	#define NEXAMAP_TOPDOWN_FLOORS 1
#endif
constexpr int FloorShiftX = NEXAMAP_TOPDOWN_FLOORS ? 0 : 1;

// The sea layer
#define GROUND_LAYER 7

constexpr int ClientMapWidth = 17;
constexpr int ClientMapHeight = 13;

#define MAP_LOAD_FILE_WILDCARD_OTGZ "OpenTibia Binary Map (*.otbm;*.otgz)|*.otbm;*.otgz"
#define MAP_SAVE_FILE_WILDCARD_OTGZ "OpenTibia Binary Map (*.otbm)|*.otbm|Compressed OpenTibia Binary Map (*.otgz)|*.otgz"

#define MAP_LOAD_FILE_WILDCARD "OpenTibia Binary Map (*.otbm)|*.otbm"
#define MAP_SAVE_FILE_WILDCARD "OpenTibia Binary Map (*.otbm)|*.otbm"

// Lights
constexpr int MaxLightIntensity = 8;
constexpr int PixelFormatRGB = 3;
constexpr int PixelFormatRGBA = 4;

// wxString conversions
#define nstr(str) std::string(static_cast<const char*>((str).mb_str(wxConvUTF8)))
#define wxstr(str) wxString((str).c_str(), wxConvUTF8)

// increment & decrement definitions
#define IMPLEMENT_INCREMENT_OP(Type)                        \
	namespace {                                             \
		[[maybe_unused]] Type& operator++(Type& type) {     \
			return (type = static_cast<Type>(type + 1));    \
		}                                                   \
		[[maybe_unused]] Type operator++(Type& type, int) { \
			return static_cast<Type>((++type) - 1);         \
		}                                                   \
	}

#endif
