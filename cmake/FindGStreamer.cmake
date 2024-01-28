# - Try to find GStreamer and its plugins
# Once done, this will define
#
#  GSTREAMER_FOUND - system has GStreamer
#  GSTREAMER_INCLUDE_DIRS - the GStreamer include directories
#  GSTREAMER_LIBRARIES - link these to use GStreamer
#
# Additionally, gstreamer-base is always looked for and required, and
# the following related variables are defined:
#
#  GSTREAMER_BASE_INCLUDE_DIRS - gstreamer-base's include directory
#  GSTREAMER_BASE_LIBRARIES - link to these to use gstreamer-base
#
# Optionally, the COMPONENTS keyword can be passed to find_package()
# and GStreamer plugins can be looked for.  Currently, the following
# plugins can be searched, and they define the following variables if
# found:
#
#  gstreamer-app:        GSTREAMER_APP_INCLUDE_DIRS and GSTREAMER_APP_LIBRARIES
#  gstreamer-audio:      GSTREAMER_AUDIO_INCLUDE_DIRS and GSTREAMER_AUDIO_LIBRARIES
#  gstreamer-gl:         GSTREAMER_GL_INCLUDE_DIRS and GSTREAMER_GL_LIBRARIES
#
# Copyright (C) 2012 Raphael Kubo da Costa <rakuco@webkit.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1.  Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
# 2.  Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER AND ITS CONTRIBUTORS ``AS
# IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR ITS
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set(CMAKE_SYSTEM_TRIPLET "${CMAKE_SYSTEM_PROCESSOR}-${VENDOR}-${CMAKE_SYSTEM_NAME}")

find_package(PkgConfig REQUIRED QUIET)

# Helper macro to find a GStreamer plugin (or GStreamer itself)
#   _component_prefix is prepended to the _INCLUDE_DIRS and _LIBRARIES variables (eg. "GSTREAMER_AUDIO")
#   _pkgconfig_name is the component's pkg-config name (eg. "gstreamer-1.0", or "gstreamer-video-1.0").
macro(FIND_GSTREAMER_COMPONENT _pkgconfig_name)
	string(TOUPPER ${_pkgconfig_name} _UPPER_NAME)
	pkg_check_modules(${_UPPER_NAME} QUIET ${_pkgconfig_name})
	list(APPEND _GSTREAMER_REQUIRED_VARS
			${_UPPER_NAME}_INCLUDE_DIRS
			${_UPPER_NAME}_LIBRARIES
			)
endmacro()

# ------------------------
# 1. Find GStreamer itself
# ------------------------

# 1.1. Find headers and libraries
find_gstreamer_component(gstreamer-1.0)
find_gstreamer_component(gstreamer-base-1.0)

# 1.3. Check GStreamer version
if (GSTREAMER_INCLUDE_DIRS)
	if (EXISTS "${GSTREAMER_INCLUDE_DIRS}/gst/gstversion.h")
		file(READ "${GSTREAMER_INCLUDE_DIRS}/gst/gstversion.h" GSTREAMER_VERSION_CONTENTS)

		string(REGEX MATCH "#define +GST_VERSION_MAJOR +\\(([0-9]+)\\)" _dummy "${GSTREAMER_VERSION_CONTENTS}")
		set(GSTREAMER_VERSION_MAJOR "${CMAKE_MATCH_1}")

		string(REGEX MATCH "#define +GST_VERSION_MINOR +\\(([0-9]+)\\)" _dummy "${GSTREAMER_VERSION_CONTENTS}")
		set(GSTREAMER_VERSION_MINOR "${CMAKE_MATCH_1}")

		string(REGEX MATCH "#define +GST_VERSION_MICRO +\\(([0-9]+)\\)" _dummy "${GSTREAMER_VERSION_CONTENTS}")
		set(GSTREAMER_VERSION_MICRO "${CMAKE_MATCH_1}")

		set(GSTREAMER_VERSION "${GSTREAMER_VERSION_MAJOR}.${GSTREAMER_VERSION_MINOR}.${GSTREAMER_VERSION_MICRO}")
	endif ()
endif ()

if ("${GStreamer_FIND_VERSION}" VERSION_GREATER "${GSTREAMER_VERSION}")
	message(FATAL_ERROR "Required version (" ${GStreamer_FIND_VERSION} ") is higher than found version (" ${GSTREAMER_VERSION} ")")
endif ()

# ------------------------------------------------
# 3. Process the COMPONENTS passed to FIND_PACKAGE
# ------------------------------------------------
set(_GSTREAMER_REQUIRED_VARS GSTREAMER_INCLUDE_DIRS GSTREAMER_LIBRARIES GSTREAMER_VERSION GSTREAMER_BASE_INCLUDE_DIRS GSTREAMER_BASE_LIBRARIES)

foreach (_component ${GStreamer_FIND_COMPONENTS})
	find_gstreamer_component(${_component})
endforeach ()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GStreamer REQUIRED_VARS _GSTREAMER_REQUIRED_VARS
											VERSION_VAR   GSTREAMER_VERSION)

# Create targets
if(NOT TARGET GStreamer::gstreamer-1.0)
	add_library(GStreamer::gstreamer-1.0 INTERFACE)

	target_include_directories(GStreamer::gstreamer-1.0
			INTERFACE
			${GSTREAMER-1.0_INCLUDE_DIRS}
			)
	set_target_properties(GStreamer::gstreamer-1.0 PROPERTIES
			INTERFACE_LINK_LIBRARIES "${GSTREAMER-1.0_LIBRARIES}"
			)
endif()

if(NOT TARGET GStreamer::gstreamer-base-1.0)
	add_library(GStreamer::gstreamer-base-1.0 INTERFACE)

	target_include_directories(GStreamer::gstreamer-base-1.0
			INTERFACE
			${GSTREAMER_BASE-1.0_INCLUDE_DIRS}
			)
	set_target_properties(GStreamer::gstreamer-base-1.0 PROPERTIES
			INTERFACE_LINK_LIBRARIES "${GSTREAMER_BASE-1.0_LIBRARIES}"
			)
endif()

foreach (_component ${GStreamer_FIND_COMPONENTS})
	string(TOUPPER ${_component} _UPPER_NAME)

	if(NOT TARGET GStreamer::${_component})
		message(STATUS "Adding target GStreamer::${_component}")
		add_library(GStreamer::${_component} INTERFACE)

		target_include_directories(GStreamer::${_component}
				INTERFACE
				${${_UPPER_NAME}_INCLUDE_DIRS}
				)
		set_target_properties(GStreamer::${_component} PROPERTIES
				INTERFACE_LINK_LIBRARIES "${${_UPPER_NAME}_LIBRARIES}"
				)
		add_dependencies(GStreamer::${_component}
				GStreamer::gstreamer-1.0
				GStreamer::gstreamer-base-1.0
				)
	endif()
endforeach ()
