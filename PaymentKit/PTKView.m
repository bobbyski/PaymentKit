//
//  PTKPaymentField.m
//  PTKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PTKView.h"
#import "PTKTextField.h"
//#import "UIView+debuggingTools.h"

#define RGB(r,g,b) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0f]
#define DarkGreyColor RGB(0,0,0)
#define RedColor RGB(253,0,17)
#define DefaultBoldFont [UIFont boldSystemFontOfSize:17]

#define kPTKStateCardNumber             0
#define kPTKStateCardExpiry             1
#define kPTKStateCardCVC                2
#define kPTKStateCardZip                3
#define kPTKViewPlaceholderViewAnimationDuration 0.25

static NSString *const kPTKLocalizedStringsTableName = @"PaymentKit";
static NSString *const kPTKOldLocalizedStringsTableName = @"STPaymentLocalizable";

@interface PTKView () <PTKTextFieldDelegate> {
@private
    BOOL _isInitialState;
    BOOL _isValidState;
    NSInteger _state;
}

@property IBOutlet UIView *innerView;
@property IBOutlet UIView *clipView;
@property IBOutlet PTKTextField *cardNumberField;
@property IBOutlet PTKTextField *cardExpiryField;
@property IBOutlet PTKTextField *cardCVCField;
@property IBOutlet UIImageView *placeholderView;

@property (nonatomic, readonly, assign) UIResponder *firstResponderField;
@property (nonatomic, readonly, assign) PTKTextField *firstInvalidField;
@property (nonatomic, readonly, assign) PTKTextField *nextFirstResponder;

@property (nonatomic) PTKCardNumber *cardNumber;
@property (nonatomic) PTKCardExpiry *cardExpiry;
@property (nonatomic) PTKCardCVC *cardCVC;
@property (nonatomic) PTKAddressZip *addressZip;

- (void)setup;
- (void)setupPlaceholderView;
- (void)setupCardNumberField;
- (void)setupCardExpiryField;
- (void)setupCardCVCField;

- (void)pkTextFieldDidBackSpaceWhileTextIsEmpty:(PTKTextField *)textField;

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardNumberFieldShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardExpiryShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardCVCShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;

@end

#pragma mark -

@implementation PTKView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
    _isInitialState = YES;
    _isValidState = NO;
    _state = kPTKStateCardNumber;
    
    if ( !self.font )
    {
        if ( [self.fontName length] && ( self.fontSize > 0.0 ) )
            self.font = [UIFont fontWithName: self.fontName size: self.fontSize];
    }
    
    if ( !self.font )
        self.font = DefaultBoldFont;
    
    if ( self.cardWidth <= 0.0 )
    {
        CGSize size = [@"9999 9999 9999 9999" sizeWithAttributes: @{NSFontAttributeName: self.font}];
        self.cardWidth = size.width;
    }
    
    if ( self.expiryWidth <= 0.0 )
    {
        CGSize size = [@"MM/YY" sizeWithAttributes: @{NSFontAttributeName: self.font}];
        self.expiryWidth = size.width;
    }
    
    if ( self.cvcWidth <= 0.0 )
    {
        CGSize size = [@"CVC9" sizeWithAttributes: @{NSFontAttributeName: self.font}];
        self.cvcWidth = size.width;
    }
    
    if ( self.zipWidth <= 0.0 )
        self.zipWidth = 70.0;
    
    if ( self.spacing <= 0.0 )
        self.spacing = 10.0;
    
    if ( self.placeHolderSpacing <= 0.0 )
        self.placeHolderSpacing = 5.0;
    
    if ( !self.textColor )
        self.textColor = [UIColor blackColor];
    
    if ( !self.placeholderColor )
        self.placeholderColor = DarkGreyColor;
    
    if ( !self.badColor )
        self.badColor = RedColor;
    
    if ( !self.goodColor )
        self.goodColor = self.textColor;

    if ( self.backgroundImage )
    {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, 290, 46);
        self.backgroundColor = [UIColor clearColor];

        if ( self.backgroundImage )
        {
            UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
            backgroundImageView.image = self.backgroundImage; // [[UIImage imageNamed:@"textfield"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 8, 0, 8)];
            [self addSubview:backgroundImageView];
        }
    }
    
    self.clipView = [[UIView alloc] initWithFrame: UIEdgeInsetsInsetRect( [self bounds], [self edgeInsets])];
    [self.clipView setClipsToBounds: YES];
    [self.clipView setAutoresizingMask: UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [self.clipView setBackgroundColor: [UIColor clearColor]];
    [self addSubview: self.clipView];

    self.innerView = [[UIView alloc] initWithFrame:CGRectMake(40, 12, self.frame.size.width - 40, self.frame.size.height - 24.0)];
    [self.innerView setBackgroundColor: [UIColor clearColor]];
    self.innerView.clipsToBounds = YES;
    
    [self resizeView];

    [self setupPlaceholderView];
    [self setupCardNumberField];
    [self setupCardExpiryField];
    [self setupCardCVCField];

    [self.innerView addSubview:self.cardNumberField];

    [self.clipView addSubview: self.innerView];
    [self addSubview: self.placeholderView];

    [self stateCardNumber];
    
    //[self setupFrameDebug];
}


- (void)setupPlaceholderView
{
    self.placeholderView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 13, 32, 20)];
    self.placeholderView.backgroundColor = [UIColor clearColor];
    self.placeholderView.image = [UIImage imageNamed:@"placeholder"];
}

- (void) setFrameForSize:(CGFloat)width offset:(CGFloat)offset forField:(PTKTextField*)textField
{
    CGRect iFrame = self.innerView.bounds;
    CGFloat hoffset = /* self.placeholderView.frame.size.width + */ offset;
    
    iFrame = CGRectMake( hoffset, 0, width,  self.clipView.bounds.size.height );
    
    [textField setFrame: iFrame];
}

- (void)setupCardNumberField
{
    CGRect iFrame = self.innerView.bounds;
    CGFloat hoffset = self.placeholderView.frame.size.width + 2.0;
    
    iFrame = CGRectMake( hoffset, 0, self.cardWidth,  self.bounds.size.height );
    self.cardNumberField = [[PTKTextField alloc] initWithFrame: iFrame];
    self.cardNumberField.delegate = self;
    self.cardNumberField.placeholder = [self.class localizedStringWithKey:@"placeholder.card_number" defaultValue:@"1234 5678 9012 3456"];
    self.cardNumberField.keyboardType = UIKeyboardTypeNumberPad;
    self.cardNumberField.textColor = self.placeholderColor;
    self.cardNumberField.font = self.font;

    [self.cardNumberField.layer setMasksToBounds:YES];
}

- (void)setupCardExpiryField
{
    CGRect iFrame = self.innerView.bounds;
    CGFloat hoffset = self.cardNumberField.frame.origin.x + self.cardNumberField.frame.size.width + self.spacing;
    
    iFrame = CGRectMake( hoffset, 0, self.expiryWidth,  self.bounds.size.height );
    self.cardExpiryField = [[PTKTextField alloc] initWithFrame: iFrame];
    self.cardExpiryField.delegate = self;
    self.cardExpiryField.placeholder = [self.class localizedStringWithKey:@"placeholder.card_expiry" defaultValue:@"MM/YY"];
    self.cardExpiryField.keyboardType = UIKeyboardTypeNumberPad;
    self.cardExpiryField.textColor = self.placeholderColor;
    self.cardExpiryField.font = self.font;

    [self.cardExpiryField.layer setMasksToBounds:YES];
}

- (void)setupCardCVCField
{
    CGRect iFrame = self.innerView.bounds;
    CGFloat hoffset = self.cardExpiryField.frame.origin.x + self.cardExpiryField.frame.size.width + self.spacing;
    
    iFrame = CGRectMake( hoffset, 0, self.cvcWidth,  self.bounds.size.height );
    self.cardCVCField = [[PTKTextField alloc] initWithFrame: iFrame];
    self.cardCVCField.delegate = self;
    self.cardCVCField.placeholder = [self.class localizedStringWithKey:@"placeholder.card_cvc" defaultValue:@"CVC"];
    self.cardCVCField.keyboardType = UIKeyboardTypeNumberPad;
    self.cardCVCField.textColor = self.placeholderColor;
    self.cardCVCField.font = self.font;

    [self.cardCVCField.layer setMasksToBounds:YES];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    [self resizeView];
}

- (void) setupFrameDebug
{
    [[self layer] setBorderWidth: 0.5];
    [[self layer] setBorderColor: [UIColor blueColor].CGColor];
    [[[self innerView] layer] setBorderWidth: 0.5];
    [[[self innerView] layer] setBorderColor: [UIColor magentaColor].CGColor];
    [[[self clipView] layer] setBorderWidth: 0.5];
    [[[self clipView] layer] setBorderColor: [UIColor yellowColor].CGColor];
    [[[self placeholderView] layer] setBorderWidth: 0.5];
    [[[self placeholderView] layer] setBorderColor: [UIColor greenColor].CGColor];
}

- (void) resizeView
{
    CGFloat contentWidth = /* self.placeholderView.frame.size.width
                        + self.placeHolderSpacing */
                        + self.cardNumberField.frame.size.width
                        + self.cardExpiryField.frame.size.width
                        + self.cardCVCField.frame.size.width
                        + ( self.spacing * 2 );
    
    CGRect iframe = [self bounds];
    CGRect placeHolderFrame = [[self placeholderView] frame];
    CGFloat heightPadding = ( iframe.size.height - placeHolderFrame.size.height ) / 2.0;
    
    CGRect clipFrame = UIEdgeInsetsInsetRect( [self bounds], [self edgeInsets]);
    clipFrame.size.width -= ( self.placeholderView.frame.size.width + self.placeHolderSpacing);
    clipFrame.origin.x += ( self.placeholderView.frame.size.width + self.placeHolderSpacing );
    
    CGFloat windowWidth = clipFrame.size.width;
    [self.clipView setFrame: clipFrame];
    
    CGFloat innerX = 0.0; //self.edgeInsets.left + placeHolderFrame.size.width;
    if ( contentWidth > windowWidth )
    {
        if ( _state != kPTKStateCardNumber )
            innerX = innerX - ( contentWidth - windowWidth );
    }
    
    //iframe = CGRectMake( innerX, iframe.origin.y, contentWidth, iframe.size.height);
    iframe = CGRectMake( innerX, 0, contentWidth, clipFrame.size.height);
    
//    NSLog( @"innerView before: %@ changing to %@", NSStringFromCGRect( [[self innerView] frame] ),
//          NSStringFromCGRect( iframe ) );
    
    [self.innerView setFrame: iframe];
    
    iframe = CGRectMake( self.edgeInsets.left + 2.0,
                         /* iframe.origin.y + self.edgeInsets.top +*/ heightPadding,
                         placeHolderFrame.size.width,
                         placeHolderFrame.size.height );
    
    [self.placeholderView setFrame: iframe];
    
    [self setFrameForSize: self.cardWidth offset: 5.0 forField: self.cardNumberField];
    
    [self setFrameForSize: self.expiryWidth
                   offset: self.cardNumberField.frame.origin.x + self.cardNumberField.frame.size.width + self.spacing
                 forField: self.cardExpiryField];
    
    [self setFrameForSize: self.cvcWidth
                   offset: self.cardExpiryField.frame.origin.x + self.cardExpiryField.frame.size.width + self.spacing
                 forField: self.cardCVCField];
    
//    NSLog( @"State: %d, x: %f", (int) _state, innerX );
//    NSLog( @"resizeView View layout:\n%@", [self viewStructure] );
}

// Checks both the old and new localization table (we switched in 3/14 to PaymentKit.strings).
// Leave this in for a long while to preserve compatibility.
+ (NSString *)localizedStringWithKey:(NSString *)key defaultValue:(NSString *)defaultValue
{
    NSString *value = NSLocalizedStringFromTable(key, kPTKLocalizedStringsTableName, nil);
    if (value && ![value isEqualToString:key]) { // key == no value
        return value;
    } else {
        value = NSLocalizedStringFromTable(key, kPTKOldLocalizedStringsTableName, nil);
        if (value && ![value isEqualToString:key]) {
            return value;
        }
    }

    return defaultValue;
}

#pragma mark - Accessors

- (PTKCardNumber *)cardNumber
{
    return [PTKCardNumber cardNumberWithString:self.cardNumberField.text];
}

- (PTKCardExpiry *)cardExpiry
{
    return [PTKCardExpiry cardExpiryWithString:self.cardExpiryField.text];
}

- (PTKCardCVC *)cardCVC
{
    return [PTKCardCVC cardCVCWithString:self.cardCVCField.text];
}

#pragma mark - State

- (void)stateCardNumber
{
    _state = kPTKStateCardNumber;
    
    if (!_isInitialState)
    {
        // Animate left
        _isInitialState = YES;
        
        //CGRect pframe = [self.placeholderView frame];

//        [UIView animateWithDuration:0.05 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
//                         animations:^{
//                             self.opaqueOverGradientView.alpha = 0.0;
//                         }
//                         completion:^(BOOL finished)
//        {
//        }];
        
        [UIView animateWithDuration:0.400
                              delay:0
                            options:(UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction)
                         animations:^
                                {
                                     [self resizeView];
                                 }
                         completion:^(BOOL completed)
                                 {
                                     [self.cardExpiryField removeFromSuperview];
                                     [self.cardCVCField removeFromSuperview];
                                 }];
        
        [self.cardNumberField becomeFirstResponder];
    }
}

- (void)stateMeta
{
    _state = kPTKStateCardExpiry;
    _isInitialState = NO;

    CGSize cardNumberSize;
    CGSize lastGroupSize;

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
    if ([self.cardNumber.formattedString respondsToSelector:@selector(sizeWithAttributes:)]) {
        NSDictionary *attributes = @{NSFontAttributeName: self.font};

        cardNumberSize = [self.cardNumber.formattedString sizeWithAttributes:attributes];
        lastGroupSize = [self.cardNumber.lastGroup sizeWithAttributes:attributes];
    } else {
        cardNumberSize = [self.cardNumber.formattedString sizeWithFont:self.font];
        lastGroupSize = [self.cardNumber.lastGroup sizeWithFont:self.font];
    }
#else
    NSDictionary *attributes = @{NSFontAttributeName: self.font};

    cardNumberSize = [self.cardNumber.formattedString sizeWithAttributes:attributes];
    lastGroupSize = [self.cardNumber.lastGroup sizeWithAttributes:attributes];
#endif
    
    [UIView animateWithDuration:0.400 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^
                            {
                                [self resizeView];
                            }
                     completion: nil];
    
    self.cardExpiryField.frame = CGRectMake(self.cardNumberField.frame.origin.x + self.cardNumberField.frame.size.width + self.spacing,
                                            self.cardExpiryField.frame.origin.y,
                                            self.cardExpiryField.frame.size.width,
                                            self.cardExpiryField.frame.size.height);
    
    self.cardCVCField.frame = CGRectMake(self.cardExpiryField.frame.origin.x + self.cardExpiryField.frame.size.width + self.spacing,
                                         self.cardCVCField.frame.origin.y,
                                         self.cardCVCField.frame.size.width,
                                         self.cardCVCField.frame.size.height);

    [self addSubview: self.placeholderView];
    [self.innerView addSubview:self.cardExpiryField];
    [self.innerView addSubview:self.cardCVCField];
    [self.cardExpiryField becomeFirstResponder];
}

- (void)stateCardCVC
{
    _state = kPTKStateCardCVC;
    [self.cardCVCField becomeFirstResponder];
}

- (BOOL)isValid
{
    return [self.cardNumber isValid] && [self.cardExpiry isValid] &&
            [self.cardCVC isValidWithType:self.cardNumber.cardType];
}

- (PTKCard *)card
{
    PTKCard *card = [[PTKCard alloc] init];
    card.number = [self.cardNumber string];
    card.cvc = [self.cardCVC string];
    card.expMonth = [self.cardExpiry month];
    card.expYear = [self.cardExpiry year];
    card.type = [self cardTupe];

    return card;
}

- (void)setPlaceholderViewImage:(UIImage *)image
{
    if (![self.placeholderView.image isEqual:image])
    {
        __weak UIView *previousPlaceholderView = self.placeholderView;
        
        [UIView animateWithDuration:kPTKViewPlaceholderViewAnimationDuration delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
                                 {
                                     self.placeholderView.layer.opacity = 0.0;
                                     self.placeholderView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1.2);
                                 }
                         completion:^(BOOL finished)
                                {
                                    [previousPlaceholderView removeFromSuperview];
                                }];
        
        self.placeholderView = nil;

        [self setupPlaceholderView];
        self.placeholderView.image = image;
        self.placeholderView.layer.opacity = 0.0;
        self.placeholderView.layer.transform = CATransform3DMakeScale(0.8, 0.8, 0.8);
        [self insertSubview: self.placeholderView belowSubview: previousPlaceholderView];
        
        [UIView animateWithDuration:kPTKViewPlaceholderViewAnimationDuration delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^
                                 {
                                     self.placeholderView.layer.opacity = 1.0;
                                     self.placeholderView.layer.transform = CATransform3DIdentity;
                                 }
                         completion:^(BOOL finished)
                                {
                                    //NSLog( @"New graphic at %@", NSStringFromCGRect( [me.placeholderView frame]) );
                                }];
    }
}

- (void)setPlaceholderToCVC
{
    PTKCardNumber *cardNumber = [PTKCardNumber cardNumberWithString:self.cardNumberField.text];
    PTKCardType cardType = [cardNumber cardType];

    if (cardType == PTKCardTypeAmex) {
        [self setPlaceholderViewImage:[UIImage imageNamed:@"cvc-amex"]];
    } else {
        [self setPlaceholderViewImage:[UIImage imageNamed:@"cvc"]];
    }
}

- (void)setPlaceholderToCardType
{
    PTKCardNumber *cardNumber = [PTKCardNumber cardNumberWithString:self.cardNumberField.text];
    PTKCardType cardType = [cardNumber cardType];
    NSString *cardTypeName = @"placeholder";

    switch (cardType) {
        case PTKCardTypeAmex:
            cardTypeName = @"amex";
            break;
        case PTKCardTypeDinersClub:
            cardTypeName = @"diners";
            break;
        case PTKCardTypeDiscover:
            cardTypeName = @"discover";
            break;
        case PTKCardTypeJCB:
            cardTypeName = @"jcb";
            break;
        case PTKCardTypeMasterCard:
            cardTypeName = @"mastercard";
            break;
        case PTKCardTypeVisa:
            cardTypeName = @"visa";
            break;
        default:
            break;
    }

    [self setPlaceholderViewImage:[UIImage imageNamed:cardTypeName]];
}

- (NSString*)cardTupe
{
    PTKCardNumber *cardNumber = [PTKCardNumber cardNumberWithString:self.cardNumberField.text];
    PTKCardType cardType = [cardNumber cardType];
    NSString *cardTypeName = @"unknown";
    
    switch (cardType)
    {
        case PTKCardTypeAmex:
            cardTypeName = @"American Express";
            break;
        case PTKCardTypeDinersClub:
            cardTypeName = @"Diners Club";
            break;
        case PTKCardTypeDiscover:
            cardTypeName = @"Discover";
            break;
        case PTKCardTypeJCB:
            cardTypeName = @"JCB";
            break;
        case PTKCardTypeMasterCard:
            cardTypeName = @"MasterCard";
            break;
        case PTKCardTypeVisa:
            cardTypeName = @"Visa";
            break;
        default:
            break;
    }
    
    return cardTypeName;
}

#pragma mark - Delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ([textField isEqual:self.cardCVCField]) {
        [self setPlaceholderToCVC];
    } else {
        [self setPlaceholderToCardType];
    }

    if ([textField isEqual:self.cardNumberField] && !_isInitialState) {
        [self stateCardNumber];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    if ([textField isEqual:self.cardNumberField]) {
        return [self cardNumberFieldShouldChangeCharactersInRange:range replacementString:replacementString];
    }

    if ([textField isEqual:self.cardExpiryField]) {
        return [self cardExpiryShouldChangeCharactersInRange:range replacementString:replacementString];
    }

    if ([textField isEqual:self.cardCVCField]) {
        return [self cardCVCShouldChangeCharactersInRange:range replacementString:replacementString];
    }

    return YES;
}

- (void)pkTextFieldDidBackSpaceWhileTextIsEmpty:(PTKTextField *)textField
{
    if (textField == self.cardCVCField)
        [self.cardExpiryField becomeFirstResponder];
    else if (textField == self.cardExpiryField)
        [self stateCardNumber];
}

- (BOOL)cardNumberFieldShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [self.cardNumberField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PTKTextField textByRemovingUselessSpacesFromString:resultString];
    PTKCardNumber *cardNumber = [PTKCardNumber cardNumberWithString:resultString];

    if (![cardNumber isPartiallyValid])
        return NO;

    if (replacementString.length > 0) {
        self.cardNumberField.text = [cardNumber formattedStringWithTrail];
    } else {
        self.cardNumberField.text = [cardNumber formattedString];
    }

    [self setPlaceholderToCardType];

    if ([cardNumber isValid]) {
        [self textFieldIsValid:self.cardNumberField];
        [self stateMeta];

    } else if ([cardNumber isValidLength] && ![cardNumber isValidLuhn]) {
        [self textFieldIsInvalid:self.cardNumberField withErrors:YES];

    } else if (![cardNumber isValidLength]) {
        [self textFieldIsInvalid:self.cardNumberField withErrors:NO];
    }

    return NO;
}

- (BOOL)cardExpiryShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [self.cardExpiryField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PTKTextField textByRemovingUselessSpacesFromString:resultString];
    PTKCardExpiry *cardExpiry = [PTKCardExpiry cardExpiryWithString:resultString];

    if (![cardExpiry isPartiallyValid]) return NO;

    // Only support shorthand year
    if ([cardExpiry formattedString].length > 5) return NO;

    if (replacementString.length > 0) {
        self.cardExpiryField.text = [cardExpiry formattedStringWithTrail];
    } else {
        self.cardExpiryField.text = [cardExpiry formattedString];
    }

    if ([cardExpiry isValid]) {
        [self textFieldIsValid:self.cardExpiryField];
        [self stateCardCVC];

    } else if ([cardExpiry isValidLength] && ![cardExpiry isValidDate]) {
        [self textFieldIsInvalid:self.cardExpiryField withErrors:YES];
    } else if (![cardExpiry isValidLength]) {
        [self textFieldIsInvalid:self.cardExpiryField withErrors:NO];
    }

    return NO;
}

- (BOOL)cardCVCShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [self.cardCVCField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PTKTextField textByRemovingUselessSpacesFromString:resultString];
    PTKCardCVC *cardCVC = [PTKCardCVC cardCVCWithString:resultString];
    PTKCardType cardType = [[PTKCardNumber cardNumberWithString:self.cardNumberField.text] cardType];

    // Restrict length
    if (![cardCVC isPartiallyValidWithType:cardType]) return NO;

    // Strip non-digits
    self.cardCVCField.text = [cardCVC string];

    if ([cardCVC isValidWithType:cardType]) {
        [self textFieldIsValid:self.cardCVCField];
    } else {
        [self textFieldIsInvalid:self.cardCVCField withErrors:NO];
    }

    return NO;
}


#pragma mark - Validations

- (void)checkValid
{
    if ([self isValid]) {
        _isValidState = YES;

        if ([self.delegate respondsToSelector:@selector(paymentView:withCard:isValid:)]) {
            [self.delegate paymentView:self withCard:self.card isValid:YES];
        }

    } else if (![self isValid] && _isValidState) {
        _isValidState = NO;

        if ([self.delegate respondsToSelector:@selector(paymentView:withCard:isValid:)]) {
            [self.delegate paymentView:self withCard:self.card isValid:NO];
        }
    }
}

- (void)textFieldIsValid:(UITextField *)textField
{
    textField.textColor = self.goodColor;
    [self checkValid];
}

- (void)textFieldIsInvalid:(UITextField *)textField withErrors:(BOOL)errors
{
    if (errors) {
        textField.textColor = self.badColor;
    } else {
        textField.textColor = self.textColor;
    }

    [self checkValid];
}

#pragma mark -
#pragma mark UIResponder
- (UIResponder *)firstResponderField;
{
    NSMutableArray* responders = [NSMutableArray arrayWithCapacity: 3];
    
    if ( self.cardNumberField )
        [responders addObject: self.cardNumberField];
    
    if ( self.cardExpiryField )
        [responders addObject: self.cardExpiryField];
    
    if ( self.cardCVCField )
        [responders addObject: self.cardCVCField];
    
    for (UIResponder *responder in responders) {
        if (responder.isFirstResponder) {
            return responder;
        }
    }

    return nil;
}

- (PTKTextField *)firstInvalidField;
{
    if (![[PTKCardNumber cardNumberWithString:self.cardNumberField.text] isValid])
        return self.cardNumberField;
    else if (![[PTKCardExpiry cardExpiryWithString:self.cardExpiryField.text] isValid])
        return self.cardExpiryField;
    else if (![[PTKCardCVC cardCVCWithString:self.cardCVCField.text] isValid])
        return self.cardCVCField;

    return nil;
}

- (PTKTextField *)nextFirstResponder;
{
    if (self.firstInvalidField)
        return self.firstInvalidField;

    return self.cardCVCField;
}

- (BOOL)isFirstResponder;
{
    return self.firstResponderField.isFirstResponder;
}

- (BOOL)canBecomeFirstResponder;
{
    return self.nextFirstResponder.canBecomeFirstResponder;
}

- (BOOL)becomeFirstResponder;
{
    return [self.nextFirstResponder becomeFirstResponder];
}

- (BOOL)canResignFirstResponder;
{
    return self.firstResponderField.canResignFirstResponder;
}

- (BOOL)resignFirstResponder;
{
    [super resignFirstResponder];
    
    return [self.firstResponderField resignFirstResponder];
}

@end
