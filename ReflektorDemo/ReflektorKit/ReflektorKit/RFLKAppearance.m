//
//  RFLKAppearance.m
//  ReflektorKit
//
//  Created by Alex Usbergo on 22/04/15.
//  Copyright (c) 2015 Alex Usbergo. All rights reserved.
//

#import "RFLKAppearance.h"
#import <objc/runtime.h>
#import "Aspects.h"
#import "RFLKParser.h"
#import "RFLKParserItems.h"
#import "RFLKMacros.h"
#import "UIKit+RFLKAdditions.h"
#import "RFLKWatchFileServer.h"

NSString *RFLKApperanceStylesheetDidChangeNotification = @"RFLKApperanceStylesheetDidChangeNotification";

static const void *UIViewTraitsKey;
static const void *UIViewComputedPropertiesKey;

@implementation UIView (RFLKAppearance)

- (NSDictionary*)rflk_computedProperties
{
    return objc_getAssociatedObject(self, &UIViewComputedPropertiesKey);
}

- (void)setRflk_computedProperties:(NSDictionary*)rflk_computedProperties
{
    objc_setAssociatedObject(self, &UIViewComputedPropertiesKey, rflk_computedProperties, OBJC_ASSOCIATION_RETAIN);
}

- (NSSet*)rflk_traits
{
    return objc_getAssociatedObject(self, &UIViewTraitsKey);
}

- (void)rflk_addTrait:(NSString*)traitName
{
    NSMutableSet *set = objc_getAssociatedObject(self, &UIViewTraitsKey);
    
    if (set == nil)
        set = [[NSMutableSet alloc] init];
    
    [set addObject:traitName];
    
    objc_setAssociatedObject(self, &UIViewTraitsKey, set, OBJC_ASSOCIATION_RETAIN);
    [self setNeedsLayout];
}

- (void)rflk_removeTrait:(NSString*)traitName
{
    NSMutableSet *set = objc_getAssociatedObject(self, &UIViewTraitsKey);
    
    if (set == nil)
        set = [[NSMutableSet alloc] init];
    
    [set removeObject:traitName];
    
    objc_setAssociatedObject(self, &UIViewTraitsKey, set, OBJC_ASSOCIATION_RETAIN);
    [self setNeedsLayout];
}

- (id)rflk_property:(NSString*)propertyName
{
    return [self rflk_property:propertyName withTraitCollection:[UIScreen mainScreen].traitCollection andBounds:[UIScreen mainScreen].rflk_screenBounds.size];
}

- (id)rflk_property:(NSString*)propertyName withTraitCollection:(UITraitCollection*)traitCollection andBounds:(CGSize)size
{
    NSDictionary *computedProperties = self.rflk_computedProperties;
    
    if (computedProperties == nil)
        computedProperties = [[RFLKAppearance sharedAppearance] computeStyleForView:self];
    
    if (computedProperties[propertyName] == nil)
        [NSException raise:[NSString stringWithFormat:@"Property not defined: %@", propertyName] format:nil];
    
    return [computedProperties[propertyName] valueWithTraitCollection:traitCollection andBounds:size];
}

- (void)rflk_stylesheetDidChangeNotification:(id)notification
{
    self.rflk_computedProperties = [[RFLKAppearance sharedAppearance] computeStyleForView:self];
    [self setNeedsLayout];
}

- (void)rflk_applyComputedStyle:(NSDictionary*)computedStyle
{
    if (computedStyle.count != 0) {
        
        for (NSString *key in computedStyle)
            if ([self respondsToSelector:NSSelectorFromString(key)]) {
                
                // compute the value and set it in the view
                id value = [computedStyle[key] valueWithTraitCollection:self.traitCollection andBounds:self.bounds.size];
                if (![value isEqual:[self valueForKey:key]])
                    [self setValue:value forKey:key];
            }
    }
}

@end

@interface RFLKAppearance ()

@property (nonatomic, strong) NSDictionary *propertyMap;

@end

@implementation RFLKAppearance

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSError *error;
        [UIView aspect_hookSelector:@selector(layoutSubviews) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> aspectInfo) {
            
            UIView *_self = aspectInfo.instance;
            [[RFLKAppearance sharedAppearance] computeStyleForView:_self];
            
            if (_self.rflk_computedProperties.count != 0) {
                [_self rflk_applyComputedStyle:_self.rflk_computedProperties];
            }
            
        } error:&error];
        
        [UIView aspect_hookSelector:@selector(didMoveToSuperview) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo) {
            
            UIView *_self = aspectInfo.instance;
            
            if (!_self.rflk_observationAdded) {
                
                // triggers rflk_stylesheetDidChangeNotification to be called when the stylesheet changes
                _self.rflk_observationAdded = YES;
                [_self rflk_addObserverForName:RFLKApperanceStylesheetDidChangeNotification usingBlock:^(NSNotification *note) {
                    [_self rflk_stylesheetDidChangeNotification:note];
                }];
            }

            
        } error:&error];
    });
    
    [[RFLKWatchFileServer sharedInstance] startOnPort:RFLKWatchFileServerDefaultPort];
}

+ (instancetype)sharedAppearance
{ 
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)parseStylesheetData:(NSString*)stylesheet
{
    self.propertyMap = rflk_parseStylesheet(stylesheet);
    [[NSNotificationCenter defaultCenter] postNotificationName:RFLKApperanceStylesheetDidChangeNotification object:nil userInfo:@{}];
}

- (NSDictionary*)computeStyleForClass:(Class)klass withTraits:(NSSet*)traits traitCollection:(UITraitCollection*)traitCollection bounds:(CGSize)bounds
{
    NSMutableDictionary *computedProperties = @{}.mutableCopy;
    NSMutableArray *selectors = @[].mutableCopy;
    
    for (RFLKSelector *selector in self.propertyMap.allKeys) {
        
        switch (selector.type) {
                
            case RFLKSelectorTypeClass:
                if (selector.associatedClass == klass || [klass isSubclassOfClass:selector.associatedClass])
                    if (!selector.trait.length || (selector.trait.length && [traits containsObject:selector.trait]))
                        if (!selector.condition || (selector.condition && [selector.condition evaluatConditionWithTraitCollection:traitCollection andBounds:[UIScreen mainScreen].rflk_screenBounds.size]))
                            [selectors addObject:selector];
                break;
                
            case RFLKSelectorTypeTrait:
                if ([traits containsObject:selector.trait])
                    [selectors addObject:selector];
                break;
                
            default:
                break;
        }
    }
    
    //selector priorities: RFLKSelectorTypeClass > RFLKSelectorTypeTrait > RFLKSelectorTypeClassWithAssociatedTrait
    NSArray *sortedSelectors = [selectors sortedArrayUsingComparator:^NSComparisonResult(RFLKSelector *obj1, RFLKSelector *obj2) {
        return [obj1 comparePriority:obj2];
    }];

    
    for (RFLKSelector *selector in sortedSelectors)
        for (NSString *key in self.propertyMap[selector])
            computedProperties[key] = self.propertyMap[selector][key];
    
    return computedProperties;
}

- (NSDictionary*)computeStyleForView:(UIView*)view
{
    NSDictionary *computedProperties = [self computeStyleForClass:view.class withTraits:view.rflk_traits traitCollection:view.traitCollection bounds:view.bounds.size];
    view.rflk_computedProperties = computedProperties;
    return computedProperties;
}

@end

id rflk_computedProperty(UIView *view, NSString *propertyName)
{
    NSDictionary *computedProperties = view.rflk_computedProperties;
    
    if (computedProperties == nil)
        computedProperties = [[RFLKAppearance sharedAppearance] computeStyleForView:view];
    
    NSCAssert(computedProperties[propertyName] != nil, @"property not defined");
    
    return [computedProperties[propertyName] valueWithTraitCollection:[UIScreen mainScreen].traitCollection andBounds:view.bounds.size];
}
