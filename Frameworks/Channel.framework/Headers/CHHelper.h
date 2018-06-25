//
//  CHHelper.h
//  Channel
//
//  Created by Apisit Toompakdee on 4/22/17.
//  Copyright © 2017 Mogohichi, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

BOOL checkIfInstanceOverridesSelector(Class instance, SEL selector);
Class getClassWithProtocolInHierarchy(Class searchClass, Protocol* protocolToFind);
NSArray* ClassGetSubclasses(Class parentClass);
void injectToProperClass(SEL newSel, SEL makeLikeSel, NSArray* delegateSubclasses, Class myClass, Class delegateClass);
BOOL injectSelector(Class newClass, SEL newSel, Class addToClass, SEL makeLikeSel);
