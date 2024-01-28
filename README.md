# llm-api-scripts
Here are some scripts for interface with common LLM APIs in R

## OpenAI GPT-3.5 and GPT-4

You can get an API key on the [OpenAI platform website](https://platform.openai.com/docs/introduction).

The below shows code using the [{openai} R package](https://irudnyts.github.io/openai/). The model used below is GPT-3.5, but there are a [range of alternative models available](https://platform.openai.com/docs/models/gpt-4-and-gpt-4-turbo), including GPT-4 (for which you just need to set `model = "gpt-4"`. Their website also has more on the [system and user prompts](https://platform.openai.com/docs/guides/prompt-engineering/strategy-write-clear-instructions), which can be thought of as the overall goal/context (system) and specific task/question (user).

```
if(!require("openai")) install.packages("openai")
library(claudeR)

# Add API key to system environment
Sys.setenv(OPENAI_API_KEY = "insert_your_key")

# Run GPT
openai_api_key <- Sys.getenv("OPENAI_API_KEY")

system_prompt <- "insert_system_prompt"
user_prompt <- "insert_user_prompt"

llm_completion <- create_chat_completion(
                  model = "gpt-3.5-turbo", 
                  messages = list(list("role"="system","content" = system_prompt),
                                  list("role"="user","content" = user_prompt)
                  ),
                  temperature = 0.2, # level of randomness in response
                  openai_api_key = openai_api_key,
                  max_tokens = 1000 # number of tokens (and hence $) used
  )

llm_completion_content <- llm_completion$choices$message.content
```

**Important: for security reasons, it is not good practice to store API keys as text in script files, or any other file that may be (inadvertantly) shared with others**

After running the above code, you may want to export the output content as a formatted file, in which case markdown is often the neatest way to do this given GPT is good at handling the formatting:
```
if(!require("readr")) install.packages("readr")
library(readr)

write_lines(llm_completion_content,"llm_output.md"))

```


## Anthropic Claude

You can apply for API access to Claude on the [Anthropic website](https://www.anthropic.com/earlyaccess).

The below shows code using the [{claudeR} R package](https://github.com/yrvelez/claudeR).

```
if(!require("pak")) install.packages("pak")
pak::pak("yrvelez/claudeR")
library(claudeR)

# Add API key to system environment
Sys.setenv(ANTHROPIC_API_KEY = "insert_your_key")

# Run Claude
anthropic_key <- Sys.getenv("OPENAI_API_KEY")

llm_completion <- claudeR(
                      prompt = "What is the capital of France?",
                      model = "claude-2",
                      max_tokens = 100,
                      api_key = anthropic_key
)

```
