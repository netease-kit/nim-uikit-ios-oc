## ADDED Requirements

### Requirement: NEMarkdownElement Protocol
Base protocol for all Markdown elements. Declares: `regex` (NSString*, readonly property), `regularExpression` (returns NSRegularExpression*), `parse:` (takes NSMutableAttributedString*), `match:attributedString:` (takes NSTextCheckingResult* and NSMutableAttributedString*). Default `parse:` implementation iterates through all regex matches, calling `match:attributedString:` for each, adjusting location for length changes after each replacement.
#### Scenario: Default parse iterates all matches
- **WHEN** `parse:` is called on an attributed string
- **THEN** it repeatedly calls `regularExpression` to find the first match starting from `location`, invokes `match:attributedString:` for each match, and advances `location` by the match range length adjusted for any length changes
#### Scenario: Protocol requires regex property
- **WHEN** a class conforms to `NEMarkdownElement`
- **THEN** it must provide a `regex` string property

---

### Requirement: NEMarkdownStyle Protocol
Styling protocol declaring: `font` (UIFont*, optional), `color` (UIColor*, optional), `attributes` (NSDictionary<NSAttributedStringKey, id>*, computed). Default `attributes` implementation builds a dictionary containing `.font` and `.foregroundColor` keys only when the respective properties are non-nil.
#### Scenario: Attributes include font when set
- **WHEN** `font` is non-nil
- **THEN** `attributes` dictionary contains `NSFontAttributeName` key with the font value
#### Scenario: Attributes include color when set
- **WHEN** `color` is non-nil
- **THEN** `attributes` dictionary contains `NSForegroundColorAttributeName` key with the color value
#### Scenario: Attributes empty when both nil
- **WHEN** both `font` and `color` are nil
- **THEN** `attributes` returns an empty dictionary

---

### Requirement: NEMarkdownCommonElement Protocol
Protocol composing `NEMarkdownElement` and `NEMarkdownStyle`. Adds method `addAttributes:range:`. Default implementations: `regularExpression` creates NSRegularExpression with no options; `addAttributes:range:` applies the `attributes` dictionary to the range; `match:attributedString:` deletes trailing markdown (group 4), applies attributes to content (group 3), then deletes leading markdown (group 2).
#### Scenario: Match strips markdown delimiters and applies attributes
- **WHEN** `match:attributedString:` is called with a 4-group regex match
- **THEN** trailing delimiter (group 4) is deleted, attributes are applied to content (group 3), and leading delimiter (group 2) is deleted, leaving only styled content

---

### Requirement: NEMarkdownLevelElement Protocol
Protocol composing `NEMarkdownElement` and `NEMarkdownStyle` for multi-level elements (headers, lists, quotes). Declares: `maxLevel` (NSInteger), `formatText:range:level:`, `addAttributes:range:level:`, `attributesForLevel:`. Default: `regularExpression` uses `.anchorsMatchLines` option; `match:` extracts level from group(1) length, applies attributes to group(2), calls `formatText:` on the leading marker range.
#### Scenario: Level determined by group 1 length
- **WHEN** a match is found with group(1) having N characters
- **THEN** the level is N, and `addAttributes:range:level:` and `formatText:range:level:` are called with level=N
#### Scenario: Default attributesForLevel returns base attributes
- **WHEN** `attributesForLevel:` is called without override
- **THEN** it returns the base `attributes` from `NEMarkdownStyle`

---

### Requirement: NEMarkdownLinkElement Protocol
Protocol composing `NEMarkdownElement` and `NEMarkdownStyle` for link-type elements. Declares: `formatText:range:link:` and `addAttributes:range:link:`.
#### Scenario: Protocol provides link-specific formatting hooks
- **WHEN** a class conforms to `NEMarkdownLinkElement`
- **THEN** it must implement `formatText:range:link:` and `addAttributes:range:link:` to handle URL-specific formatting

---

### Requirement: NEMarkdownBold
Open class conforming to `NEMarkdownCommonElement`. Regex: `(.?|^)(\*\*|__)(?=\S)(.+?)(?<=\S)(\2)`. Matches text wrapped in `**` or `__`. On init, applies `.bold()` trait to the provided font.
#### Scenario: Bold text parsed
- **WHEN** input contains `**bold text**`
- **THEN** the delimiters are removed and the content "bold text" is styled with bold font
#### Scenario: Underscore bold parsed
- **WHEN** input contains `__bold text__`
- **THEN** the delimiters are removed and content is styled with bold font

---

### Requirement: NEMarkdownItalic
Open class conforming to `NEMarkdownCommonElement`. Regex: `(\s|^)(\*|_)(?![*_\s])(.+?)(?<![*_\s])(\2)`. Matches text wrapped in single `*` or `_`. On init, applies `.italic()` trait to the provided font.
#### Scenario: Italic text parsed
- **WHEN** input contains `*italic text*`
- **THEN** delimiters are removed and content is styled with italic font
#### Scenario: Underscore italic parsed
- **WHEN** input contains `_italic text_`
- **THEN** delimiters are removed and content is styled with italic font

---

### Requirement: NEMarkdownCode
Open class conforming to `NEMarkdownCommonElement`. Regex: `(.?|^)(\`{1,3})(.+?)(\2)`. Matches inline code wrapped in 1–3 backticks. Additional properties: `textHighlightColor`, `textBackgroundColor`. Overrides `addAttributes:range:` to unescape UTF-16, then apply code-specific foreground color, background color, and monospace font.
#### Scenario: Inline code parsed with single backtick
- **WHEN** input contains `` `code` ``
- **THEN** backtick delimiters are removed, content is unescaped from UTF-16 encoding, and styled with monospace font, highlight color, and background color
#### Scenario: Triple backtick code parsed
- **WHEN** input contains `` ```code block``` ``
- **THEN** the triple backtick delimiters are removed and content is styled as code

---

### Requirement: NEMarkdownStrikethrough
Open class conforming to `NEMarkdownCommonElement`. Regex: `(.?|^)(~~|__)(?=\S)(.+?)(?<=\S)(\2)`. Applies `NSStrikethroughStyleAttributeName` with `NSUnderlineStyleSingle` as a custom `attributes` override.
#### Scenario: Strikethrough text parsed
- **WHEN** input contains `~~strikethrough~~`
- **THEN** delimiters are removed and content is styled with strikethrough attribute

---

### Requirement: NEMarkdownHeader
Open class conforming to `NEMarkdownLevelElement`. Regex: `^(#{1,N})\s*(.+)$` (where N = maxLevel if >0, otherwise unlimited). Properties: `maxLevel` (NSInteger), `fontIncrease` (NSInteger, default 2). `attributesForLevel:` computes header font size as `font.pointSize + 4 - level * fontIncrease` and applies bold trait. `formatText:range:level:` deletes the `#` markers.
#### Scenario: H1 header parsed
- **WHEN** input contains `# Header`
- **THEN** the `#` marker and space are removed, "Header" is styled with bold font at size `baseSize + 4 - 1*fontIncrease`
#### Scenario: H3 header parsed
- **WHEN** input contains `### Header`
- **THEN** the `###` markers are removed, content is styled with smaller bold font (level 3)
#### Scenario: Max level limits parsing
- **WHEN** `maxLevel` is set to 3 and input contains `#### Header`
- **THEN** the header is not matched (exceeds maxLevel)

---

### Requirement: NEMarkdownList (Unordered)
Open class conforming to `NEMarkdownLevelElement`. Regex: `^( {0,N}[*+-])\s+(.+)$` (N = maxLevel). Properties: `maxLevel` (default 6), `indicator` (default "•"), `separator` (default "  "). `formatText:range:level:` replaces the marker with level-dependent bullet indicators ("•", "◦", "▪︎") and indentation, and applies paragraph style with `headIndent` = 16.
#### Scenario: Simple unordered list item
- **WHEN** input contains `- item`
- **THEN** the `- ` is replaced with `• ` (bullet indicator) and paragraph indent style is applied
#### Scenario: Nested list item (level 3)
- **WHEN** input contains `  - nested item` (2-space indent)
- **THEN** the marker is replaced with `  ◦  ` (open circle with offset) and deeper indent

---

### Requirement: NEMarkdownOrderedList
Open class conforming to `NEMarkdownLevelElement`. Regex: `^( {0,N})(\d+)\.\s+(.+)$`. Custom `match:` override: group(1) = leading spaces (level = length + 1), group(2) = number, group(3) = content. `formatText:` replaces leading spaces with indented `number. ` format and applies hanging indent paragraph style.
#### Scenario: Ordered list item
- **WHEN** input contains `1. First item`
- **THEN** the marker is replaced with `1. ` and paragraph style with firstLineHeadIndent and headIndent is applied
#### Scenario: Nested ordered list
- **WHEN** input contains `  1. Nested item` (2-space indent)
- **THEN** indentation depth increases and paragraph headIndent is adjusted accordingly

---

### Requirement: NEMarkdownQuote
Open class conforming to `NEMarkdownLevelElement`. Regex: `^(>{1,N})\s*(.+)$`. Properties: `maxLevel`, `indicator` (default ">"), `separator` (default "  "). `formatText:` replaces `>` markers with indented indicator characters.
#### Scenario: Single-level quote
- **WHEN** input contains `> quoted text`
- **THEN** the `>` marker is replaced with `  > ` (separator + indicator)
#### Scenario: Nested quote
- **WHEN** input contains `>> deeply quoted`
- **THEN** two levels of separator are prepended before the indicator

---

### Requirement: NEMarkdownLink
Open class conforming to `NEMarkdownLinkElement`. Regex: `\[[^\]]+\]\(\S+(?=\))\)`. Secondary regex for URL extraction: `\(\S+(?=\))\)`. `match:` extracts the URL, deletes trailing `](url)`, deletes leading `[`, then calls `formatText:range:link:` which adds `NSLinkAttributeName` with the parsed URL. `addAttributes:` applies the style attributes. Uses `.dotMatchesLineSeparators` regex option.
#### Scenario: Markdown link parsed
- **WHEN** input contains `[title](https://example.com)`
- **THEN** the markdown syntax is stripped, "title" is displayed with link attributes pointing to the URL
#### Scenario: URL percent-encoded if needed
- **WHEN** the URL contains special characters
- **THEN** the URL is percent-encoded before creating the NSURL

---

### Requirement: NEMarkdownAutomaticLink
Open class (subclass of `NEMarkdownLink`) that overrides `regularExpression` to use `NSDataDetector` with `NSTextCheckingTypeLink`. `match:` extracts the link text as-is (no markdown delimiters to strip), applies formatting and attributes.
#### Scenario: Bare URL auto-detected
- **WHEN** input contains `https://example.com` without markdown syntax
- **THEN** the URL text is detected and styled as a clickable link

---

### Requirement: NEMarkdownImage
Open class conforming to `NEMarkdownElement`. Regex: `!\[[^\[\]]*\]\(\s*"?(\S+?)"?(?:\s+"[^"]*")?\s*\)`. Properties: `maxWidth` (CGFloat, default 200), `maxHeight` (CGFloat, default 300), `placeholderSize` (CGSize, 120×80). `match:` extracts the URL from capture group 1, creates `NEMarkdownImageAttachment` with placeholder, replaces the markdown syntax with the attachment, and starts async download.
#### Scenario: Image markdown parsed with placeholder
- **WHEN** input contains `![alt](https://example.com/image.png)`
- **THEN** the syntax is replaced with an `NSTextAttachment` showing a gray placeholder image
#### Scenario: Image download completes
- **WHEN** the async download finishes successfully
- **THEN** the attachment's image is updated to the downloaded image (constrained to maxWidth/maxHeight), and `NEMarkdownImageDidLoadNotification` is posted with "url" and "image" in userInfo
#### Scenario: Image cache hit
- **WHEN** the same URL has been previously downloaded
- **THEN** the cached image is applied synchronously without posting a notification

---

### Requirement: NEMarkdownImageAttachment
Open class (subclass of NSTextAttachment). Properties: `imageURL` (NSString*, readonly), `maxWidth` (CGFloat, readonly), `maxHeight` (CGFloat, readonly), `placeholderSize` (CGSize, readonly), `isLoaded` (BOOL, readonly). Maintains a static `NSCache` for image caching. Overrides `attachmentBoundsForTextContainer:` to return the display size. `startDownload` checks cache first, then uses `NSURLSession` for async download.
#### Scenario: Bounds reflect display size
- **WHEN** `attachmentBoundsForTextContainer:proposedLineFragment:glyphPosition:characterIndex:` is called
- **THEN** it returns a CGRect with the current displaySize (placeholder before download, constrained image size after)
#### Scenario: constrainSize preserves aspect ratio
- **WHEN** `+constrainSize:maxWidth:maxHeight:` is called with an image larger than limits
- **THEN** it scales proportionally, first constraining width then height, and returns ceiled dimensions

---

### Requirement: NEMarkdownHorizontalRule
Open class conforming to `NEMarkdownElement`. Regex: `^[ \t]*([\\-\\*\\_][ \t]*){3,}[ \t]*$` with `.anchorsMatchLines` option. Properties: `lineColor` (UIColor), `lineHeight` (CGFloat, default 1.0), `verticalPadding` (CGFloat, default 6.0). `match:` replaces the separator line with a custom `NSTextAttachment` that dynamically sizes itself to the line width.
#### Scenario: Horizontal rule parsed
- **WHEN** input contains `---` on its own line
- **THEN** the text is replaced with an NSTextAttachment that renders a horizontal line
#### Scenario: Asterisk horizontal rule
- **WHEN** input contains `***` or `* * *`
- **THEN** it is also recognized and replaced with a horizontal line attachment
#### Scenario: Attachment auto-sizes to container width
- **WHEN** the attachment's `attachmentBoundsForTextContainer:proposedLineFragment:` is called
- **THEN** the width matches the proposedLineFragment width, height is `lineHeight + 2 * verticalPadding`

---

### Requirement: NEMarkdownTable
Open class conforming to `NEMarkdownElement`. The `regex` property returns a never-matching pattern (`(?!x)x`) since table parsing uses a custom `preprocess:font:color:` method called before other elements. Properties: `maxWidth` (CGFloat), `headerFont` (UIFont), `cellFont` (UIFont), `cellPadding` (CGFloat, default 8), `borderWidth` (CGFloat, default 0.5).
#### Scenario: GFM table parsed via preprocess
- **WHEN** `preprocess:font:color:` is called with markdown containing a separator line (e.g. `|---|---|`)
- **THEN** the table block (header row + separator + data rows) is replaced with an `NSTextAttachment` containing a `NEMarkdownTableView`, and non-table text is preserved
#### Scenario: Separator line detection
- **WHEN** a line starts with `|`, contains `-`, and consists only of `|`, `:`, `-`, spaces, and tabs
- **THEN** it is recognized as a GFM separator line (the anchor for table detection)
#### Scenario: Table without explicit header
- **WHEN** a separator line has no preceding `|`-prefixed line
- **THEN** default column headers ("列1", "列2", etc.) are generated
#### Scenario: Mixed-line header extraction
- **WHEN** the line before the separator contains `|` but doesn't start with `|` (e.g. `## Title | Col1 | Col2 |`)
- **THEN** trailing table cells are extracted from the mixed line as headers, and the text before the first `|` is preserved as regular content
#### Scenario: Column alignment parsed
- **WHEN** separator cells contain `:---` (left), `:---:` (center), or `---:` (right)
- **THEN** `NEMarkdownTableAlignment` values are set accordingly for each column

---

### Requirement: NEMarkdownTableData Model
Struct with properties: `headers` (NSArray<NSString*>*), `alignments` (NSArray of NEMarkdownTableAlignment enum values), `rows` (NSArray<NSArray<NSString*>*>*), computed `columnCount` (NSInteger, equals headers.count).
#### Scenario: Column count derived from headers
- **WHEN** a `NEMarkdownTableData` is created with 3 headers
- **THEN** `columnCount` returns 3

---

### Requirement: NEMarkdownTableAlignment Enum
Enum with cases: `left`, `center`, `right`.
#### Scenario: Alignment values
- **WHEN** alignment is parsed from separator line
- **THEN** `:---` maps to `.left`, `:---:` maps to `.center`, `---:` maps to `.right`

---

### Requirement: NEMarkdownTableView
Open class (subclass of UIView) rendering a `NEMarkdownTableData` as a grid. Style properties: `maxWidth`, `headerBackgroundColor`, `oddRowBackgroundColor`, `evenRowBackgroundColor`, `borderColor`, `borderWidth`, `cellPadding`, `headerFont`, `cellFont`, `headerTextColor`, `cellTextColor`. Layout: equal-width columns (min 60pt), auto-height rows based on text wrapping. Static method `+calculateHeight:maxWidth:headerFont:cellFont:cellPadding:borderWidth:` pre-computes total height.
#### Scenario: Table rendered with header and data rows
- **WHEN** initialized with a `NEMarkdownTableData` containing headers and rows
- **THEN** the table view renders a header row (with `headerBackgroundColor` and `headerFont`) followed by data rows with alternating background colors
#### Scenario: Static height calculation
- **WHEN** `+calculateHeight:` is called
- **THEN** it returns the total height based on text bounding-rect calculations for all rows at the given column width
#### Scenario: Cells align to column alignment
- **WHEN** a column has `.center` alignment
- **THEN** the UILabel for that column has `NSTextAlignmentCenter`

---

### Requirement: NEMarkdownTableAttachment
Subclass of NSTextAttachment holding a reference to a `NEMarkdownTableView` and a fixed size. Used as the text attachment embedded in the attributed string to represent a table block.
#### Scenario: Attachment embeds table view
- **WHEN** the attachment is created with a `NEMarkdownTableView` and a size
- **THEN** the attachment's bounds match the given size and the table view is accessible for rendering

---

### Requirement: NEMarkdownCodeEscaping
Open class conforming to `NEMarkdownElement`. Regex handles two branches: multi-backtick (2+) allowing cross-line content via `[\s\S]+?`, and single-backtick restricting to `[^\n`]+`. `match:` identifies the content group (group 3 for multi-backtick, group 6 for single) and escapes all characters to 4-digit hex UTF-16 representation.
#### Scenario: Code content escaped before other elements
- **WHEN** text within backticks is processed by `NEMarkdownCodeEscaping`
- **THEN** each character in the code content is replaced with its 4-hex-digit UTF-16 representation, preventing subsequent markdown elements from matching inside code blocks

---

### Requirement: NEMarkdownEscaping
Open class conforming to `NEMarkdownElement`. Regex: `\\.` (backslash followed by any character). Uses `.dotMatchesLineSeparators` option. `match:` replaces the escaped character at `match.location + 1` with its 4-hex-digit UTF-16 representation.
#### Scenario: Backslash escaping processed
- **WHEN** input contains `\*` (escaped asterisk)
- **THEN** the backslash and character are replaced with the hex-encoded character, preventing markdown interpretation

---

### Requirement: NEMarkdownUnescaping
Open class conforming to `NEMarkdownElement`. Reverses the hex encoding applied by escaping elements, converting 4-hex-digit sequences back to their original UTF-16 characters.
#### Scenario: Escaped characters restored
- **WHEN** the unescaping element processes the attributed string after all other elements
- **THEN** hex-encoded sequences are converted back to their original characters

---

### Requirement: NEMarkdownParser
Open class providing the main parser entry point. Nested `NEEnabledElements` OptionSet with flags: `.automaticLink`, `.header`, `.list`, `.quote`, `.link`, `.bold`, `.italic`, `.code`, `.strikethrough`, `.table`, `.orderedList`, `.horizontalRule`, `.image`. Compound sets: `.disabledAutomaticLink` (all except automaticLink), `.all` (everything). Properties: `font` (UIFont), `color` (UIColor), `enabledElements` (NEEnabledElements), `customElements` (NSMutableArray<NEMarkdownElement>*). Holds instances of all element types.
#### Scenario: Parse markdown string
- **WHEN** `parse:` is called with a markdown string
- **THEN** it first runs table preprocessing (if enabled), then applies base font/color attributes, then processes escaping elements → default elements (in priority order: image, horizontalRule, table, automaticLink, header, list, orderedList, quote, link, bold, italic, code, strikethrough) → custom elements → unescaping elements, and returns the final NSAttributedString
#### Scenario: Table preprocessing before other elements
- **WHEN** table element is enabled
- **THEN** `table.preprocess:font:color:` is called on the raw text before escaping/default elements run, so `|` characters inside tables are not escaped
#### Scenario: Enabled elements filter
- **WHEN** `enabledElements` is changed
- **THEN** only the enabled element types are included in the default processing pipeline
#### Scenario: Custom element extension
- **WHEN** `addCustomElement:` is called with a custom NEMarkdownElement
- **THEN** it is appended to `customElements` and processed after default elements but before unescaping
#### Scenario: Remove custom element
- **WHEN** `removeCustomElement:` is called
- **THEN** the element is removed from the `customElements` array by identity comparison
#### Scenario: Element processing order
- **WHEN** parsing runs
- **THEN** the order is: escapingElements (codeEscaping, escaping) → defaultElements (image first, then horizontalRule, table, automaticLink, header, list, orderedList, quote, link, bold, italic, code, strikethrough) → customElements → unescapingElements (code, unescaping)

---

### Requirement: String+UTF16 Extension
Extension on NSString providing `unescapeUTF16` method to convert hex-encoded UTF-16 sequences back to their original characters.
#### Scenario: Hex sequences converted back
- **WHEN** `unescapeUTF16` is called on a string containing 4-hex-digit sequences
- **THEN** each sequence is converted back to the corresponding Unicode character

---

### Requirement: UIFont+Traits Extension
Extension on UIFont providing `bold()` and `italic()` convenience methods that return a new font with the respective symbolic trait applied.
#### Scenario: Bold trait applied
- **WHEN** `bold` is called on a UIFont
- **THEN** a new font with `UIFontDescriptorTraitBold` is returned at the same point size
#### Scenario: Italic trait applied
- **WHEN** `italic` is called on a UIFont
- **THEN** a new font with `UIFontDescriptorTraitItalic` is returned at the same point size
