# Sentiment analysis redesign

## Purpose

The Year 1 project used NRC sentiment analysis as part of the same monolithic script that also handled topic modelling, category assignment, word clouds, and activity recommendation. The sentiment code was also duplicated.

Phase 2 keeps sentiment, but treats it as a **separate descriptive analysis**.

The question is narrower:

> Which NRC emotion and polarity words are present in each reflection, and how frequently do they occur relative to document length?

The sentiment layer does **not** decide a student's interest category, does not label LDA topics, and does not infer personality.

## Implementation

`R/06_sentiment.R` uses `syuzhet::get_nrc_sentiment()` to obtain the standard NRC dimensions:

- anger;
- anticipation;
- disgust;
- fear;
- joy;
- sadness;
- surprise;
- trust;
- negative;
- positive.

The module returns two main representations.

### Raw counts

For each reflection, the raw number of lexicon hits for each NRC dimension is preserved.

Raw counts are useful for auditing what the lexicon detected, but they should not be compared naively across documents of very different lengths.

### Length-normalised rates

The module therefore also reports emotion/polarity hits per 100 words by default.

This does not make the measure a validated psychological score. It simply makes descriptive comparison across differently sized documents less misleading than comparing raw counts alone.

## Descriptive summary

`summarise_nrc_sentiment()` reports:

- the highest-count core emotion;
- whether that highest emotion is unique, tied, or absent;
- positive count;
- negative count;
- a simple `positive - negative` polarity balance.

The label `dominant_emotion` means only **the NRC emotion with the most lexical hits in that text**. It must not be interpreted as the student's true emotional state.

## Why sentiment stays separate

The revised architecture is:

```text
reflection text
      |
      v
preprocessing / validated input
      |
      +--> interest classification --> evaluation
      |
      +--> optional corpus-level LDA topic discovery
      |
      +--> NRC sentiment description
```

These tasks answer different questions and use different assumptions.

A reflection can, for example, be classified as `Future Skills & Intelligence` while still containing fear, frustration, joy, or trust. Those sentiment words do not redefine the interest category.

## Important limitations

NRC analysis is lexicon-based. A word can be associated with one or more emotions without the surrounding sentence actually expressing that emotion in the intended way.

Important limitations include:

- negation and scope (for example, `not happy`) are not reliably resolved by simple lexical counting;
- sarcasm and irony are difficult to detect;
- context and word sense can change meaning;
- the current workflow is designed around English text;
- repeated words can increase counts without representing stronger emotion;
- multiple NRC dimensions may be triggered by the same word;
- a reflection is not a psychological assessment;
- sentiment output should not be used to diagnose mental state or personality.

## Testing

`tests/smoke_test_sentiment.R` checks that:

- all five synthetic reflections can be processed;
- all expected NRC columns are returned;
- normalised rates have the same document coverage as the raw counts;
- simple positive and negative probe sentences trigger the expected polarity direction;
- sentiment output does not contain interest-category predictions.

The smoke test verifies implementation behaviour only. It is not evidence that NRC sentiment scores are accurate measures of real student emotion.

## Relationship to the Year 1 project

This keeps one of the original project's useful ideas while changing the claim being made.

The improvement is not simply moving the same code into another file. It is a change in analytical responsibility:

```text
Year 1:
NRC output inside one large pipeline
        ↓
loosely connected to interpretation of the student

Phase 2:
NRC lexical description
        ↓
explicit counts + length-normalised rates
        ↓
clearly documented limits
        ↓
kept separate from category, topics, and recommendations
```
