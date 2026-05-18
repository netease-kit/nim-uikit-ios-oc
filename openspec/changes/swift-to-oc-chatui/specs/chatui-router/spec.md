## ADDED Requirements

### Requirement: ChatRouter Class
Open class `ChatRouter` (subclass of NSObject, annotated with `objcMembers`) providing static route registration for chat-related navigation actions.
#### Scenario: Class exists as NSObject subclass
- **WHEN** the OC translation is compiled
- **THEN** `ChatRouter` is an `NSObject` subclass with all methods exposed to Objective-C

---

### Requirement: registerCommon Static Method
Class method `+registerCommon` that registers common chat router handlers on the shared `Router` instance. Currently registers the `ChatAddFriendRouter` route.
#### Scenario: Common routes registered
- **WHEN** `[ChatRouter registerCommon]` is called
- **THEN** the `ChatAddFriendRouter` route key is registered on `[Router shared]` with a handler block

---

### Requirement: ChatAddFriendRouter Handler
The handler registered for the `ChatAddFriendRouter` route key. It extracts `text` (NSString*) and `conversationId` (NSString*) from the `param` dictionary, creates a text message via `[MessageUtils textMessageWithText:]`, and sends it asynchronously via `[ChatRepo.shared sendMessage:conversationId:completion:]`. The completion block logs any error.
#### Scenario: Send hello message on add-friend route
- **WHEN** the `ChatAddFriendRouter` route is triggered with a param dictionary containing keys "text" (NSString*) and "conversationId" (NSString*)
- **THEN** a text message is created from the "text" value using `MessageUtils`, and sent to the conversation identified by "conversationId" via `ChatRepo`
#### Scenario: Missing parameters are safely ignored
- **WHEN** the param dictionary does not contain "text" or "conversationId" (or they are not NSString*)
- **THEN** no message is created or sent (the guard/if-let equivalent in OC safely exits)
#### Scenario: Send error is logged
- **WHEN** the message send completes with an error
- **THEN** the error description is logged via `NEALog.errorLog` with the tag "ChatAddFriendRouter"
