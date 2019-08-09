

#import "BilateralFilter.h"
#import <Foundation/Foundation.h>
#import <CoreImage/CIFilter.h>

@implementation BilateralFilter
{
    CIKernel     *_bilateralKernel ;
}

- (id)init
{
    _bilateralRadius = 0.0;//8.0;//取樣範圍
    _bilateralEffect = 0.0;//16.0; ;//值越大，效果越不明顯
    
    NSString* kernelString = [self loadKernelString];
    NSArray* kernels = [CIKernel kernelsWithString:kernelString];

    _bilateralKernel = [kernels objectAtIndex:0];
    
    return [super init];
}


// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    if (_inputImage == nil || _bilateralKernel == nil ) {
        return  nil;
    }
    if ( _bilateralEffect <= 0.01) {
        return _inputImage;
    }

    NSNumber* radius = [NSNumber numberWithFloat:_bilateralRadius];//取樣範圍
    NSNumber* effect = [NSNumber numberWithFloat:_bilateralEffect];//值越大，效果越不明顯
    
    NSArray *argsHor = @[_inputImage,radius,@0.0,effect];
    CIImage* outputHorz = [_bilateralKernel applyWithExtent:_inputImage.extent roiCallback:^CGRect(int index, CGRect destRect) {
        return destRect;
    } arguments:argsHor];
    
    NSArray *argsVer = @[outputHorz,@0.0,radius,effect];
    CIImage* output = [_bilateralKernel applyWithExtent:_inputImage.extent roiCallback:^CGRect(int index, CGRect destRect) {
        return destRect;
    } arguments:argsVer];
    return output;
    
}


-(NSString*)loadKernelString
{
    //        NSString* code =
    //        @"kernel vec4 maskRed(sampler image, float scale, float greenWeight){\n";
    //        @"vec4   p = sample(image, samplerCoord(image));\n";
    //        @"float  x = scale*(p.r - greenWeight*p.g);\n";
    //            @"return vec4(clamp(x, 0.0, 1.0));\n";
    //        @"}";
    
    //        NSString* kernelString =
    //        @"kernel vec4 sobel (sampler image) {\n" \
    //        @"  mat3 sobel_x = mat3( -1, -2, -1, 0, 0, 0, 1, 2, 1 );\n" \
    //        @"  mat3 sobel_y = mat3( 1, 0, -1, 2, 0, -2, 1, 0, -1 );\n" \
    //        @"  float s_x = 0.0;\n" \
    //        @"  float s_y = 0.0;\n" \
    //        @"  vec2 dc = destCoord();\n" \
    //        @"  for (int i=-1; i <= 1; i++) {\n" \
    //        @"    for (int j=-1; j <= 1; j++) {\n" \
    //        @"      vec4 currentSample = sample(image, samplerTransform(image, dc + vec2(i,j)));" \
    //        @"      s_x += sobel_x[j+1][i+1] * currentSample.g;\n" \
    //        @"      s_y += sobel_y[j+1][i+1] * currentSample.g;\n" \
    //        @"    }\n" \
    //        @"  }\n" \
    //        @"  return vec4(s_x, s_y, 0.0, 1.0);\n" \
    //        @"}";
    
    NSString* kernelString =
    @"kernel vec4 HorizonBilateral (sampler image, float verticalOffset, float horizonOffset, float distanceNormalizationFactor) {\n"\
        @"vec2 texcoord = destCoord();\n"\
        @"vec2 coordinate0;\n"\
        @"vec2 coordinate1;\n"\
        @"vec2 coordinate2;\n"\
        @"vec2 coordinate3;\n"\
        @"vec2 coordinate4;\n"\
        @"vec2 coordinate5;\n"\
        @"vec2 coordinate6;\n"\
        @"vec2 coordinate7;\n"\
        @"vec2 coordinate8;\n"\
        @"vec2 stepOffset = vec2(verticalOffset, horizonOffset);\n"\
        @"coordinate4 = texcoord;\n"\
        @"coordinate3 = coordinate4 - stepOffset;\n"\
        @"coordinate2 = coordinate3 - stepOffset;\n"\
        @"coordinate1 = coordinate2 - stepOffset;\n"\
        @"coordinate0 = coordinate1 - stepOffset;\n"\
        @"coordinate5 = coordinate4 + stepOffset;\n"\
        @"coordinate6 = coordinate5 + stepOffset;\n"\
        @"coordinate7 = coordinate6 + stepOffset;\n"\
        @"coordinate8 = coordinate7 + stepOffset;\n"\
        @"vec4 centralColor = sample(image, samplerTransform(image, coordinate4));\n"\
        @"float gaussianWeight = 0.18;\n"\
        @"vec4 totalColor = centralColor * gaussianWeight;\n"\
        @"float totalWeight = gaussianWeight;\n"\
        @"vec4 color = sample(image, samplerTransform(image,coordinate0));\n"\
        @"gaussianWeight = 0.05 * (1.0 - min(distance(centralColor, color) * distanceNormalizationFactor, 1.0));\n"\
        @"totalColor += color * gaussianWeight;\n"\
        @"totalWeight += gaussianWeight;\n"\
        @"color = sample(image, samplerTransform(image,coordinate1));\n"\
        @"gaussianWeight = 0.09 * (1.0 - min(distance(centralColor, color) * distanceNormalizationFactor, 1.0));\n"\
        @"totalColor += color * gaussianWeight;\n"\
        @"totalWeight += gaussianWeight;\n"\
        @"color = sample(image, samplerTransform(image,coordinate2));\n"\
        @"gaussianWeight = 0.12 * (1.0 - min(distance(centralColor, color) * distanceNormalizationFactor, 1.0));\n"\
        @"totalColor += color * gaussianWeight;\n"\
        @"totalWeight += gaussianWeight;\n"\
        @"color = sample(image, samplerTransform(image,coordinate3));\n"\
        @"gaussianWeight = 0.15 * (1.0 - min(distance(centralColor, color) * distanceNormalizationFactor, 1.0));\n"\
        @"totalColor += color * gaussianWeight;\n"\
        @"totalWeight += gaussianWeight;\n"\
        @"color = sample(image, samplerTransform(image,coordinate5));\n"\
        @"gaussianWeight = 0.15 * (1.0 - min(distance(centralColor, color) * distanceNormalizationFactor, 1.0));\n"\
        @"totalColor += color * gaussianWeight;\n"\
        @"totalWeight += gaussianWeight;\n"\
        @"color = sample(image, samplerTransform(image,coordinate6));\n"\
        @"gaussianWeight = 0.12 * (1.0 - min(distance(centralColor, color) * distanceNormalizationFactor, 1.0));\n"\
        @"totalColor += color * gaussianWeight;\n"\
        @"totalWeight += gaussianWeight;\n"\
        @"color = sample(image, samplerTransform(image,coordinate7));\n"\
        @"gaussianWeight = 0.09 * (1.0 - min(distance(centralColor, color) * distanceNormalizationFactor, 1.0));\n"\
        @"totalColor += color * gaussianWeight;\n"\
        @"totalWeight += gaussianWeight;\n"\
        @"color = sample(image, samplerTransform(image,coordinate8));\n"\
        @"gaussianWeight = 0.05 * (1.0 - min(distance(centralColor, color) * distanceNormalizationFactor, 1.0));\n"\
        @"totalColor += color * gaussianWeight;\n"\
        @"totalWeight += gaussianWeight;\n"\
        @"return totalColor / totalWeight;\n"\
    @"}\n";
    return kernelString;
}

@end
