//
//  viewNoise.m
//  xRayda
//
//  Created by apple on 2022/1/16.
//  Copyright © 2022 apple.gupt.www. All rights reserved.
//

#import "viewNoiseGateDot.h"
@implementation viewNoiseGateDot

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawText:context];
}

-(void) drawText:(CGContextRef) context{
  
    NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];
    pStyle.alignment = NSTextAlignmentRight;
    
    UIColor *textColor;
    if (self.colorNumber == 0) {
        textColor = [UIColor redColor];
    }else{
        textColor = [UIColor blackColor];
    }
    NSDictionary *attrDict = @{NSFontAttributeName:[UIFont fontWithName:@"Arial" size:10],NSForegroundColorAttributeName:textColor,NSParagraphStyleAttributeName:pStyle};
    CGFloat vWidth = (self.frame.size.width)/8;

    for(int i=0;i<16;i++){
        for(int j=0;j<8;j++){
            [self.dataStr[i*8+j] drawInRect:CGRectMake((vWidth-2)*j, 10+20*i, vWidth-3, 20) withAttributes:attrDict];
        }
    }
}

@end
