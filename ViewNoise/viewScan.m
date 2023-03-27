//
//  viewScan.m
//  xRayda
//
//  Created by apple on 2022/2/10.
//  Copyright © 2022 apple.gupt.www. All rights reserved.
//

#import "viewScan.h"

@implementation viewScan

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.

- (void)drawRect:(CGRect)rect
{
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    //Y轴
    CGContextMoveToPoint(ctx, rect.origin.x+30, rect.origin.y+10);
    CGContextAddLineToPoint(ctx, rect.origin.x+30,rect.origin.y+ rect.size.height-30);
    //x轴
    CGContextMoveToPoint(ctx, rect.origin.x+30, rect.origin.y+rect.size.height-30);
    CGContextAddLineToPoint(ctx, rect.origin.x+rect.size.width-10,rect.origin.y+ rect.size.height-30);
    CGContextStrokePath(ctx);
    
    
    //绘制水平虚线
    for(int j=0;j<8;j++){
        CGContextBeginPath(ctx);
        CGContextSetLineWidth(ctx, 2.0);
        CGContextSetStrokeColorWithColor(ctx, [UIColor grayColor].CGColor);
        
        CGFloat lengths[] = {3,2};
        CGContextSetLineDash(ctx,0,lengths,2);
        CGContextMoveToPoint(ctx, rect.origin.x+30, rect.origin.y+10+(rect.size.height-40)/8.0*j);
        CGContextAddLineToPoint(ctx, rect.origin.x+rect.size.width-10,rect.origin.y+10+(rect.size.height-40)/8.0*j);
        CGContextStrokePath(ctx);
    }
    
    //绘制垂直虚线
    for(int i=1;i<7;i++){
        CGContextBeginPath(ctx);
        CGContextSetLineWidth(ctx, 2.0);
        CGContextSetStrokeColorWithColor(ctx, [UIColor grayColor].CGColor);
        
        CGFloat lengths[] = {3,2};
        CGContextSetLineDash(ctx,0,lengths,2);
        CGContextMoveToPoint(ctx, rect.origin.x+30+(rect.size.width-40)/6.0*i, rect.origin.y+10);
        CGContextAddLineToPoint(ctx, rect.origin.x+30+(rect.size.width-40)/6.0*i,rect.origin.y+ rect.size.height-30);
        CGContextStrokePath(ctx);
    }
    
    //绘制横坐标
    NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];
    pStyle.alignment = NSTextAlignmentCenter;
    
    UIColor *textColor = [UIColor blackColor];
    NSDictionary *attrDict = @{NSFontAttributeName:[UIFont fontWithName:@"Arial" size:10],NSForegroundColorAttributeName:textColor,NSParagraphStyleAttributeName:pStyle};
    CGFloat vWidth = (self.frame.size.width)/18;
    
    NSArray *dataX = [NSArray arrayWithObjects:@"-3", @"-2",@"-1",@"0",@"1",@"2",@"3",nil];
    for(int i=0;i<dataX.count;i++){
        [dataX[i] drawInRect:CGRectMake(20+(rect.size.width-40)/6.0*i, rect.origin.y+ rect.size.height-20, vWidth, 10) withAttributes:attrDict];
    }
    
    //绘制纵坐标
    CGFloat vHeight = (self.frame.size.height)/18;
    NSArray *dataY = [NSArray arrayWithObjects:@"10.0",@"8.75", @"7.50",@"6.25",@"5.00",@"3.75",@"2.50",@"1.25",nil];
    for(int j=0;j< dataY.count;j++){
        [dataY[j] drawInRect:CGRectMake(rect.origin.x+3, rect.origin.y+5+ (rect.size.height-40)/8.0*j,25,vHeight) withAttributes:attrDict];
    }
    
    
    //显示目标字符串
    if(![self.dataStr isEqual: @""]){
        textColor = [UIColor colorWithRed:0 green:0 blue:1.0 alpha:0.8];
        pStyle.alignment = NSTextAlignmentLeft;
        attrDict = @{NSFontAttributeName:[UIFont fontWithName:@"Arial" size:15],NSForegroundColorAttributeName:textColor,NSParagraphStyleAttributeName:pStyle};
        
        NSArray *strs = [self.dataStr componentsSeparatedByString:@","];
        
        int kTargets = 0;  //目标个数
        if(strs.count>0){
            kTargets = [[strs[0] substringFromIndex:7] intValue];
            //考虑到接收数据不完整
            if(strs.count < 3*kTargets +1){
                kTargets = (int)(strs.count -1)/3;
            }
        }
        self.data = [[NSMutableArray alloc] init];
        
        for(int i=0;i<kTargets;i++){
            NSString *strSeq = [NSString stringWithFormat:@"Target[%d]:",i];
            [strSeq drawInRect:CGRectMake(rect.origin.x+40, rect.origin.y+10+i*20,100,20) withAttributes:attrDict];
            
            [strs[3*i+1] drawInRect:CGRectMake(rect.origin.x+40+70, rect.origin.y+10+i*20,100,20) withAttributes:attrDict];
            [self.data addObject:[strs[3*i+1] substringFromIndex:3]];
            
            [strs[3*i+2] drawInRect:CGRectMake(rect.origin.x+40+140, rect.origin.y+10+i*20,100,20) withAttributes:attrDict];
            [self.data addObject:[strs[3*i+2] substringFromIndex:3]];
            
            [strs[3*i+3] drawInRect:CGRectMake(rect.origin.x+40+210, rect.origin.y+10+i*20,100,20) withAttributes:attrDict];
            [self.data addObject:[strs[3*i+3] substringFromIndex:4]];
        }
        
        //绘制目标
        textColor = [UIColor redColor];
        pStyle.alignment = NSTextAlignmentCenter;
        attrDict = @{NSFontAttributeName:[UIFont fontWithName:@"Arial" size:30],NSForegroundColorAttributeName:textColor,NSParagraphStyleAttributeName:pStyle};
        NSString *plus = @"+";
        
        for(int k=0;k<self.data.count/3;k++){
            float x = rect.origin.x + 30 + (rect.size.width-30)/6.0*3 + [self.data[3*k] floatValue]*(rect.size.width-40)/6.0-20;
            float y = rect.origin.y + rect.size.height - 30 - [self.data[3*k+1] floatValue]/1.25*(rect.size.height-30)/8.0-20;
            [plus drawInRect:CGRectMake(x, y,30,30) withAttributes:attrDict];
        }
    }
}
@end

