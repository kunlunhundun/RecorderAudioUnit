

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>

@interface BilateralFilter : CIFilter

@property (strong,nonatomic) CIImage* inputImage;
@property (assign,nonatomic) float bilateralRadius;//取樣範圍
@property (assign,nonatomic) float bilateralEffect;//值越大，效果越不明顯

@end
