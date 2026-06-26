```markdown
# AI Cold Email Outreach Workflow

## Technical Architecture
This 19-node workflow automates the end-to-end process of lead generation and personalized outreach.

### Phase 1: Data Extraction
- **Trigger:** Scheduled fetch from Google Sheets.
- **Filtering:** Removes duplicates and previously contacted leads.

### Phase 2: AI Personalization
- **Scraping:** HTTP nodes to pull text from lead websites.
- **Cleaning:** Custom JavaScript (Code Node) to sanitize HTML text for the LLM.
- **Intelligence:** Gemini AI generates a personalized "ice-breaker" based on the website content.

### Phase 3: Delivery & Resilience
- **Messaging:** Gmail API sends the personalized email.
- **Error Handling:** Regex-based logic to categorize errors (Retry vs. Permanent) and update the Google Sheet status.
```