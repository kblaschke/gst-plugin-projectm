cmake_minimum_required(VERSION 3.21 FATAL_ERROR)

include(CMakeDependentOption)
include(CheckSymbolExists)

set(OpenGL_GL_PREFERENCE "GLVND")

project(gstprojectm VERSION 0.0.1)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

find_package(projectM4 REQUIRED)
find_package(GStreamer REQUIRED COMPONENTS
        gstreamer-audio-1.0
        gstreamer-gl-1.0
        gstreamer-pbutils-1.0
        gstreamer-video-1.0
        )
find_package(GLIB2 REQUIRED)

add_library(gstprojectm SHARED
    src/enums.h
    src/plugin.h
    src/plugin.c
)

target_include_directories(gstprojectm
    PUBLIC
        ${GSTREAMER_INCLUDE_DIRS}
        ${GSTREAMER_BASE_INCLUDE_DIRS}
        ${GSTREAMER_AUDIO_INCLUDE_DIRS}
        ${GSTREAMER_GL_INCLUDE_DIRS}
        ${GLIB2_INCLUDE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(gstprojectm
    PRIVATE
        libprojectM::projectM
    PUBLIC
        GStreamer::gstreamer-gl-1.0
        GStreamer::gstreamer-audio-1.0
        GStreamer::gstreamer-video-1.0
        GStreamer::gstreamer-pbutils-1.0
        ${GLIB2_LIBRARIES}
        ${GLIB2_GOBJECT_LIBRARIES}
)