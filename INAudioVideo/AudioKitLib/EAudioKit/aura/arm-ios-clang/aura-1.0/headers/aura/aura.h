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
#include "compressor.hpp"
#include "compressoroption.hpp"
#include "export.hpp"
#include "equalizer.hpp"
#include "limiter.hpp"
#include "limiteroption.hpp"
#include "pitchdetector.hpp"
#include "pitchshifter.hpp"
#include "resampler.hpp"
#include "reverber.hpp"
#include "reverboption.hpp"
#include "reverbpreset.hpp"
#include "visualizer.hpp"
#include "spectrum.hpp"
#endif /* AURA_API_HPP */
namespace aura {
namespace AudioToolbox {
    float FactorForDecibels(float decibels);
    void AdjustVolume(float factor, const Int16 *input, Int16 *output, UInt32 samples);
    void AdjustVolume(float factor, const float *input, float *output, UInt32 samples);
    void MixAudio(const Int16 *input1, const Int16 *input2, Int16 *output, UInt32 samples);
    void MixAudio(const float *input1, const float *input2, float *output, UInt32 samples);
    void MonoToStereo(const Int16 *input, Int16 *output, UInt32 samples);
    void MonoToStereo(const float *input, float *output, UInt32 samples);
    void StereoToMono(const Int16 *input, Int16 *output, UInt32 samples);
    void StereoToMono(const float *input, float *output, UInt32 samples);
}
}
namespace aura {
class Compressor {
public:
    virtual bool SetOption(UInt8 option, float value) = 0;
    virtual bool GetOption(UInt8 option, float &value) const = 0;
    virtual void Process(const float *input, float *output, UInt32 samples) = 0;
    virtual void Close() = 0;
};
}
namespace aura {
namespace CompressorOption {
    const UInt8 OPTION_MIN = 0;
    const UInt8 ROOT_MEAN_SQUARE = OPTION_MIN + 0;
    const UInt8 SOFTKNEE = OPTION_MIN + 1;
    const UInt8 ATTACK = OPTION_MIN + 2;
    const UInt8 RELEASE = OPTION_MIN + 3;
    const UInt8 THRESHOLD = OPTION_MIN + 4;
    const UInt8 RATIO = OPTION_MIN + 5;
    const UInt8 OPTION_MAX = RATIO;
    const UInt8 OPTION_TOTAL = OPTION_MAX - OPTION_MIN + 1;
}
}
namespace aura {
namespace ReverbType {
    const UInt8 SOX = 0x00;
    const UInt8 SIMPLE_TANK = 0x01;
    const UInt8 NVERB = 0x02;
    const UInt8 ZONE = 0x03;
    const UInt8 LVM = 0x04;
    const UInt8 OPENAL = 0x05;
    const UInt8 PROGENITOR = 0x06;
}
}
namespace aura {
namespace SampleType {
    const UInt8 SHORT_SAMPLE = 0x00;
    const UInt8 FLOAT_SAMPLE = 0x01;
}
}
namespace aura {
class PitchShifter;
class Resampler;
class Reverber;
class PitchDetector;
class Limiter;
class Compressor;
class Equalizer;
class Visualizer;
Reverber *CreateReverber(UInt32 samplerate, UInt32 channels, UInt8 type = ReverbType::SOX, UInt8 sampletype = SampleType::SHORT_SAMPLE);
Resampler *CreateResampler(UInt32 inputSamplerate, UInt32 outputSamplerate, UInt32 channels, UInt8 sampletype = SampleType::SHORT_SAMPLE);
PitchShifter *CreatePitchShifter(UInt32 samplerate, UInt32 channels, UInt8 sampletype = SampleType::SHORT_SAMPLE);
PitchDetector *CreatePitchDetector(UInt32 samplerate, UInt32 channels, UInt8 sampletype = SampleType::SHORT_SAMPLE);
Limiter *CreateLimiter(UInt32 samplerate, UInt32 channels, UInt8 sampletype = SampleType::SHORT_SAMPLE);
Compressor *CreateCompressor(UInt32 samplerate, UInt32 channels);
Equalizer *CreateEqualizer();
Visualizer *CreateVisualizer(UInt32 channels);
}
namespace aura {
class Equalizer {
public:
    virtual void SetLowPassParam(float low) = 0;
    virtual void SetHighPassParam(float high) = 0;
    virtual void Process(const void *input, void *output, UInt32 samples) = 0;
    virtual void Close() = 0;
};
}
namespace aura {
class Limiter {
public:
    virtual bool SetOption(UInt8 option, float value) = 0;
    virtual bool GetOption(UInt8 option, float &value) const = 0;
    virtual void Process(const void **inputs, void **outputs, UInt32 samples) = 0;
    virtual void ProcessInterleave(const void *input, void *output, UInt32 samples) = 0;
    virtual void Close() = 0;
};
}
namespace aura {
namespace LimiterOption {
    const UInt8 OPTION_MIN = 0;
    const UInt8 ROOT_MEAN_SQUARE = OPTION_MIN + 0;
    const UInt8 LOOKAHEAD = OPTION_MIN + 1;
    const UInt8 ATTACK = OPTION_MIN + 2;
    const UInt8 RELEASE = OPTION_MIN + 3;
    const UInt8 THRESHOLD = OPTION_MIN + 4;
    const UInt8 CEILING = OPTION_MIN + 5;
    const UInt8 OPTION_MAX = CEILING;
    const UInt8 OPTION_TOTAL = OPTION_MAX - OPTION_MIN + 1;
}
}
namespace aura {
class PitchDetector {
public:
    virtual void Offer(const void *input, UInt32 samples) = 0;
    virtual float GetPitch() = 0;
    virtual void Close() = 0;
};
}
namespace aura {
class PitchShifter {
public:
    virtual void SetPitch(float pitch) = 0;
    virtual void SetPitchSemiTones(Int32 semiTones) = 0;
    virtual void Offer(const void **inputs, UInt32 samples) = 0;
    virtual UInt32 Receive(void **outputs, UInt32 samples) = 0;
    virtual void OfferInterleave(const void *input, UInt32 samples) = 0;
    virtual UInt32 ReceiveInterleave(void *output, UInt32 samples) = 0;
    virtual UInt32 Available() const = 0;
    virtual UInt32 Flush() = 0;
    virtual void Close() = 0;
};
}
namespace aura {
class Resampler {
public:
    virtual void Offer(const void *input, UInt32 samples) = 0;
    virtual UInt32 Receive(void *output, UInt32 samples) = 0;
    virtual UInt32 Available() const = 0;
    virtual UInt32 Flush() = 0;
    virtual void Close() = 0;
};
}
namespace aura {
class Reverber {
public:
    virtual bool SetOption(UInt8 option, float value) = 0;
    virtual bool GetOption(UInt8 option, float &value) const = 0;
    virtual bool SetPresetOptions(UInt8 preset) = 0;
    virtual void Process(const void **inputs, void **outputs, UInt32 samples) = 0;
    virtual void ProcessInterleave(const void *input, void *output, UInt32 samples) = 0;
    virtual void Reset() = 0;
    virtual void Close() = 0;
};
}
namespace aura {
namespace ReverbOption {
    /* SOX reverber option */
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
    /* simple tank reverber option */
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
    const UInt8 SIMPLE_TANK_MNOISE1 = SIMPLE_TANK_OPTION_MIN + 18;
    const UInt8 SIMPLE_TANK_MNOISE2 = SIMPLE_TANK_OPTION_MIN + 19;
    const UInt8 SIMPLE_TANK_SIZEFACTOR = SIMPLE_TANK_OPTION_MIN + 20;
    const UInt8 SIMPLE_TANK_OPTION_MAX = SIMPLE_TANK_SIZEFACTOR;
    const UInt8 SIMPLE_TANK_OPTION_TOTAL = SIMPLE_TANK_OPTION_MAX - SIMPLE_TANK_OPTION_MIN + 1;
    /* nverb reverber option */
    const UInt8 NVERB_OPTION_MIN = 0;
    const UInt8 NVERB_RSFACTOR = NVERB_OPTION_MIN + 0;
    const UInt8 NVERB_WIDTH = NVERB_OPTION_MIN + 1;
    const UInt8 NVERB_DRY = NVERB_OPTION_MIN + 2;
    const UInt8 NVERB_WET = NVERB_OPTION_MIN + 3;
    const UInt8 NVERB_PREDELAY = NVERB_OPTION_MIN + 4;
    const UInt8 NVERB_RT60 = NVERB_OPTION_MIN + 5;
    const UInt8 NVERB_DAMP = NVERB_OPTION_MIN + 6;
    const UInt8 NVERB_DAMP2 = NVERB_OPTION_MIN + 7;
    const UInt8 NVERB_DAMP3 = NVERB_OPTION_MIN + 8;
    const UInt8 NVERB_FEEDBACK = NVERB_OPTION_MIN + 9;
    const UInt8 NVERB_OPTION_MAX = NVERB_FEEDBACK;
    const UInt8 NVERB_OPTION_TOTAL = NVERB_OPTION_MAX - NVERB_OPTION_MIN + 1;
    /* zone reverber option */
    const UInt8 ZONE_OPTION_MIN = 0;
    const UInt8 ZONE_RSFACTOR = ZONE_OPTION_MIN + 0;
    const UInt8 ZONE_WIDTH = ZONE_OPTION_MIN + 1;
    const UInt8 ZONE_DRY = ZONE_OPTION_MIN + 2;
    const UInt8 ZONE_WET = ZONE_OPTION_MIN + 3;
    const UInt8 ZONE_LOOPDAMP = ZONE_OPTION_MIN + 4;
    const UInt8 ZONE_RT60 = ZONE_OPTION_MIN + 5;
    const UInt8 ZONE_OUTPUTLPF = ZONE_OPTION_MIN + 6;
    const UInt8 ZONE_APFEEDBACK = ZONE_OPTION_MIN + 7;
    const UInt8 ZONE_OPTION_MAX = ZONE_APFEEDBACK;
    const UInt8 ZONE_OPTION_TOTAL = ZONE_OPTION_MAX - ZONE_OPTION_MIN + 1;
    /* openal reverber option */
    const UInt8 OPENAL_OPTION_MIN = 0;
    const UInt8 OPENAL_DENSITY = OPENAL_OPTION_MIN + 0;
    const UInt8 OPENAL_DIFFUSION = OPENAL_OPTION_MIN + 1;
    const UInt8 OPENAL_GAIN = OPENAL_OPTION_MIN + 2;
    const UInt8 OPENAL_GAIN_HF = OPENAL_OPTION_MIN + 3;
    const UInt8 OPENAL_GAIN_LF = OPENAL_OPTION_MIN + 4;
    const UInt8 OPENAL_DECAY_TIME = OPENAL_OPTION_MIN + 5;
    const UInt8 OPENAL_DECAY_HF_RATIO = OPENAL_OPTION_MIN + 6;
    const UInt8 OPENAL_DECAY_LF_RATIO = OPENAL_OPTION_MIN + 7;
    const UInt8 OPENAL_REFLECTIONS_GAIN = OPENAL_OPTION_MIN + 8;
    const UInt8 OPENAL_REFLECTIONS_DELAY = OPENAL_OPTION_MIN + 9;
    const UInt8 OPENAL_REFLECTIONS_PAN0 = OPENAL_OPTION_MIN + 10;
    const UInt8 OPENAL_REFLECTIONS_PAN1 = OPENAL_OPTION_MIN + 11;
    const UInt8 OPENAL_REFLECTIONS_PAN2 = OPENAL_OPTION_MIN + 12;
    const UInt8 OPENAL_LATE_REVERB_GAIN = OPENAL_OPTION_MIN + 13;
    const UInt8 OPENAL_LATE_REVERB_DELAY = OPENAL_OPTION_MIN + 14;
    const UInt8 OPENAL_LATE_REVERB_PAN0 = OPENAL_OPTION_MIN + 15;
    const UInt8 OPENAL_LATE_REVERB_PAN1 = OPENAL_OPTION_MIN + 16;
    const UInt8 OPENAL_LATE_REVERB_PAN2 = OPENAL_OPTION_MIN + 17;
    const UInt8 OPENAL_ECHO_TIME = OPENAL_OPTION_MIN + 18;
    const UInt8 OPENAL_ECHO_DEPTH = OPENAL_OPTION_MIN + 19;
    const UInt8 OPENAL_MODULATION_TIME = OPENAL_OPTION_MIN + 20;
    const UInt8 OPENAL_MODULATION_DEPTH = OPENAL_OPTION_MIN + 21;
    const UInt8 OPENAL_AIR_ABSORPTION_GAIN_HF = OPENAL_OPTION_MIN + 22;
    const UInt8 OPENAL_HF_REFERENCE = OPENAL_OPTION_MIN + 23;
    const UInt8 OPENAL_LF_REFERENCE = OPENAL_OPTION_MIN + 24;
    const UInt8 OPENAL_ROOM_ROLL_OFF_FACTOR = OPENAL_OPTION_MIN + 25;
    const UInt8 OPENAL_DECAY_HF_LIMIT = OPENAL_OPTION_MIN + 26;
    const UInt8 OPENAL_OPTION_MAX = OPENAL_DECAY_HF_LIMIT;
    const UInt8 OPENAL_OPTION_TOTAL = OPENAL_OPTION_MAX - OPENAL_OPTION_MIN + 1;
    /* progenitor reverber option */
    const UInt8 PROGENITOR_OPTION_MIN = 0;
    const UInt8 PROGENITOR_RSFACTOR = PROGENITOR_OPTION_MIN + 0;
    const UInt8 PROGENITOR_DRY = PROGENITOR_OPTION_MIN + 1;
    const UInt8 PROGENITOR_WET = PROGENITOR_OPTION_MIN + 2;
    const UInt8 PROGENITOR_IDELAY = PROGENITOR_OPTION_MIN + 3;
    const UInt8 PROGENITOR_WIDTH = PROGENITOR_OPTION_MIN + 4;
    const UInt8 PROGENITOR_RT60 = PROGENITOR_OPTION_MIN + 5;
    const UInt8 PROGENITOR_DECAY0 = PROGENITOR_OPTION_MIN + 6;
    const UInt8 PROGENITOR_DECAY1 = PROGENITOR_OPTION_MIN + 7;
    const UInt8 PROGENITOR_DECAY2 = PROGENITOR_OPTION_MIN + 8;
    const UInt8 PROGENITOR_DECAY3 = PROGENITOR_OPTION_MIN + 9;
    const UInt8 PROGENITOR_DECAYF = PROGENITOR_OPTION_MIN + 10;
    const UInt8 PROGENITOR_DIFF1 = PROGENITOR_OPTION_MIN + 11;
    const UInt8 PROGENITOR_DIFF2 = PROGENITOR_OPTION_MIN + 12;
    const UInt8 PROGENITOR_DIFF3 = PROGENITOR_OPTION_MIN + 13;
    const UInt8 PROGENITOR_DIFF4 = PROGENITOR_OPTION_MIN + 14;
    const UInt8 PROGENITOR_IDIFF1 = PROGENITOR_OPTION_MIN + 15;
    const UInt8 PROGENITOR_IDIFF2 = PROGENITOR_OPTION_MIN + 16;
    const UInt8 PROGENITOR_ICROSSF = PROGENITOR_OPTION_MIN + 17;
    const UInt8 PROGENITOR_DCCUT = PROGENITOR_OPTION_MIN + 18;
    const UInt8 PROGENITOR_IDAMP = PROGENITOR_OPTION_MIN + 19;
    const UInt8 PROGENITOR_DAMP = PROGENITOR_OPTION_MIN + 20;
    const UInt8 PROGENITOR_ODAMP = PROGENITOR_OPTION_MIN + 21;
    const UInt8 PROGENITOR_ODAMPBW = PROGENITOR_OPTION_MIN + 22;
    const UInt8 PROGENITOR_DAMP2BW = PROGENITOR_OPTION_MIN + 23;
    const UInt8 PROGENITOR_DAMP2 = PROGENITOR_OPTION_MIN + 24;
    const UInt8 PROGENITOR_BASSBOOST = PROGENITOR_OPTION_MIN + 25;
    const UInt8 PROGENITOR_SPIN = PROGENITOR_OPTION_MIN + 26;
    const UInt8 PROGENITOR_MNOISE1 = PROGENITOR_OPTION_MIN + 27;
    const UInt8 PROGENITOR_MNOISE2 = PROGENITOR_OPTION_MIN + 28;
    const UInt8 PROGENITOR_SPINLIMIT = PROGENITOR_OPTION_MIN + 29;
    const UInt8 PROGENITOR_WANDER = PROGENITOR_OPTION_MIN + 30;
    const UInt8 PROGENITOR_SPIN2 = PROGENITOR_OPTION_MIN + 31;
    const UInt8 PROGENITOR_SPINLIMIT2 = PROGENITOR_OPTION_MIN + 32;
    const UInt8 PROGENITOR_WANDER2 = PROGENITOR_OPTION_MIN + 33;
    const UInt8 PROGENITOR_SPIN2FREQ = PROGENITOR_OPTION_MIN + 34;
    const UInt8 PROGENITOR_REVTYPE = PROGENITOR_OPTION_MIN + 35;
    const UInt8 PROGENITOR_OPTION_MAX = PROGENITOR_REVTYPE;
    const UInt8 PROGENITOR_OPTION_TOTAL = PROGENITOR_OPTION_MAX - PROGENITOR_OPTION_MIN + 1;
}
}
namespace aura {
namespace ReverbPreset {
    const UInt8 PRESET_MIN = 0x00;
    const UInt8 STUDIO = 0;
    const UInt8 KARAOKE = 1;
    const UInt8 CONCERT = 2;
    const UInt8 THEATER = 3;
    const UInt8 PRESET_MAX = THEATER;
    const UInt8 PRESET_TOTAL = PRESET_MAX + 1;
}
}
namespace aura {
class Visualizer {
public:
    virtual bool Process(float *input, int inputSize, int windowSize, float rate, float *output, bool autocorrelation, int windowFunc) = 0;
};
}
namespace aura {
class Spectrum : public Visualizer {
public:
    Spectrum(UInt32 channel);
    virtual ~Spectrum();
public:
    virtual bool Process(float *input, int samples, int windowSize, float rate, float *out, bool autocorrelation, int windowFunc);
private:
    int channel_;
};
}
#endif /* AURA_API_HPP */
