//
//  ViewController.m
//  iOS Example Obj-C
//
//  Created by Hamilton Chapman on 09/09/2016.
//  Copyright © 2016 Eventflit. All rights reserved.
//

#import "ViewController.h"

@interface AuthRequestBuilder : NSObject <AuthRequestBuilderProtocol>

- (NSMutableURLRequest *)requestForSocketID:(NSString *)socketID channel:(EventflitChannel *)channel;
- (NSURLRequest *)requestForSocketID:(NSString *)socketID channelName:(NSString *)channelName;

@end

@implementation AuthRequestBuilder

- (NSMutableURLRequest *)requestForSocketID:(NSString *)socketID channel:(EventflitChannel *)channel {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [[NSURL alloc] initWithString:@"http://localhost:9292/eventflit/auth"]];
    NSString *dataStr = [NSString stringWithFormat: @"socket_id=%@&channel_name=%@", socketID, [channel name]];
    NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = data;
    request.HTTPMethod = @"POST";
    return request;
}

- (NSURLRequest *)requestForSocketID:(NSString *)socketID channelName:(NSString *)channelName {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:@"http://localhost:9292/eventflit/auth"]];
    NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL: [[NSURL alloc] initWithString:@"http://localhost:9292/eventflit/auth"]];

    NSString *dataStr = [NSString stringWithFormat: @"socket_id=%@&channel_name=%@", socketID, channelName];
    NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    mutableRequest.HTTPBody = data;
    mutableRequest.HTTPMethod = @"POST";

    request = [mutableRequest copy];

    return request;
}

@end

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    OCAuthMethod *authMethod = [[OCAuthMethod alloc] initWithSecret:@"YOUR_APP_SECRET"];
    EventflitClientOptions *options = [[EventflitClientOptions alloc] initWithAuthMethod:authMethod];

    // Use this if you want to try out your auth Endpoint
//    OCAuthMethod *endpointAuthMethod = [[OCAuthMethod alloc] initWithAuthRequestBuilder:[[AuthRequestBuilder alloc] init]];
//    EventflitClientOptions *optionsWithEndpoint = [[EventflitClientOptions alloc] initWithAuthMethod:endpointAuthMethod];

    self.client = [[Eventflit alloc] initWithAppKey:@"YOUR_APP_KEY" options:options];
    self.client.connection.delegate = self;

    self.client.connection.userDataFetcher = ^EventflitPresenceChannelMember* () {
        NSString *uuid = [[NSUUID UUID] UUIDString];
        return [[EventflitPresenceChannelMember alloc] initWithUserId:uuid userInfo:nil];
    };

    [self.client bind:^void (NSDictionary *data) {
        NSString *eventName = data[@"event"];

        if ([eventName isEqualToString:@"eventflit:error"]) {
            NSString *errorMessage = data[@"data"][@"message"];
            NSLog(@"Error message: %@", errorMessage);
        }
    }];

    [self.client connect];

    EventflitChannel *presChan = [self.client subscribeWithChannelName:@"presence-test"];

    [presChan bindWithEventName:@"test-event" callback:^void (id data) {
        NSLog(@"And here is the data: %@", data);
    }];

    void (^onMemberAdded)(EventflitPresenceChannelMember*) = ^void (EventflitPresenceChannelMember *member) {
        NSLog(@"member added: %@", member);
    };

    void (^onMemberRemoved)(EventflitPresenceChannelMember*) = ^void (EventflitPresenceChannelMember *member) {
        NSLog(@"member removed: %@", member);
    };

    EventflitPresenceChannel *presChanExplicit = [self.client subscribeToPresenceChannelWithChannelName:@"presence-explicit" onMemberAdded:onMemberAdded onMemberRemoved:onMemberRemoved];

    [presChanExplicit bindWithEventName:@"testing" callback: ^void (id data) {
        NSLog(@"Data: %@", data);

        [presChanExplicit triggerWithEventName:@"client-testing" data:@{ @"developers" : @"developers developers developers" }];
    }];
}

- (void)changedConnectionStateFrom:(enum ConnectionState)old to:(enum ConnectionState)new_ {
    NSLog(@"Old connection: %d, new connection: %d", (int)old, (int)new_);
}

- (void)debugLogWithMessage:(NSString *)message {
    NSLog(@"%@", message);
}

- (void)subscribedToChannelWithName:(NSString *)name {
    NSLog(@"Subscribed to channel %@", name);

    if ([name isEqual: @"presence-test"]) {
        NSLog(@"%@", [(EventflitPresenceChannel *)[self.client.connection.channels findWithName:@"presence-test"] members]);
    }
}

- (void)failedToSubscribeToChannelWithName:(NSString *)name response:(NSURLResponse *)response data:(NSString *)data error:(NSError *)error {
    NSLog(@"Failed to subscribe to channel %@", name);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

