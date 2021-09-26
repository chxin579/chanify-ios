//
//  CHBarButtonItem.m
//  OSX
//
//  Created by WizJin on 2021/9/24.
//

#import "CHBarButtonItem.h"
#import "CHTheme.h"

@implementation CHBarButtonItem

+ (instancetype)itemWithIcon:(NSString *)icon target:(id)target action:(SEL)action {
    return [[self.class alloc] initWithIcon:icon target:target action:action];
}

- (instancetype)initWithIcon:(NSString *)icon target:(id)target action:(SEL)action {
    if (self = [super initWithFrame:NSMakeRect(0, 0, 32, 32)]) {
        self.image = [CHImage systemImageNamed:icon];
        self.imageScaling = NSImageScaleProportionallyUpOrDown;
        self.contentTintColor = CHTheme.shared.labelColor;
        self.bezelStyle = NSBezelStyleTexturedSquare;
        self.showsBorderOnlyWhileMouseInside = YES;
        self.target = target;
        self.action = action;
    }
    return self;
}


@end