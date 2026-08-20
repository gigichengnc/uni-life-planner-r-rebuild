# Tests

Planned checks for the corrected implementation:

- preprocessing removes expected stopwords/punctuation;
- empty text is handled safely;
- category scoring is deterministic;
- unknown/weakly matched text can return `uncertain`;
- recommendation matching does not return unrelated activities because of one generic word;
- plotting functions can write files to `output/` without changing analytical results.
