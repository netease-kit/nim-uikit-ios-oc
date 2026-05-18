## ADDED Requirements

### Requirement: NIMEmoticonType Enum
Enum `NIMEmoticonType` (NSInteger) defining emoticon source types: `.file` (0) and `.unicode` (1).
#### Scenario: Enum values map correctly
- **WHEN** an emoticon has a non-empty `unicode` property
- **THEN** its `type` returns `NIMEmoticonTypeUnicode`
#### Scenario: File type is default
- **WHEN** an emoticon has an empty or nil `unicode` property
- **THEN** its `type` returns `NIMEmoticonTypeFile`

---

### Requirement: NIMInputEmoticon Model
Open class `NIMInputEmoticon` (subclass of NSObject) representing a single emoticon with properties: `emoticonID` (NSString*), `tag` (NSString*), `fileName` (NSString*), `unicode` (NSString*). Read-only computed property `type` returns `NIMEmoticonType` based on whether `unicode` is non-empty.
#### Scenario: Type derived from unicode
- **WHEN** `unicode` is set to a non-empty string (e.g. "😀")
- **THEN** `type` returns `NIMEmoticonTypeUnicode`
#### Scenario: Type derived from fileName
- **WHEN** `unicode` is nil or empty and `fileName` is set
- **THEN** `type` returns `NIMEmoticonTypeFile`

---

### Requirement: NIMInputEmoticonLayout Model
Open class `NIMInputEmoticonLayout` (subclass of NSObject) computing grid layout for emoji pages. Properties: `rows` (NSInteger), `columes` (NSInteger), `itemCountInPage` (NSInteger), `cellWidth` (CGFloat), `cellHeight` (CGFloat), `imageWidth` (CGFloat), `imageHeight` (CGFloat), `emoji` (BOOL).
#### Scenario: Layout computed from width
- **WHEN** initialized with a container width
- **THEN** `rows` is set to `NIMKit_EmojRows` (3), `columes` is calculated as `(width - leftMargin - rightMargin) / imageWidth`, `itemCountInPage` is `rows * columes - 1` (last slot reserved for delete button), `cellWidth` is evenly distributed, `cellHeight` / `imageWidth` / `imageHeight` use defined constants, and `emoji` is YES

---

### Requirement: NIMInputEmoticonCatalog Model
Open class `NIMInputEmoticonCatalog` (subclass of NSObject) grouping emoticons into a catalog. Properties: `layout` (NIMInputEmoticonLayout*), `catalogID` (NSString*), `title` (NSString*), `id2Emoticons` (NSDictionary<NSString*, NIMInputEmoticon*>*), `tag2Emoticons` (NSDictionary<NSString*, NIMInputEmoticon*>*), `emoticons` (NSArray<NIMInputEmoticon*>*), `icon` (NSString*), `iconPressed` (NSString*), `pagesCount` (NSInteger).
#### Scenario: Lookup emoticon by ID
- **WHEN** `id2Emoticons` dictionary is populated
- **THEN** looking up an emoticon by its `emoticonID` key returns the correct `NIMInputEmoticon` instance
#### Scenario: Lookup emoticon by tag
- **WHEN** `tag2Emoticons` dictionary is populated
- **THEN** looking up an emoticon by its `tag` key returns the correct `NIMInputEmoticon` instance

---

### Requirement: NIMInputEmoticonManager Singleton
Open class `NIMInputEmoticonManager` (subclass of NSObject) with a shared singleton (`+shared`). On initialization it parses the emoji plist from `Bundle.nim_EmojiPlistFile()` and populates catalogs. Provides lookup methods and a custom-config entry point. Read-only property `isCustomEmojResource` (BOOL) indicates whether custom emoji config was loaded.
#### Scenario: Singleton initialization parses default plist
- **WHEN** `[NIMInputEmoticonManager shared]` is first accessed
- **THEN** it loads the emoji plist, creates `NIMInputEmoticonCatalog` objects with their `emoticons`, `id2Emoticons`, and `tag2Emoticons` dictionaries populated
#### Scenario: Set custom emoji config
- **WHEN** `setCustomEmojConfig:` is called with an NSArray of dictionaries (each with "info" and "data" keys)
- **THEN** existing catalogs are replaced with catalogs parsed from the provided array, and `isCustomEmojResource` returns YES
#### Scenario: Lookup catalog by catalogID
- **WHEN** `emoticonCatalogWithCatalogID:` is called with a valid catalog ID string
- **THEN** the matching `NIMInputEmoticonCatalog` is returned, or nil if not found
#### Scenario: Lookup emoticon by tag across all catalogs
- **WHEN** `emoticonByTag:` is called with a non-empty tag string (e.g. "[微笑]")
- **THEN** it iterates all catalogs' `tag2Emoticons` and returns the first matching `NIMInputEmoticon`, or nil
#### Scenario: Lookup emoticon by emoticonID across all catalogs
- **WHEN** `emoticonByID:` is called with a non-empty emoticon ID string
- **THEN** it iterates all catalogs' `id2Emoticons` and returns the first matching `NIMInputEmoticon`, or nil
#### Scenario: Lookup emoticon by catalogID + emoticonID
- **WHEN** `emoticonByCatalogID:emoticonID:` is called with both non-empty strings
- **THEN** it finds the catalog matching `catalogID`, then looks up the emoticon by `emoticonID` within that catalog's `id2Emoticons`

---

### Requirement: NIMInputEmoticonDefine Constants
Public constants defining emoji layout dimensions and paths: `NIMKit_EmojiCatalog` ("default"), `NIMKit_EmojiPath` ("Emoji"), `NIMKit_EmojiLeftMargin` (8), `NIMKit_EmojiRightMargin` (8), `NIMKit_EmojiTopMargin` (14), `NIMKit_DeleteIconWidth` (43.0), `NIMKit_DeleteIconHeight` (43.0), `NIMKit_EmojCellHeight` (46.0), `NIMKit_EmojImageHeight` (43.0), `NIMKit_EmojImageWidth` (43.0), `NIMKit_EmojRows` (3), plus chartlet-related path constants and pic-size constants.
#### Scenario: Constants available at compile time
- **WHEN** any emoji UI class references these constants
- **THEN** the correct integer/float values are used for layout calculations

---

### Requirement: NIMInputEmoticonButton
Open class `NIMInputEmoticonButton` (subclass of UIButton) displaying a single emoticon. Properties: `emotionData` (NIMInputEmoticon*), `catalogID` (NSString*), `delegate` (weak, id<NIMInputEmoticonButtonDelegate>). Factory method `+iconButtonWithData:catalogID:delegate:` creates and configures the button.
#### Scenario: Factory creates unicode emoji button
- **WHEN** `iconButtonWithData:catalogID:delegate:` is called with an emoticon whose type is `.unicode`
- **THEN** the button title is set to the unicode string, font is 32pt, and the button is configured with target-action for `touchUpInside`
#### Scenario: Factory creates file-based emoji button
- **WHEN** the emoticon type is `.file`
- **THEN** the button image is loaded via `UIImage.ne_bundleImage(name:)` using `fileName`, and set for both normal and highlighted states
#### Scenario: Tapping button notifies delegate
- **WHEN** the button is tapped
- **THEN** `delegate.selectedEmoticon:catalogID:` is called with the button's `emotionData` and `catalogID`

---

### Requirement: NIMInputEmoticonButtonDelegate Protocol
ObjC protocol `NIMInputEmoticonButtonDelegate` (inherits NSObjectProtocol) with required method `selectedEmoticon:catalogID:` receiving the selected `NIMInputEmoticon` and the catalog ID string.
#### Scenario: Delegate receives selection
- **WHEN** an emoticon button is tapped
- **THEN** the delegate method `selectedEmoticon:catalogID:` is invoked with the emoticon data and catalog ID

---

### Requirement: NEEmotionAttachment
Open class `NEEmotionAttachment` (subclass of NSTextAttachment) wrapping an `NIMInputEmoticon` for display in attributed strings. Property `emotion` (NIMInputEmoticon*): when set, loads the image from bundle (if default resource) or from `+imageNamed:` (if custom resource), based on `NIMInputEmoticonManager.shared.isCustomEmojResource`.
#### Scenario: Default resource loads from bundle
- **WHEN** `emotion` is set and `isCustomEmojResource` is NO
- **THEN** `image` is loaded via `UIImage.ne_bundleImage(name:)` using `emotion.fileName`
#### Scenario: Custom resource loads from main bundle
- **WHEN** `emotion` is set and `isCustomEmojResource` is YES
- **THEN** `image` is loaded via `[UIImage imageNamed:]` using `emotion.fileName`

---

### Requirement: NEEmotionTool Utility
Open class `NEEmotionTool` (subclass of NSObject) with class methods for emoji text processing.
#### Scenario: Get regex matches for emoji tags
- **WHEN** `+getRegularArrayWithStr:` is called with a string containing bracket-enclosed tags like "[微笑]"
- **THEN** it returns an array of `NSTextCheckingResult` for all matches of regex `\[[^\[|^\]]+\]`
#### Scenario: Convert text with emoji tags to attributed string
- **WHEN** `+getAttWithStr:font:color:offset:` is called with a string containing emoji tags
- **THEN** each tag matching an emoticon in the default catalog is replaced with an `NEEmotionAttachment` (NSTextAttachment) sized to the font's lineHeight, and the result is a `NSMutableAttributedString` with font and color attributes
#### Scenario: Convert attributed string with attachments back to text
- **WHEN** `+getTextWithAtt:range:` is called with an attributed string containing `NEEmotionAttachment` instances
- **THEN** each attachment is replaced with its `emotion.tag` string, and other ranges retain their text content

---

### Requirement: EmojiPageView
Open class `EmojiPageView` (subclass of UIView) providing horizontal paging scroll for emoji pages. Properties: `dataSource` (weak, id<EmojiPageViewDataSource>), `pageViewDelegate` (weak, id<EmojiPageViewDelegate>). Contains a UIScrollView with paging enabled.
#### Scenario: Reload data from dataSource
- **WHEN** `reloadData` is called
- **THEN** it queries `dataSource.numberOfPages:` for total page count, then requests each page view via `dataSource.pageView:index:`, positions them in the scroll view with frame offsets
#### Scenario: Scroll to specific page
- **WHEN** `scrollToPage:` is called with a page index
- **THEN** the scroll view scrolls to show that page and `reloadData` is triggered
#### Scenario: Scroll end notifies delegate
- **WHEN** the user finishes scrolling (deceleration ends)
- **THEN** `pageViewDelegate.pageViewScrollEnd:currentIndex:totolPages:` is called with the current page and total pages
#### Scenario: Frame width change triggers reload
- **WHEN** the view's `frame` is set with a different width
- **THEN** `reloadData` is called to recalculate layout

---

### Requirement: EmojiPageViewDataSource Protocol
ObjC protocol `EmojiPageViewDataSource` (inherits NSObjectProtocol) with optional methods: `numberOfPages:` returning NSInteger, `pageView:index:` returning a UIView for a given page index.
#### Scenario: DataSource provides pages
- **WHEN** `EmojiPageView` calls `numberOfPages:` and `pageView:index:`
- **THEN** the data source returns the total page count and a configured UIView for each page index

---

### Requirement: EmojiPageViewDelegate Protocol
ObjC protocol `EmojiPageViewDelegate` (inherits NSObjectProtocol) with optional methods: `pageViewScrollEnd:currentIndex:totolPages:`, `pageViewDidScroll:`, `needScrollAnimation` returning BOOL.
#### Scenario: Delegate notified on scroll events
- **WHEN** the page view scrolls or finishes scrolling
- **THEN** the corresponding delegate methods are invoked

---

### Requirement: InputEmoticonContainerView
Open class `InputEmoticonContainerView` (subclass of UIView) assembling the full emoji input panel. Contains an `EmojiPageView` (top, height 159) and an `InputEmoticonTabView` (bottom, height 35). Property `delegate` (weak, id<InputEmoticonContainerViewDelegate>). On init, loads the default emoji catalog, computes pages, and configures the page view.
#### Scenario: Initialization loads default emoji catalog
- **WHEN** the view is initialized with a frame
- **THEN** it loads the default catalog from `NIMInputEmoticonManager`, creates an `NIMInputEmoticonLayout` based on view width, computes `pagesCount`, and displays the first page
#### Scenario: Emoji page view displays grid of emoticon buttons
- **WHEN** the page view requests a page
- **THEN** `NIMInputEmoticonButton` instances are laid out in a grid (rows × columns) with a delete button in the last position for emoji catalog pages
#### Scenario: Tapping an emoticon button notifies container delegate
- **WHEN** a unicode emoticon button is tapped
- **THEN** `delegate.selectedEmoticon:emotCatalogID:description:` is called with the emoticonID, catalogID, and the unicode string as description
#### Scenario: Tapping an emoticon button for file type
- **WHEN** a file-type emoticon button is tapped
- **THEN** `delegate.selectedEmoticon:emotCatalogID:description:` is called with the emoticonID, catalogID, and the tag string as description
#### Scenario: Tapping delete button
- **WHEN** the delete button is tapped
- **THEN** `delegate.selectedEmoticon:emotCatalogID:description:` is called with empty strings for all parameters (signals delete action)
#### Scenario: Tapping send button
- **WHEN** the send button in the tab view is tapped
- **THEN** `delegate.didPressSend:` is called

---

### Requirement: InputEmoticonContainerViewDelegate Protocol
ObjC protocol `InputEmoticonContainerViewDelegate` (inherits NSObjectProtocol) with required methods: `selectedEmoticon:emotCatalogID:description:` and `didPressSend:`.
#### Scenario: Delegate receives emoticon selection
- **WHEN** an emoticon is selected in the container
- **THEN** the delegate receives `selectedEmoticon:emotCatalogID:description:` with the selected emoticon's ID, catalog ID, and display string
#### Scenario: Delegate receives send action
- **WHEN** the send button is pressed
- **THEN** the delegate receives `didPressSend:` with the sender button

---

### Requirement: InputEmoticonTabView
Open class `InputEmoticonTabView` (subclass of UIControl) displaying catalog tabs and a send button. Property `delegate` (weak, id<InputEmoticonTabViewDelegate>). Has a `sendButton` (UIButton) with localized "send" title and theme color background.
#### Scenario: Load catalogs creates tab buttons
- **WHEN** `loadCatalogs:` is called with an array of `NIMInputEmoticonCatalog`
- **THEN** old tabs are removed, new UIButton tabs are created for each catalog, and separator views are added between them
#### Scenario: Select tab index
- **WHEN** `selectTabIndex:` is called with an index
- **THEN** the button at that index is set to selected state, all others deselected
#### Scenario: Tapping a tab notifies delegate
- **WHEN** a tab button is tapped
- **THEN** `delegate.tabView:didSelectTabIndex:` is called with the tapped index

---

### Requirement: InputEmoticonTabViewDelegate Protocol
ObjC protocol `InputEmoticonTabViewDelegate` (inherits NSObjectProtocol) with optional method `tabView:didSelectTabIndex:`.
#### Scenario: Delegate receives tab selection
- **WHEN** a tab is tapped in the tab view
- **THEN** the delegate method is invoked with the tab view and the selected index
