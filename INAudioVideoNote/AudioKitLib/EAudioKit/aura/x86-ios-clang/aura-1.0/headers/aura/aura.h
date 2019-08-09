#ifndef AURA_API_HPP
#define AURA_API_HPP
namespace aura {
    extern const char *MAJOR_VERSION;
    extern const char *MINOR_VERSION;
    extern const char *BUILD_VERSION;
    extern const char *VERSION;
}
#ifndef API
/**
 * @file aura/aura.h
 * @author zhouqing
 */
#include <deque>
#include <string>
#endif /* API */
#ifndef AURA_API_HPP
#include "audiotoolbox.hpp"
#include "export.hpp"
#include "pitchshifter.hpp"
#include "resampler.hpp"
#include "reverber.hpp"
#include "reverboption.hpp"
#include "reverbpreset.hpp"
#endif /* AURA_API_HPP */
namespace aura {
namespace AudioToolbox {
    void ChangeVolume(float factor, const Int16 *input, Int16 *output, UInt32 samples);
    void MixAudio(const Int16 *input1, const Int16 *input2, Int16 *output, UInt32 samples);
    void MonoToStereo(const Int16 *input, Int16 *output, UInt32 samples);
    void StereoToMono(const Int16 *input, Int16 *output, UInt32 samples);
}
}
namespace aura {
namespace ReverbType {
    const UInt8 SOX = 0x00;
    const UInt8 SIMPLE_TANK = 0x01;
}
}
namespace aura {
class PitchShifter;
class Resampler;
class Reverber;
Reverber *CreateReverber(UInt32 samplerate, UInt32 channels, UInt8 type = ReverbType::SOX);
Resampler *CreateResampler(UInt32 inputSamplerate, UInt32 outputSamplerate, UInt32 channels);
PitchShifter *CreatePitchShifter(UInt32 samplerate, UInt32 channels);
}
namespace aura {
class PitchShifter {
public:
    virtual void SetPitch(float pitch) = 0;
    virtual void Offer(const Int16 *input, UInt32 samples) = 0;
    virtual UInt32 Receive(Int16 *output, UInt32 samples) = 0;
    virtual UInt32 Available() const = 0;
    virtual UInt32 Flush() = 0;
    virtual void Close() = 0;
};
}
namespace aura {
namespace SampleType {
    const UInt8 SHORT_SAMPLE = 0x00;
    const UInt8 FLOAT_SAMPLE = 0x01;
}
}
namespace aura {
class Resampler {
public:
    virtual UInt32 Process(const Int16 *input, Int16 *output, UInt32 samples) = 0;
    virtual void Close() = 0;
};
}
namespace aura {
class Reverber {
public:
    virtual bool SetOption(UInt8 option, Int32 value) = 0;
    virtual bool GetOption(UInt8 option, Int32 &value) const = 0;
    virtual bool SetPresetOptions(UInt8 preset) = 0;
    virtual void Process(const Int16 *input, Int16 *output, UInt32 samples) = 0;
    virtual void Reset() = 0;
    virtual void Close() = 0;
};
}
namespace aura {
namespace ReverbOption {
    const UInt8 SOX_OPTION_MIN = 0;
    const UInt8 SOX_ROOM_SIZE = SOX_OPTION_MIN + 0;
    const UInt8 SOX_PRE_DELAY = SOX_OPTION_MIN + 1;
    const UInt8 SOX_REVERBERANCE = SOX_OPTION_MIN + 2;
    const UInt8 SOX_DAMPING = SOX_OPTION_MIN + 3;
    const UInt8 SOX_TONE_LOW = SOX_OPTION_MIN + 4;
    const UInt8 SOX_TONE_HIGH = SOX_OPTION_MIN + 5;
    const UInt8 SOX_WET_GAIN = SOX_OPTION_MIN + 6;
    const UInt8 SOX_DRY_GAIN = SOX_OPTION_MIN + 7;
    const UInt8 SOX_STEREO_WIDTH = SOX_OPTION_MIN + 8;
    const UInt8 SOX_OPTION_MAX = SOX_STEREO_WIDTH;
    const UInt8 SOX_OPTION_TOTAL = SOX_OPTION_MAX - SOX_OPTION_MIN + 1;
    const UInt8 SIMPLE_TANK_OPTION_MIN = 0;
    const UInt8 SIMPLE_TANK_RSFACTOR = SIMPLE_TANK_OPTION_MIN + 0;
    const UInt8 SIMPLE_TANK_WIDTH = SIMPLE_TANK_OPTION_MIN + 1;
    const UInt8 SIMPLE_TANK_DRY = SIMPLE_TANK_OPTION_MIN + 2;
    const UInt8 SIMPLE_TANK_WET = SIMPLE_TANK_OPTION_MIN + 3;
    const UInt8 SIMPLE_TANK_PREDELAY = SIMPLE_TANK_OPTION_MIN + 4;
    const UInt8 SIMPLE_TANK_RT60 = SIMPLE_TANK_OPTION_MIN + 5;
    const UInt8 SIMPLE_TANK_IDIFFUSION1 = SIMPLE_TANK_OPTION_MIN + 6;
    const UInt8 SIMPLE_TANK_IDIFFUSION2 = SIMPLE_TANK_OPTION_MIN + 7;
    const UInt8 SIMPLE_TANK_DIFFUSION1 = SIMPLE_TANK_OPTION_MIN + 8;
    const UInt8 SIMPLE_TANK_DIFFUSION2 = SIMPLE_TANK_OPTION_MIN + 9;
    const UInt8 SIMPLE_TANK_INPUTDAMP = SIMPLE_TANK_OPTION_MIN + 10;
    const UInt8 SIMPLE_TANK_DAMP = SIMPLE_TANK_OPTION_MIN + 11;
    const UInt8 SIMPLE_TANK_OUTPUTDAMP = SIMPLE_TANK_OPTION_MIN + 12;
    const UInt8 SIMPLE_TANK_SPIN = SIMPLE_TANK_OPTION_MIN + 13;
    const UInt8 SIMPLE_TANK_SPINDIFF = SIMPLE_TANK_OPTION_MIN + 14;
    const UInt8 SIMPLE_TANK_SPINLIMIT = SIMPLE_TANK_OPTION_MIN + 15;
    const UInt8 SIMPLE_TANK_WANDER = SIMPLE_TANK_OPTION_MIN + 16;
    const UInt8 SIMPLE_TANK_DCCUTFREQ = SIMPLE_TANK_OPTION_MIN + 17;
    const UInt8 SIMPLE_TANK_OPTION_MAX = SIMPLE_TANK_DCCUTFREQ;
    const UInt8 SIMPLE_TANK_OPTION_TOTAL = SIMPLE_TANK_OPTION_MAX - SIMPLE_TANK_OPTION_MIN + 1;
}
}
namespace aura {
namespace ReverbPreset {
    const UInt8 PRESET_MIN = 0x00;
    const UInt8 KARAOKE = 0x00;
    const UInt8 STUDIO = 0x01;
    const UInt8 CONCERT = 0x02;
    const UInt8 THEATER = 0x03;
    const UInt8 PRESET_MAX = THEATER;
    const UInt8 PRESET_TOTAL = PRESET_MAX + 1;
}
}
#endif /* AURA_API_HPP */
