//
//  JKLLockScreenPincodeView.m
//

#import "JKLLockScreenPincodeView.h"

static const NSUInteger LSPMaxPincodeLength = 4;

@interface JKLLockScreenPincodeView() {
    NSUInteger _wasCompleted;
}

@property (nonatomic, strong) NSString * pincode;

@end

@implementation JKLLockScreenPincodeView

- (instancetype)init {
    if (self = [super init]) {
        [self lsp_initialize];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self lsp_initialize];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self lsp_initialize];
    }
    
    return self;
}

- (void)lsp_initialize {
    
    self.enabled = YES;
    [self initPincode];
}

- (void)initPincode {
    self.pincode = @"";
}

- (void)setPincode:(NSString *)pincode {
    
    if (_pincode != pincode) {
        _pincode = pincode;
        
        [self setNeedsDisplay];
        
        BOOL length = ([pincode length] == LSPMaxPincodeLength);
        if (length && [_delegate respondsToSelector:@selector(lockScreenPincodeView:pincode:)]) {
            [_delegate lockScreenPincodeView:self pincode:pincode];
        }
    }
}


- (void)appendingPincode:(NSString *)pincode {

    if (!_enabled) return;

    NSString * appended = [_pincode stringByAppendingString:pincode];


    NSUInteger length = MIN([appended length], LSPMaxPincodeLength);
    self.pincode = [appended substringToIndex:length];
}


- (void)removeLastPincode {
    
    if (!_enabled) return;
    
    NSUInteger index = ([_pincode length] - 1);
    if ([_pincode length] > index) {
        self.pincode = [_pincode substringToIndex:index];
    }
}

- (void)wasCompleted {
    for (NSUInteger idx = 0; idx < LSPMaxPincodeLength; idx++) {
        dispatch_time_t delayInSeconds = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(idx * 0.01f * NSEC_PER_SEC));
        dispatch_after(delayInSeconds, dispatch_get_main_queue(), ^(void){
            
            _wasCompleted++;
            [self setNeedsDisplay];
        });
    }
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
    [super drawRect:rect];
    
    [_pincodeColor setFill];
    
    // 1 character box size
    CGSize boxSize  = CGSizeMake(CGRectGetWidth(rect) / LSPMaxPincodeLength, CGRectGetHeight(rect));
    CGSize charSize = CGSizeMake(13, 13);
    
    CGFloat y = rect.origin.y;
    
    NSUInteger completed = MAX([_pincode length], _wasCompleted);
    
    // draw a circle : '.'
    NSInteger str = MIN(completed, LSPMaxPincodeLength);
    for (NSUInteger idx = 0; idx < str; idx++) {
        CGFloat x = boxSize.width * idx;
        CGRect rounded = CGRectMake(x + floorf((boxSize.width  - charSize.width) / 2),
                                    y + floorf((boxSize.height - charSize.width) / 2),
                                    charSize.width,
                                    charSize.height);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, _pincodeColor.CGColor);
        CGContextSetLineWidth(context, 1.0);
        CGContextFillEllipseInRect(context, rounded);
        CGContextFillPath(context);
    }
    
    // draw a dash : '-'
    for (NSUInteger idx = str; idx < LSPMaxPincodeLength; idx++) {
        CGFloat x = boxSize.width * idx;
        CGRect rounded = CGRectMake(x + floorf((boxSize.width  - charSize.width)  / 2),
                                    y + floorf((boxSize.height - charSize.height) / 2),
                                    charSize.width,
                                    charSize.height);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetStrokeColorWithColor(context, _pincodeColor.CGColor);
        CGContextSetLineWidth(context, 1.0);
        CGContextAddEllipseInRect(context, rounded);
        CGContextStrokePath(context);
    }
}

@end
