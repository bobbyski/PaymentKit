//
//  PTKPaymentField.h
//  PTKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PTKCard.h"
#import "PTKCardNumber.h"
#import "PTKCardExpiry.h"
#import "PTKCardCVC.h"
#import "PTKAddressZip.h"
#import "PTKUSAddressZip.h"

@class PTKView, PTKTextField;

@protocol PTKViewDelegate <NSObject>
@optional
- (void)paymentView:(PTKView *)paymentView withCard:(PTKCard *)card isValid:(BOOL)valid;
@end

IB_DESIGNABLE
@interface PTKView : UIView

- (BOOL)isValid;

@property (nonatomic, readonly) UIView *opaqueOverGradientView;
@property (nonatomic, readonly) PTKCardNumber *cardNumber;
@property (nonatomic, readonly) PTKCardExpiry *cardExpiry;
@property (nonatomic, readonly) PTKCardCVC *cardCVC;
@property (nonatomic, readonly) PTKAddressZip *addressZip;
@property (nonatomic, assign) IBInspectable UIEdgeInsets edgeInsets;
@property (nonatomic, strong) IBInspectable UIFont* font;
@property (nonatomic, strong) IBInspectable NSString* fontName;
@property (nonatomic, assign) IBInspectable CGFloat fontSize;
@property (nonatomic, strong) IBInspectable UIImage* backgroundImage;
@property (nonatomic, assign) IBInspectable CGFloat cardWidth;
@property (nonatomic, assign) IBInspectable CGFloat expiryWidth;
@property (nonatomic, assign) IBInspectable CGFloat cvcWidth;
@property (nonatomic, assign) IBInspectable CGFloat zipWidth;
@property (nonatomic, assign) IBInspectable CGFloat spacing;
@property (nonatomic, assign) IBInspectable CGFloat placeHolderSpacing;
@property (nonatomic, strong) IBInspectable UIColor* textColor;
@property (nonatomic, strong) IBInspectable UIColor* placeholderColor;
@property (nonatomic, strong) IBInspectable UIColor* goodColor;
@property (nonatomic, strong) IBInspectable UIColor* badColor;

@property (nonatomic, weak) IBOutlet id <PTKViewDelegate> delegate;
@property (nonatomic, strong) PTKCard *card;

#pragma mark - protected methods -
- (void) resizeView;


@end
