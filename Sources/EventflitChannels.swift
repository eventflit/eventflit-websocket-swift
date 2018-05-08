import Foundation

@objcMembers
@objc open class EventflitChannels: NSObject {
    open var channels = [String: EventflitChannel]()

    /**
        Create a new EventflitChannel, which is returned, and add it to the EventflitChannels list
        of channels

        - parameter name:            The name of the channel to create
        - parameter connection:      The connection associated with the channel being created
        - parameter auth:            A EventflitAuth value if subscription is being made to an
                                     authenticated channel without using the default auth methods
        - parameter onMemberAdded:   A function that will be called with information about the
                                     member who has just joined the presence channel
        - parameter onMemberRemoved: A function that will be called with information about the
                                     member who has just left the presence channel

        - returns: A new EventflitChannel instance
    */
    internal func add(
        name: String,
        connection: EventflitConnection,
        auth: EventflitAuth? = nil,
        onMemberAdded: ((EventflitPresenceChannelMember) -> ())? = nil,
        onMemberRemoved: ((EventflitPresenceChannelMember) -> ())? = nil
    ) -> EventflitChannel {
        if let channel = self.channels[name] {
            return channel
        } else {
            var newChannel: EventflitChannel
            if EventflitChannelType.isPresenceChannel(name: name) {
                newChannel = EventflitPresenceChannel(
                    name: name,
                    connection: connection,
                    auth: auth,
                    onMemberAdded: onMemberAdded,
                    onMemberRemoved: onMemberRemoved
                )
            } else {
                newChannel = EventflitChannel(name: name, connection: connection, auth: auth)
            }
            self.channels[name] = newChannel
            return newChannel
        }
    }

    /**
        Create a new PresencEventflitChannel, which is returned, and add it to the EventflitChannels
        list of channels

        - parameter channelName:     The name of the channel to create
        - parameter connection:      The connection associated with the channel being created
        - parameter auth:            A EventflitAuth value if subscription is being made to an
                                     authenticated channel without using the default auth methods
        - parameter onMemberAdded:   A function that will be called with information about the
                                     member who has just joined the presence channel
        - parameter onMemberRemoved: A function that will be called with information about the
                                     member who has just left the presence channel

        - returns: A new EventflitPresenceChannel instance
    */
    internal func addPresence(
        channelName: String,
        connection: EventflitConnection,
        auth: EventflitAuth? = nil,
        onMemberAdded: ((EventflitPresenceChannelMember) -> ())? = nil,
        onMemberRemoved: ((EventflitPresenceChannelMember) -> ())? = nil
    ) -> EventflitPresenceChannel {
        if let channel = self.channels[channelName] as? EventflitPresenceChannel {
            return channel
        } else {
            let newChannel = EventflitPresenceChannel(
                name: channelName,
                connection: connection,
                auth: auth,
                onMemberAdded: onMemberAdded,
                onMemberRemoved: onMemberRemoved
            )
            self.channels[channelName] = newChannel
            return newChannel
        }
    }

    /**
        Remove the EventflitChannel with the given channelName from the channels list

        - parameter name: The name of the channel to remove
    */
    internal func remove(name: String) {
        self.channels.removeValue(forKey: name)
    }

    /**
        Return the EventflitChannel with the given channelName from the channels list, if it exists

        - parameter name: The name of the channel to return

        - returns: A EventflitChannel instance, if a channel with the given name existed, otherwise nil
    */
    public func find(name: String) -> EventflitChannel? {
        return self.channels[name]
    }

    /**
        Return the EventflitPresenceChannel with the given channelName from the channels list, if it exists

        - parameter name: The name of the presence channel to return

        - returns: A EventflitPresenceChannel instance, if a channel with the given name existed,
                   otherwise nil
    */
    public func findPresence(name: String) -> EventflitPresenceChannel? {
        return self.channels[name] as? EventflitPresenceChannel
    }
}
