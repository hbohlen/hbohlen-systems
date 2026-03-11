## ADDED Requirements

### Requirement: fetch_content tool exists
The extension SHALL register a `fetch_content` tool that the LLM can call directly.

#### Scenario: Tool is registered
- **WHEN** pi loads the brave-search extension
- **THEN** the `fetch_content` tool is available in the tool list

### Requirement: fetch_content accepts urls parameter
The fetch_content tool SHALL accept a `urls` array parameter for URLs to fetch.

#### Scenario: URLs parameter provided
- **WHEN** LLM calls fetch_content with urls=["https://example.com"]
- **THEN** the tool fetches content from the provided URLs

### Requirement: fetch_content returns extracted content
The fetch_content tool SHALL return the extracted text content from each URL.

#### Scenario: Content is fetched
- **WHEN** fetch_content is called with valid URLs
- **THEN** the result includes an array with url, title, and content for each URL

### Requirement: fetch_content handles extraction failures gracefully
The fetch_content tool SHALL handle failed fetches without breaking the entire request.

#### Scenario: One URL fails
- **WHEN** fetch_content is called with multiple URLs and one fails
- **THEN** the result includes successful fetches
- **AND** failed URLs include an error message

### Requirement: fetch_content limits content size
The fetch_content tool SHALL limit the extracted content to prevent excessive token usage.

#### Scenario: Large page is fetched
- **WHEN** fetch_content fetches a very large page
- **THEN** the content is truncated to a reasonable size
- **AND** a note indicates the content was truncated
