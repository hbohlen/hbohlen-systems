## ADDED Requirements

### Requirement: search_web tool exists
The extension SHALL register a `search_web` tool that the LLM can call directly.

#### Scenario: Tool is registered
- **WHEN** pi loads the brave-search extension
- **THEN** the `search_web` tool is available in the tool list

### Requirement: search_web accepts query parameter
The search_web tool SHALL accept a `query` string parameter for the search term.

#### Scenario: Query parameter provided
- **WHEN** LLM calls search_web with query="search term"
- **THEN** the tool executes a search for "search term"

### Requirement: search_web returns results
The search_web tool SHALL return search results with title, url, and description.

#### Scenario: Search returns results
- **WHEN** search_web is called with a valid query
- **THEN** the result includes an array of results with fields: title, url, description
- **AND** the result includes a `total` count of results

### Requirement: search_web uses Brave Search API
The search_web tool SHALL use the Brave Search API for web search.

#### Scenario: API is called
- **WHEN** search_web executes a search
- **THEN** it calls https://api.search.brave.com/res/v1/web/search
- **AND** includes the X-Subscription-Token header with the API key

### Requirement: search_web handles API errors gracefully
The search_web tool SHALL return an error message in the tool result rather than throwing.

#### Scenario: API returns error
- **WHEN** Brave Search API returns an error response
- **THEN** the tool returns a structured error with message
- **AND** the agent can continue working

### Requirement: search_web supports count parameter
The search_web tool SHALL accept an optional `count` parameter to specify number of results.

#### Scenario: Count parameter provided
- **WHEN** LLM calls search_web with count=5
- **THEN** the API returns up to 5 results
