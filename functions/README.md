# AIDHD Gemini Function

This function keeps the Gemini API key on the server. The Flutter app calls it through Firebase Callable Functions after Firebase Auth signs the user in.

## One-time setup

From the repository root:

```powershell
firebase login
firebase use aidhd-a35b9
firebase functions:secrets:set GEMINI_API_KEY
firebase deploy --only functions:chatWithGemini
```

When prompted, paste the Gemini API key directly into the terminal. Do not commit it, put it in Flutter code, or put it in a `.env` file tracked by Git.

The Google Cloud project may require billing to deploy and run Cloud Functions. The callable function rejects unauthenticated requests and keeps the ADHD safety prompt on the server.
