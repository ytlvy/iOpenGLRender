//
//  GLSLBox.m
//  testOpenGLESRender
//
//  Created by admin on 2023/9/11.
//  Copyright © 2023 Lyman Li. All rights reserved.
//

#import "GLSLBox.h"
#import <GLKit/GLKit.h>

/**
 定义顶点类型
 */
typedef struct {
    GLKVector3 positionCoord; // (X, Y, Z)
    GLKVector2 textureCoord; // (U, V)
} SenceVertex;

@interface GLSLBox()

@property (nonatomic, assign) SenceVertex *vertices; // 顶点数组
@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (assign, nonatomic) GLuint uTime;
@property (assign, nonatomic) GLuint uResolution;
@property (assign, nonatomic) NSTimeInterval startTime;
@property (assign, nonatomic) GLuint program;

@property (nonatomic, assign) CGFloat aspectRatio;


@property (nonatomic, assign) GLuint vertexBuffer;

@property (nonatomic, assign) GLuint renderBuffer;
@property (nonatomic, assign) GLuint frameBuffer;

@end

@implementation GLSLBox

- (void)dealloc {
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    // C语言风格的数组，需要手动释放
    if (_vertices) {
        free(_vertices);
        _vertices = nil;
    }
    
    [self freeMemory];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    // 创建上下文，使用 2.0 版本
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:self.context];
    
    // 创建一个展示纹理的层
    CAEAGLLayer *layer = [[CAEAGLLayer alloc] init];
    layer.frame = CGRectMake(0, 100, self.frame.size.width, self.frame.size.width);
    layer.contentsScale = [[UIScreen mainScreen] scale];  // 设置缩放比例，不设置的话，纹理会失真
    [self.layer addSublayer:layer];
    
    
    // 绑定纹理输出的层
    [self bindRenderLayer:layer];
    
    // 设置视口尺寸
    glViewport(0, 0, self.drawableWidth, self.drawableHeight);
    
    glClearColor(0.5, 0.5, 0.5, 1);
    
    [self setupShader];
    [self setupParam];
    [self startDisplayLinkIfNeeded];
}

- (void)setupShader {
    
    // 编译链接 shader
    GLuint program = [self programWithShaderName:@"glsl"]; // glsl.vsh & glsl.fsh
    glUseProgram(program);
    self.program = program;
}

- (void)setupParam {
    GLuint program = self.program;
    
    self.aspectRatio = (CGFloat)CGRectGetWidth(self.bounds)/(CGFloat)CGRectGetHeight(self.bounds);
    
    // 获取 shader 中的参数，然后传数据进去
    GLuint textureSlot = glGetUniformLocation(program, "u_texture");  // 注意 Uniform 类型的获取方式
    
    // 创建顶点数组
    self.vertices = malloc(sizeof(SenceVertex) * 4); // 4 个顶点
    self.vertices[0] = (SenceVertex){{-1, 1, 0}, {0, 1}}; // 左上角
    self.vertices[1] = (SenceVertex){{-1, -1, 0}, {0, 0}}; // 左下角
    self.vertices[2] = (SenceVertex){{1, 1, 0}, {1, 1}}; // 右上角
    self.vertices[3] = (SenceVertex){{1, -1, 0}, {1, 0}}; // 右下角
    
    // 创建顶点缓存
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    GLsizeiptr bufferSizeBytes = sizeof(SenceVertex) * 4;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_DYNAMIC_DRAW);
    
    // 设置顶点数据
    GLuint positionSlot = glGetAttribLocation(program, "i_position");
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, positionCoord));
    
    // 设置纹理数据
    GLuint textureCoordsSlot = glGetAttribLocation(program, "i_textureCoord");
    glEnableVertexAttribArray(textureCoordsSlot);
    glVertexAttribPointer(textureCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, textureCoord));
        
    GLuint sampler = glGetUniformLocation(_program, "u_sampler");
    glUniform1i(sampler, 0);
    
    GLuint aspectRatio = glGetUniformLocation(_program, "u_aspectRatio");
    glUniform1f(aspectRatio, self.aspectRatio);
    
    self.uResolution = glGetUniformLocation(program, "u_resolution"); 
    glUniform2f(self.uResolution, CGRectGetWidth(self.frame)*[[UIScreen mainScreen] scale], CGRectGetHeight(self.frame)*[[UIScreen mainScreen] scale]);

//    self.uTime = glGetUniformLocation(program, "u_time"); 
    
    // 读取纹理
    NSString *imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"sample.jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    GLuint textureID = [self createTextureWithImage:image];
    
    // 将纹理 ID 传给着色器程序
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glUniform1i(textureSlot, 0);  // 将 textureSlot 赋值为 0，而 0 与 GL_TEXTURE0 对应，这里如果写 1，上面也要改成 GL_TEXTURE1
    
//    glUniform1f(self.uTime, 0.);
        
    
//    // 开始绘制
//    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
//    
//    // 将绑定的渲染缓存呈现到屏幕上
//    [self.context presentRenderbuffer:GL_RENDERBUFFER];
    
//    // 删除顶点缓存
//    glDeleteBuffers(1, &vertexBuffer);
//    vertexBuffer = 0;
}


// 通过一张图片来创建纹理
- (GLuint)createTextureWithImage:(UIImage *)image {
    // 将 UIImage 转换为 CGImageRef
    CGImageRef cgImageRef = [image CGImage];
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
    CGRect rect = CGRectMake(0, 0, width, height);
    
    // 绘制图片
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc(width * height * 4);
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, cgImageRef);

    // 生成纹理
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData); // 将图片数据写入纹理缓存
    
    // 设置如何把纹素映射成像素
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    // 解绑
    glBindTexture(GL_TEXTURE_2D, 0);
    
    // 释放内存
    CGContextRelease(context);
    free(imageData);
    
    return textureID;
}

// 绑定图像要输出的 layer
- (void)bindRenderLayer:(CALayer <EAGLDrawable> *)layer {
    
    glDeleteBuffers(1, &_renderBuffer);// 渲染缓存
    glDeleteBuffers(1, &_frameBuffer);// 帧缓存
        
    // 绑定渲染缓存要输出的 layer
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    
    // 将渲染缓存绑定到帧缓存上
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,
                              GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER,
                              _renderBuffer);
}

// 将一个顶点着色器和一个片段着色器挂载到一个着色器程序上，并返回程序的 id
- (GLuint)programWithShaderName:(NSString *)shaderName {
    // 编译两个着色器
    GLuint vertexShader = [self compileShaderWithName:shaderName type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShaderWithName:shaderName type:GL_FRAGMENT_SHADER];
    
    // 挂载 shader 到 program 上
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    // 链接 program
    glLinkProgram(program);
    
    // 检查链接是否成功
    GLint linkSuccess;
    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"program链接失败：%@", messageString);
        exit(1);
    }
    
    
    return program;
}

// 编译一个 shader，并返回 shader 的 id
- (GLuint)compileShaderWithName:(NSString *)name type:(GLenum)shaderType {
    // 查找 shader 文件
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:name ofType:shaderType == GL_VERTEX_SHADER ? @"vsh" : @"fsh"]; // 根据不同的类型确定后缀名
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSAssert(NO, @"读取shader失败");
        exit(1);
    }
    
    // 创建一个 shader 对象
    GLuint shader = glCreateShader(shaderType);
    
    // 获取 shader 的内容
    const char *shaderStringUTF8 = [shaderString UTF8String];
//    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shader, 1, &shaderStringUTF8, NULL);
    
    // 编译shader
    glCompileShader(shader);
    
    // 查询 shader 是否编译成功
    GLint compileSuccess;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shader, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"shader编译失败：%@", messageString);
        exit(1);
    }
    
    return shader;
}

// 获取渲染缓存宽度
- (GLint)drawableWidth {
    GLint backingWidth;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    
    return backingWidth;
}

// 获取渲染缓存高度
- (GLint)drawableHeight {
    GLint backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    return backingHeight;
}

#pragma makr - timer
- (void)startDisplayLinkIfNeeded {
    if (!self.displayLink)
    {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(once:)];
        NSAssert([NSThread isMainThread], @"");
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)once:(CADisplayLink *)displayLink {
    if (self.startTime <= 0) {
        self.startTime = self.displayLink.timestamp;
    }
    
    CGFloat currentTime = self.displayLink.timestamp - self.startTime;
    GLuint time = glGetUniformLocation(_program, "u_time");
    glUniform1f(time, currentTime);
    
    glClear(GL_COLOR_BUFFER_BIT);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)endDisplay {
    self.displayLink.paused = YES;
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)freeMemory {
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    if (_renderBuffer) {
        glDeleteBuffers(1, &_renderBuffer);
    }
    if (_frameBuffer) {
        glDeleteBuffers(1, &_frameBuffer);
    }
    if (_vertexBuffer) {
        glDeleteBuffers(1, &_vertexBuffer);
    }
}

@end
