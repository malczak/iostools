//
//  IAPHelper.h
//  In App Rage
//
//  Created by Ray Wenderlich on 9/5/12.
//  Copyright (c) 2012 Razeware LLC. All rights reserved.
//

#import <StoreKit/StoreKit.h>

UIKIT_EXTERN NSString *const IAPHelperProductPurchasedNotification;
UIKIT_EXTERN NSString *const IAPHelperProductPurchaseErrorNotification;

typedef void (^RequestProductsCompletionHandler)(BOOL success, NSArray * products);

@interface IAPHelper : NSObject

@property (nonatomic, readonly) BOOL productsListIsValid;

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;
- (BOOL)canMakePayments;
- (BOOL)hasAnyProductsAvailable;
- (BOOL)mainProductPurchased;
- (NSArray*)availableProducts;
- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler;
- (void)buyProductByProductIdentifier:(NSString *)productIdentifier;
- (void)buyProduct:(SKProduct *)product;
- (BOOL)productPurchased:(NSString *)productIdentifier;
- (SKProduct*)productByProductIdentifier:(NSString *)productIdentifier;
- (void)restoreCompletedTransactions;

@end