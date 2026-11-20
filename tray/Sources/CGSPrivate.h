// SPDX-License-Identifier: GPL-3.0-only
// Copyright © 2026 33to9
// 私有接口声明（N5：全部集中在此头文件与 PrivateDisplay.swift 中）。
// 结构体大小必须为 212 字节，见需求文档 6.1 / 附录 A。
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
