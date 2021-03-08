//
//  CHNodeModel.m
//  Chanify
//
//  Created by WizJin on 2021/2/25.
//

#import "CHNodeModel.h"

@implementation CHNodeModel

+ (instancetype)modelWithNID:(nullable NSString *)nid name:(nullable NSString *)name endpoint:(nullable NSString *)endpoint features:(nullable NSString *)features {
    if (nid != nil) {
        return [[self.class alloc] initWithNID:nid name:name endpoint:endpoint features:features];
    }
    return nil;
}

- (instancetype)initWithNID:(NSString *)nid name:(nullable NSString *)name endpoint:(nullable NSString *)endpoint features:(nullable NSString *)features {
    if (self = [super init]) {
        _nid = nid;
        _name = name;
        _endpoint = (endpoint ?: @"");
        _features = [features componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
        if ([nid isEqualToString:@"sys"]) {
            if (name.length <= 0) _name = @"Chanify".localized;
            if (endpoint.length <= 0) _endpoint = [@"https://" stringByAppendingString:@kCHAPIHostname];
        }
        if (self.endpoint.length > 0 && self.name.length <= 0) {
            NSURL *url = [NSURL URLWithString:self.endpoint];
            _name = url.host;
        }
        if (self.name.length <= 0) {
            _name = @"";
        }
        
    }
    return self;
}

- (BOOL)isEqual:(CHNodeModel *)rhs {
    return [self.nid isEqualToString:rhs.nid];
}

- (NSUInteger)hash {
    return self.nid.hash;
}

- (BOOL)isFullEqual:(CHNodeModel *)rhs {
    return ([self.nid isEqualToString:rhs.nid]
            && (self.name == rhs.name || [self.name isEqualToString:rhs.name])
            && (self.endpoint == rhs.endpoint || [self.endpoint isEqualToString:rhs.endpoint])
            && (self.icon == rhs.icon || [self.icon isEqualToString:rhs.icon])
            && (self.features == rhs.features || [[self.features componentsJoinedByString:@","] isEqualToString:[rhs.features componentsJoinedByString:@","]]));
}

@end