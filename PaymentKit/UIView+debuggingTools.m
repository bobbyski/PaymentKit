//
//  UIView+debuggingTools.m
//  PaymentKit Example
//
//  Created by Bobby Skinner on 8/3/15.
//  Copyright (c) 2015 Stripe. All rights reserved.
//

#import "UIView+debuggingTools.h"

@implementation UIView (debuggingTools)

- (NSString*)viewStructure
{
    return [self viewStructureWithPrefix: @"  " andSeperator: @"\n"];
}

- (NSString*)viewStructureWithPrefix:(NSString*)prefix andSeperator:(NSString*)seperator
{
    NSMutableString* result = [NSMutableString string];
    NSString* className = [NSString stringWithFormat: @"%@", [self class]];
    
    if ( ![className isEqualToString: @"UIFieldEditor"] )
    {
        [result appendFormat: @"%@%@ %@", prefix, className, NSStringFromCGRect( [self frame])];
        
        // get text here?
        
        if ( seperator )
            [result appendString: seperator];
        
        for( UIView* sv in self.subviews )
        {
            [result appendString: [sv viewStructureWithPrefix: [NSString stringWithFormat: @"%@  ", prefix]
                                                 andSeperator: seperator]];
            
        }
    }
    
    return result;
}

@end
