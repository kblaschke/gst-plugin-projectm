#!/bin/bash
set -e

# ------------
# FUNCTIONS: PACKAGES

# Install packages based on the selected package manager: apt, pacman, brew
install_packages() {
    local AUTO=$1
    local PACKAGE_MANAGER=$2
    local PACKAGE_LIST=("${!3}")
    
    case $PACKAGE_MANAGER in
        apt)
            sudo apt update
            
            if [ $AUTO = true ]; then
                sudo apt install -y "${PACKAGE_LIST[@]}"
            else
                sudo apt install "${PACKAGE_LIST[@]}"
            fi
        ;;
        pacman)
            sudo pacman -Syyu
            
            if [ $AUTO = true ]; then
                sudo pacman -Sy "${PACKAGE_LIST[@]}"
            else
                sudo pacman -S "${PACKAGE_LIST[@]}"
            fi
        ;;
        brew)
            brew update
            
            if [ $AUTO = true ]; then
                brew install "${PACKAGE_LIST[@]}" || true
            else
                brew install "${PACKAGE_LIST[@]}"
            fi
        ;;
    esac
}

# Prompt user to install dependencies, (and choose a package manager, if multiple are available)
prompt_install_dependencies() {
    local AUTO=$1
    
    if [ $AUTO = false ]; then
        echo
        echo -n "Install dependencies? (Y/n): "
        read -r INSTALL_DEPS
    else
        INSTALL_DEPS="Y"
    fi
    
    if [[ "$INSTALL_DEPS" != "N" && "$INSTALL_DEPS" != "n" ]]; then
        # Check for available package managers
        AVAILABLE_PACKAGE_MANAGERS=()
        
        if [ "$(uname)" == "Darwin" ]; then
            if command -v brew &>/dev/null; then
                AVAILABLE_PACKAGE_MANAGERS+=("brew")
            fi
        elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
            if command -v apt &>/dev/null; then
                AVAILABLE_PACKAGE_MANAGERS+=("apt")
            fi
            
            if command -v pacman &>/dev/null; then
                AVAILABLE_PACKAGE_MANAGERS+=("pacman")
            fi
        fi
        
        # Prompt user to choose a package manager
        if [ ${#AVAILABLE_PACKAGE_MANAGERS[@]} -eq 0 ]; then
            echo "No supported package managers found."
            exit 1
            elif [ ${#AVAILABLE_PACKAGE_MANAGERS[@]} -eq 1 ] || [ $AUTO = true ]; then
            SELECTED_PACKAGE_MANAGER=${AVAILABLE_PACKAGE_MANAGERS[0]}
        else
            echo -n "Multiple package managers found. Please choose one:"
            select SELECTED_PACKAGE_MANAGER in "${AVAILABLE_PACKAGE_MANAGERS[@]}"; do
                if [ -n "$SELECTED_PACKAGE_MANAGER" ]; then
                    break
                else
                    echo "Invalid selection. Please choose a number."
                fi
            done
        fi
        
        # Install packages based on the selected package manager
        case $SELECTED_PACKAGE_MANAGER in
            apt)
                PACKAGE_LIST=("git" "cmake" "ninja-build" "pkg-config" "build-essential" "libgl1-mesa-dev" "mesa-common-dev" "libgstreamer1.0-dev" "libgstreamer-gl1.0-0" "libgstreamer-plugins-base1.0-dev" "gstreamer1.0-libav" "libunwind-dev")
                install_packages $AUTO "$SELECTED_PACKAGE_MANAGER" PACKAGE_LIST[@]
            ;;
            pacman)
                PACKAGE_LIST=("git" "cmake" "ninja" "pkgconf" "base-devel"  "mesa" "gst-plugins-base-libs" "gst-libav")
                install_packages $AUTO "$SELECTED_PACKAGE_MANAGER" PACKAGE_LIST[@]
            ;;
            brew)
                PACKAGE_LIST=("git" "cmake" "ninja" "pkg-config" "gstreamer")
                install_packages $AUTO "$SELECTED_PACKAGE_MANAGER" PACKAGE_LIST[@]
            ;;
        esac
    else
        echo
        echo "Skipping dependency installation."
    fi
}

# ------------
# FUNCTIONS: FIXES
# /usr/local/Cellar/gstreamer/1.22.8_2/include/gstreamer-1.0/gst/gl
# Fix missing "#include <gst/gl/gstglconfig.h>"
fix_missing_gstglconfig_h() {
    fix() {
        local FILEPATH=$1
        
        echo
        echo "Fixing missing gst/gl/gstglconfig.h..."
        echo
        
        # Create missing header file
        sudo touch $FILEPATH
        
        # Add contents to header file
        sudo tee $FILEPATH <<EOF
/* gstglconfig.h */

#ifndef __GST_GL_CONFIG_H__
#define __GST_GL_CONFIG_H__

#include <gst/gst.h>

G_BEGIN_DECLS


#define GST_GL_HAVE_OPENGL 1
#define GST_GL_HAVE_GLES2 1
#define GST_GL_HAVE_GLES3 1
#define GST_GL_HAVE_GLES3EXT3_H 1

#define GST_GL_HAVE_WINDOW_X11 1
#define GST_GL_HAVE_WINDOW_COCOA 0
#define GST_GL_HAVE_WINDOW_WIN32 0
#define GST_GL_HAVE_WINDOW_WINRT 0
#define GST_GL_HAVE_WINDOW_WAYLAND 1
#define GST_GL_HAVE_WINDOW_ANDROID 0
#define GST_GL_HAVE_WINDOW_DISPMANX 0
#define GST_GL_HAVE_WINDOW_EAGL 0
#define GST_GL_HAVE_WINDOW_VIV_FB 0
#define GST_GL_HAVE_WINDOW_GBM 1

#define GST_GL_HAVE_PLATFORM_EGL 1
#define GST_GL_HAVE_PLATFORM_GLX 1
#define GST_GL_HAVE_PLATFORM_WGL 0
#define GST_GL_HAVE_PLATFORM_CGL 0
#define GST_GL_HAVE_PLATFORM_EAGL 0

#define GST_GL_HAVE_DMABUF 1
#define GST_GL_HAVE_VIV_DIRECTVIV 0

#define GST_GL_HAVE_GLEGLIMAGEOES 1
#define GST_GL_HAVE_GLCHAR 1
#define GST_GL_HAVE_GLSIZEIPTR 1
#define GST_GL_HAVE_GLINTPTR 1
#define GST_GL_HAVE_GLSYNC 1
#define GST_GL_HAVE_GLUINT64 1
#define GST_GL_HAVE_GLINT64 1
#define GST_GL_HAVE_EGLATTRIB 1
#define GST_GL_HAVE_EGLUINT64KHR 1

G_END_DECLS

#endif  /* __GST_GL_CONFIG_H__ */
EOF
    }
    if [ "$(uname)" == "Darwin" ]; then
        if [ -d "/usr/local/Cellar/gstreamer/1.22.8_2/include/gstreamer-1.0/gst/gl" ] || [ ! -f "/usr/local/Cellar/gstreamer/1.22.8_2/include/gstreamer-1.0/gst/gl/gstglconfig.h" ]; then
            DIRECTORY="/usr/local/Cellar/gstreamer/1.22.8_2/include/gstreamer-1.0/gst/gl"
            FILE="/usr/local/Cellar/gstreamer/1.22.8_2/include/gstreamer-1.0/gst/gl/gstglconfig.h"
        fi
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        if [ -d "/usr/include/gstreamer-1.0/gst/gl" ] || [ ! -f "/usr/include/gstreamer-1.0/gst/gl/gstglconfig.h" ]; then
            DIRECTORY="/usr/include/gstreamer-1.0/gst/gl"
            FILE="/usr/include/gstreamer-1.0/gst/gl/gstglconfig.h"
        fi
    fi

    if [ -d $DIRECTORY ] || [ ! -f $FILE ]; then
        fix $FILE
    elif [ -f $FILE ]; then
        echo
        echo "gst/gl/gstglconfig.h already exists."
    else
        echo
        echo 'Unable to fix missing "#include <gst/gl/gstglconfig.h>".'
    fi
}

# ------------
# Main

AUTO=false

# Skip prompt if --auto is passed
if [ "$1" = "--auto" ] ; then
    AUTO=true
fi

prompt_install_dependencies $AUTO
