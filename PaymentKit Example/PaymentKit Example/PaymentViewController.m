//
//  ViewController.m
//  PTKPayment Example
//
//  Created by Alex MacCaw on 1/21/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PaymentViewController.h"

@interface PaymentViewController()

@property IBOutlet PTKView* paymentView;
@property (weak, nonatomic) IBOutlet UIView *smallPaymentView;

@end


#pragma mark -

@implementation PaymentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    self.title = @"Change Card";
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(save:)];
    saveButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = saveButton;
}


- (void) paymentView:(PTKView *)paymentView withCard:(PTKCard *)card isValid:(BOOL)valid
{
    self.navigationItem.rightBarButtonItem.enabled = valid;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)save:(id)sender
{
    PTKCard* card = self.paymentView.card;
    
    NSLog(@"Card last4: %@", card.last4);
    NSLog(@"Card expiry: %lu/%lu", (unsigned long)card.expMonth, (unsigned long)card.expYear);
    NSLog(@"Card cvc: %@", card.cvc);
    
    [[NSUserDefaults standardUserDefaults] setValue: card.last4 forKey: @"card.last4"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.navigationController popViewControllerAnimated: YES];
}

@end
