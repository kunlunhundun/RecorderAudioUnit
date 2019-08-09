#ifndef MP3_API_HPP
#define MP3_API_HPP
namespace mp3 {
    extern const char *MAJOR_VERSION;
    extern const char *MINOR_VERSION;
    extern const char *BUILD_VERSION;
    extern const char *VERSION;
}
#ifndef API
/**
 * @file mp3/mp3.h
 * @author zhouqing
 */
#include <string>
#endif /* API */
#ifndef MP3_API_HPP
#include "decoder.hpp"
#include "encoder.hpp"
#include "errorcodes.hpp"
#include "export.hpp"
#include "qualities.hpp"
#include "samplerates.hpp"
#endif /* MP3_API_HPP */
namespace mp3 {
class Decoder {
public:
    virtual bool HeaderParsed() const = 0;
    virtual UInt32 GetSamplerate() const = 0;
    virtual UInt32 GetChannels() const = 0;
    virtual UInt32 GetFrameSize() const = 0;
    virtual UInt32 GetBitrate() const = 0;
    virtual Int32 Decode(UInt8 *input, UInt32 length, Int16 *outputLeft, Int16 *outputRight) = 0;
    virtual Int32 DecodeInterleaved(UInt8 *input, UInt32 length, Int16 *output) = 0;
    virtual void Close() = 0;
};
}
namespace mp3 {
class Encoder {
public:
    virtual void SetInputSamplerate(UInt32 rate) = 0;
    virtual void SetOutputSamplerate(UInt32 rate) = 0;
    virtual void SetChannels(UInt32 channels) = 0;
    virtual void SetQuality(UInt32 quality) = 0;
    virtual void SetBitrate(UInt32 bitrate) = 0;
    virtual void SetCompressionRatio(UInt32 ratio) = 0;
    virtual Int32 Encode(Int16 *inputLeft, Int16 *inputRight, UInt32 samples, UInt8 *output, UInt32 capacity) = 0;
    virtual Int32 EncodeInterleaved(Int16 *input, UInt32 samples, UInt8 *output, UInt32 capacity) = 0;
    virtual UInt32 Flush(UInt8 *output, UInt32 capacity) = 0;
    virtual void Close() = 0;
};
}
namespace mp3 {
namespace ErrorCodes {
    const Int32 ERROR_MAX = -1;
    const Int32 ERROR_UNKNOWN = -1;
    const Int32 ERROR_OUTPUT_TOO_SMALL = -2;
    const Int32 ERROR_OUT_OF_MEMORY = -3;
    const Int32 ERROR_NOT_READY = -4;
    const Int32 ERROR_PSYCHO_ACOUSTIC_PROBLEMS = -5;
    const Int32 ERROR_DECODE = -6;
    const Int32 ERROR_MIN = -50;
}
}
namespace mp3 {
class Decoder;
class Encoder;
Encoder *CreateEncoder();
Decoder *CreateDecoder();
}
namespace mp3 {
namespace Qualities {
    const UInt32 QUALITY_MIN = 0;
    const UInt32 QUALITY_BEST = 0;
    const UInt32 QUALITY_NEAR_BEST = 2;
    const UInt32 QUALITY_GOOD = 5;
    const UInt32 QUALITY_OK = 7;
    const UInt32 QUALITY_FASTEST = 9;
    const UInt32 QUALITY_MAX = 9;
}
}
namespace mp3 {
namespace SampleRates {
    const UInt32 SAMPLE_RATE_44100 = 44100;
    const UInt32 SAMPLE_RATE_48000 = 48000;
    const UInt32 SAMPLE_RATE_32000 = 32000;
    const UInt32 SAMPLE_RATE_22050 = 22050;
    const UInt32 SAMPLE_RATE_24000 = 24000;
    const UInt32 SAMPLE_RATE_16000 = 16000;
    const UInt32 SAMPLE_RATE_11025 = 11025;
    const UInt32 SAMPLE_RATE_12000 = 12000;
    const UInt32 SAMPLE_RATE_8000 = 8000;
    const UInt32 SAMPLE_RATE_0 = 0;
}
}
#endif /* MP3_API_HPP */
