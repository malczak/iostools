//
//  IAPHelper.m
//  In App Rage
//
//  Created by Ray Wenderlich on 9/5/12.
//  Copyright (c) 2012 Razeware LLC. All rights reserved.
//

// 1
#import "IAPHelper.h"
#import <StoreKit/StoreKit.h>

NSString *const IAPHelperProductPurchasedNotification = @"IAPHelperProductPurchasedNotification";
NSString *const IAPHelperProductPurchaseErrorNotification = @"IAPHelperProductPurchaseErrorNotification";

// 2
@interface IAPHelper () <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@end

// 3
@implementation IAPHelper {
    SKProductsRequest * _productsRequest;
    RequestProductsCompletionHandler _completionHandler;
    
    NSArray * _productIdentifiers;
    NSMutableSet * _purchasedProductIdentifiers;
    NSArray * _availableProducts;
}

@synthesize productsListIsValid = _productsListIsValid;

- (id)initWithProductIdentifiers:(NSArray *)productIdentifiers {
    
    if ((self = [super init])) {
        
        _productsListIsValid = NO;
        
        _availableProducts = nil;
        
        // Store product identifiers
        _productIdentifiers = productIdentifiers;
        
        // Check for previously purchased products
        _purchasedProductIdentifiers = [NSMutableSet set];
        for (NSString * productIdentifier in _productIdentifiers) {
            BOOL productPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:productIdentifier];
            if (productPurchased) {
                [_purchasedProductIdentifiers addObject:productIdentifier];
#ifdef DEBUG
                NSLog(@"Previously purchased: %@", productIdentifier);
#endif
            } else {
#ifdef DEBUG
                NSLog(@"Not purchased: %@", productIdentifier);
#endif
            }
        }
        
        // Add self as transaction observer
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        
    }
    return self;
    
}

- (BOOL)canMakePayments {
    return [SKPaymentQueue canMakePayments];
}

- (BOOL)hasAnyProductsAvailable {
    return (_availableProducts!=nil) && ([_availableProducts count]);
}

- (BOOL)mainProductPurchased
{
    NSString *productId = (NSString*)[_productIdentifiers.objectEnumerator nextObject];
    if(!productId) {
        return NO;
    }
    return [self productPurchased:productId];
}

- (NSArray*)availableProducts {
    return _availableProducts;
}

- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler {
    
    // 1
    _completionHandler = [completionHandler copy];
    
    // 2
    _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:_productIdentifiers]];
    _productsRequest.delegate = self;
    [_productsRequest start];
    
}

- (BOOL)productPurchased:(NSString *)productIdentifier {
    return [_purchasedProductIdentifiers containsObject:productIdentifier];
}

- (void)buyProductByProductIdentifier:(NSString *)productIdentifier
{
    SKProduct *product = [self productByProductIdentifier:productIdentifier];
    if(product) {
        [self buyProduct:product];
    }
}

- (void)buyProduct:(SKProduct *)product {
#ifdef DEBUG
    NSLog(@"Buying %@...", product.productIdentifier);
#endif
    SKPayment * payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
}

- (SKProduct*)productByProductIdentifier:(NSString *)productIdentifier
{
    if(NO==self.hasAnyProductsAvailable) {
        return nil;
    }
    
    for (SKProduct *product in self.availableProducts) {
        if([product.productIdentifier isEqualToString:productIdentifier]) {
            return product;
        }
    }
    
    return nil;
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    NSArray * skProducts = response.products;
#ifdef DEBUG
    NSLog(@"Loaded list of products... %d", [skProducts count]);
    
        for (SKProduct * skProduct in skProducts) {
            NSLog(@"Found product: %@ %@ %0.2f",
                  skProduct.productIdentifier,
                  skProduct.localizedTitle,
                  skProduct.price.floatValue);
        }
#endif
    
    _productsRequest = nil;
    _productsListIsValid = YES;
    
    // sort to preserve order :D
    NSArray *sortedProducts =(nil!=skProducts)?
    [skProducts sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        SKProduct *product1 = (SKProduct*)obj1;
        SKProduct *product2 = (SKProduct*)obj2;
        int index1 = [_productIdentifiers indexOfObject:product1.productIdentifier];
        if(index1==NSNotFound) {
            return NSOrderedSame;
        }
        int index2 = [_productIdentifiers indexOfObject:product2.productIdentifier];
        if(index2==NSNotFound) {
            return NSOrderedSame;
        }
        if(index1<index2) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }]:nil;
    
    _availableProducts = sortedProducts;
    
    _completionHandler(YES, _availableProducts);
    _completionHandler = nil;
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
#ifdef DEBUG
    NSLog(@"Failed to load list of products.");
#endif
    _productsListIsValid = YES;
    _productsRequest = nil;
    
    _completionHandler(NO, nil);
    _completionHandler = nil;
    
}

#pragma mark SKPaymentTransactionOBserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction * transaction in transactions) {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing:
#ifdef DEBUG
                NSLog(@"CHyba kupujemy czy cos");
#endif
                break;
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    };
}

-(void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"Error %@",error.description);
#endif
    [[NSNotificationCenter defaultCenter] postNotificationName:IAPHelperProductPurchaseErrorNotification object:error userInfo:nil];
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
#ifdef DEBUG
    NSLog(@"completeTransaction...");
#endif
    [self provideContentForProductIdentifier:transaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
#ifdef DEBUG
    NSLog(@"restoreTransaction...");
#endif
    [self provideContentForProductIdentifier:transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
#ifdef DEBUG
    NSLog(@"failedTransaction...");
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        NSLog(@"Transaction error: %@", transaction.error.localizedDescription);
    }
#endif
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:IAPHelperProductPurchaseErrorNotification object:transaction.error userInfo:nil];

}

- (void)provideContentForProductIdentifier:(NSString *)productIdentifier {
    
    [_purchasedProductIdentifiers addObject:productIdentifier];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:IAPHelperProductPurchasedNotification object:productIdentifier userInfo:nil];
    
}

- (void)restoreCompletedTransactions {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

@end