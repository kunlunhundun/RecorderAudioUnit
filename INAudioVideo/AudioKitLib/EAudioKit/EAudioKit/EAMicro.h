

#import <AVFoundation/AVFoundation.h>
#define kOutputBus 0
#define kInputBus 1

#define LIMIT_VALUE(value,min,max) MIN(max,MAX(value,min))

#ifdef DEBUG
#define SHOW_ERROR(err,msg)             NSLog(@"!!!!err:%d,%s",(int)err,msg);
#define CHECK_ERROR(err,msg)            if(err != noErr){NSLog(@"!!!!err:%d,%s",(int)err,msg);}
#define CHECK_ERROR_RET(err)            if(err != noErr)return;
#define CHECK_ERROR_MSG_RET(err,msg)    if(err != noErr){NSLog(@"!!!!err:%d,%s",(int)err,msg);return;}
#define CHECK_ERROR_MSG_RET_NO(err,msg)    if(err != noErr){NSLog(@"!!!!err:%d,%s",(int)err,msg);return NO;}

//代码执行时长统计
#define TIME_SLAPS_TRACER(name,threshold)   EATimeSlapsTracer* __EATimeSlapsTracer_xyz = [[EATimeSlapsTracer alloc] initWithName:@name withThreshold:threshold];

//函数调用频率统计
#define INVOLKE_CALC_DEFINE(name)     static EAInvokeFreq* g_xxxEAInvokeFreqxx = [[EAInvokeFreq alloc] initWithName:@name];[g_xxxEAInvokeFreqxx invoke];

//实例生成销毁跟踪
#define MARK_INSTANCE()         [EAInstaceTracker addInstace:self];
#define UNMARK_INSTANCE()       [EAInstaceTracker removeInstance:self];
#define PRINT_INSTANCE()        [EAInstaceTracker printInstance];

//打印一次LOG
#define LOG_ONCE(...) static dispatch_once_t _xxLogerDispatchxxx;dispatch_once(&_xxLogerDispatchxxx, ^{NSLog(__VA_ARGS__);});

#else //DEBUG

#define SHOW_ERROR(err,msg)
#define CHECK_ERROR(err,msg)
#define CHECK_ERROR_RET(err)
#define CHECK_ERROR_MSG_RET(err,msg)
#define CHECK_ERROR_MSG_RET_NO(err,msg)

#define INVOLKE_CALC_DEFINE(name)

#define MARK_INSTANCE()
#define UNMARK_INSTANCE()
#define PRINT_INSTANCE()

#define TIME_SLAPS_TRACER(name,threshold)   

#define LOG_ONCE(...)

#endif //DEBUG
