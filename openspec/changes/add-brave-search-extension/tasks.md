## 1. Extension Setup

- [x] 1.1 Create directory ~/.pi/agent/extensions/brave-search/
- [x] 1.2 Create index.ts with basic extension structure
- [x] 1.3 Verify extension loads in pi (/reload)

## 2. Brave Search API Integration

- [x] 2.1 Create types.ts with TypeScript interfaces for Brave API
- [x] 2.2 Create brave-search.ts with API wrapper function
- [x] 2.3 Implement API key retrieval from 1Password
- [x] 2.4 Test API connection with actual Brave Search API call
- [x] 2.5 Handle API errors gracefully

## 3. search_web Tool Implementation

- [x] 3.1 Register search_web tool in index.ts
- [x] 3.2 Define tool parameters using Typebox (query, count, offset)
- [x] 3.3 Implement tool execute function with Brave API call
- [x] 3.4 Format tool result with compact JSON (title, url, description)
- [x] 3.5 Test tool with sample searches

## 4. fetch_content Tool Implementation

- [x] 4.1 Create content-fetcher.ts with URL fetching logic
- [x] 4.2 Register fetch_content tool in index.ts
- [x] 4.3 Define tool parameters using Typebox (urls array)
- [x] 4.4 Implement HTML content extraction
- [x] 4.5 Handle extraction errors and failures gracefully
- [x] 4.6 Add content size limiting for token efficiency

## 5. Integration Testing

- [x] 5.1 Test search_web in pi with real queries
- [x] 5.2 Test fetch_content with various URLs
- [x] 5.3 Test error handling (invalid URL, API errors)
- [x] 5.4 Verify tool results are token-efficient

## 6. Documentation

- [x] 6.1 Add extension documentation in index.ts comments
- [x] 6.2 Document 1Password key location and setup
- [x] 6.3 Create README.md with usage examples

## 7. Future Enhancements (Out of Scope for Initial Release)

- [ ] 7.1 Research gap analysis tool
- [ ] 7.2 Bead integration for research tasks
- [ ] 7.3 Search result caching
- [ ] 7.4 Brave AI summary integration
