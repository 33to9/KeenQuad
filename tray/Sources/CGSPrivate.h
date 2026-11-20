// SPDX-License-Identifier: GPL-3.0-only
// Copyright © 2026 33to9
// Private CoreGraphics declarations. All private API use is kept in this header and PrivateDisplay.swift.
// The struct must be exactly 212 bytes.
#include <CoreGraphics/CoreGraphics.h>
#include <stdint.h>

typedef struct {
    uint32_t modeNumber;
    uint32_t flags;
    uint32_t width;
    uint32_t height;
    uint32_t depth;
    uint8_t unknown[170];
    uint16_t freq;
    uint8_t more_unknown[16];
    float density;
} CGSDisplayMode;

_Static_assert(sizeof(CGSDisplayMode) == 212, "CGSDisplayMode must be 212 bytes");

extern void CGSGetNumberOfDisplayModes(CGDirectDisplayID display, int *count);
extern void CGSGetDisplayModeDescriptionOfLength(CGDirectDisplayID display, int index, CGSDisplayMode *mode, int length);
extern void CGSGetCurrentDisplayMode(CGDirectDisplayID display, int *modeNumber);
extern CGError CGSConfigureDisplayMode(CGDisplayConfigRef config, CGDirectDisplayID display, int modeNumber);
