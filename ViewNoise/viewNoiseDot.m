//
//  viewNoise.m
//  xRayda
//
//  Created by apple on 2022/1/16.
//  Copyright © 2022 apple.gupt.www. All rights reserved.
//

#import "viewNoiseDot.h"
@implementation viewNoiseDot

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
    pStyle.alignment = NSTextAlignmentCenter;
    
    UIColor *textColor;
    if (self.colorNumber == 0) {
        textColor = [UIColor redColor];
    }else{
        textColor = [UIColor blackColor];
    }
    NSDictionary *attrDict = @{NSFontAttributeName:[UIFont fontWithName:@"Arial" size:10],NSForegroundColorAttributeName:textColor,NSParagraphStyleAttributeName:pStyle};
    CGFloat vWidth = (self.frame.size.width)/3;
   /*
    for(int i=0;i<16;i++){
        for(int j=0;j<8;j++){
            [self.dataStr[i*8+j] drawInRect:CGRectMake((vWidth-2)*j, 10+20*i, vWidth-3, 20) withAttributes:attrDict];
        }
    }
    */
    for(int i=0;i<63;i++){
        for(int j=0;j<3;j++){
            [self.dataStr[i*3+j] drawInRect:CGRectMake((vWidth-2)*j, 10+20*i, vWidth-3, 20) withAttributes:attrDict];
            continue;
        }
    }
    
    
}

@end
