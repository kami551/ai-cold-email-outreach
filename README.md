
# AI-Driven Cold Email Outreach Automation

![n8n](https://img.shields.io/badge/n8n-Workflow-red) ![Gemini](https://img.shields.io/badge/AI-Gemini-blue) ![Git](https://img.shields.io/badge/Version-Control-black)

A professional 19-node automation designed to scrape lead websites, personalize outreach using LLMs, and manage delivery status with advanced error handling.

## 🚀 Key Features
- **Automated Lead Scraper:** Extracts content from target websites via HTTP request nodes.
- **AI Ice-Breakers:** Uses Gemini AI to write personalized intro lines based on scraped data.
- **Resilient Logic:** Implements custom JavaScript for regex-based error classification and automatic retries.
- **Live Tracking:** Syncs all outreach status updates to Google Sheets in real-time.

## 🛠️ Technical Stack
- **Engine:** n8n
- **AI:** Google Gemini (LLM)
- **Database:** Google Sheets API
- **Language:** JavaScript (for custom Code Nodes)
- **Version Control:** Git & GitHub

## 📂 Documentation
- [View Architecture Details](architecture.md)
- [Download Workflow JSON](workflow.json)
