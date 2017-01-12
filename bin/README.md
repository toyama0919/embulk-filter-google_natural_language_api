# Google Natural Language Api filter plugin for Embulk

Google Natural Language Api filter plugin for Embulk.

## Overview

* **Plugin type**: filter

## Configuration

- **api**: api type. analyzeSentiment or analyzeEntities or analyzeSyntax. (string, required)
- **out_key_name_suffix**: out_key_name_suffix (string, required)
- **key_names**: key_names (array, required)
- **delay**: delay (integer, default: 0)
- **google_api_key**: google_api_key (string, default: ENV['GOOGLE_API_KEY'])
- **language**: language. default is auto detect. (string, default: nil)


## Example

```yaml
filters:
  - type: google_natural_language_api
    api: analyzeSentiment
    out_key_name_suffix: _parsed
    language: en
    key_names:
      - title
      - message
```


## Build

```
$ rake
```
