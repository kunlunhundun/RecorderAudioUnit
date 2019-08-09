#ifndef API
#ifndef PLATFORM_HPP
#define PLATFORM_HPP

/* Detect darwin platform */
#if defined(__APPLE__) && defined(__MACH__)
#define OS_DARWIN
#include <TargetConditionals.h>
#if TARGET_IPHONE_SIMULATOR == 1
#define OS_IOS
#define OS_IOS_SIMULATOR
#elif TARGET_IOS_IPHONE == 1
#define OS_IOS
#elif TARGET_OS_MAC == 1
#define OS_MACX
#endif
#endif
/* Detect win platform */
#if defined(_WIN64)
#define OS_WIN64
#define OS_WIN32
#elif defined(_WIN32)
#define OS_WIN32
#endif
/* Detect android platform */
#if defined(__ANDROID__)
#define OS_ANDROID
#endif
/* Detect linux platform */
#if defined(__linux__) || defined(OS_ANDROID)
#define OS_LINUX
#endif
/* Detect unix platform */
#if defined(OS_LINUX) || defined(OS_DARWIN)
#define OS_UNIX
#endif
#if defined(__AVM2__) || defined(__FLASHPLAYER__)
#define OS_UNIX
#define OS_FLASH
#endif

#ifdef OS_DARWIN
#include <MacTypes.h>
typedef SInt8 Int8;
typedef SInt16 Int16;
typedef SInt32 Int32;
typedef SInt64 Int64;
#else
#include <stdint.h>
typedef int8_t Int8;
typedef uint8_t UInt8;
typedef int16_t Int16;
typedef uint16_t UInt16;
typedef int32_t Int32;
typedef uint32_t UInt32;
typedef int64_t Int64;
typedef uint64_t UInt64;
#endif

#endif /* PLATFORM_HPP */
#endif /* API */
