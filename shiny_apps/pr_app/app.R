# - - - - - - - - - - - - - - - - - - - - - - - 
# Concept for PR review
# Author: Adam Kucharski
# - - - - - - - - - - - - - - - - - - - - - - -

# Load paths ------------------------------------------------------------------

library(shinyjs) 
library(dplyr)
library(stringr)
library(shinyWidgets)
library(openai)
library(readr)
library(waiter)
library(shinythemes)
library(lsa) 
library(markdown)

wait_screen1 <- tagList(
  spin_orbiter(), h4("Summarising comments and reviews...")
)


# Plotting and helper functions ------------------------------------------------------------------

# Load credentials
credential_load <- read.csv("data/credentials.csv")

Sys.setenv(GITHUB_PAT = credential_load$value2)

# App UI ------------------------------------------------------------------

ui <- fluidPage(
  title = "Summarise PR comments and reviews",
  collapsible = TRUE,
  windowTitle = "Summarise PR comments and reviews",
  theme = shinytheme("flatly"),
  
  # Load libraries
  useShinyjs(),
  useWaiter(),
  
  # Define some additional CSS tags if required.
  
  # AI interface ----------------------------------------------------------

  div(
    id = "package-explorer", 
    style = "width: 600px; max-width: 100%; margin: 0 auto;",

    # Text input
    div(
      id="question-box",
      class = "well",#style = "height: 300px;",
      div(class = "text-center",
      h4("What Epiverse PR would you like to summarise?"),
      textInput("question_text", label = NULL, placeholder = "Input full URL, e.g. https://github.com/epiverse-trace/simulist/pull/33"),
      
      actionButton("question_button","Summarise PR",class="btn-primary")
      )
    )
  ),

  # Output package
  hidden(
    div(id = "output-response1",style = "width: 600px; max-width: 100%; margin: 0 auto;",
            div(
              class = "well",
              #p(strong("Suggested functions:")),
              uiOutput("generated_answer")
            )
        )
  ),

  div(class = "text-center",
      br(),
      p(em("Output generated using the OpenAI API."))
  )
  # 

    
  
) # END UI

# App server ------------------------------------------------------------------

server <- function(input, output, session) {
  
  # Store text
  package_name <- reactiveVal("")
  package_text <- reactiveVal("")
  package_link <- reactiveVal("")
  

  # Output LLM completion
  observeEvent(input$question_button,{

    waiter_show(html = wait_screen1,color="#b7c9e2") #) #id="question-box",

    # Input link
    query_text <-  input$question_text

    # Extract 'x'
    x <- sub("https://github.com/epiverse-trace/(.*)/pull/.*", "\\1", query_text)
    
    # Extract 'y'
    y <- sub(".*pull/([^/]*)/?.*$", "\\1", query_text)

    # Define repo and PR number
    owner_repo <- paste0("epiverse-trace/",x)
    pull_number <- as.numeric(y)
    
    print(owner_repo)
    print(pull_number)
    
    # Fetch pull request comments
    pr_comments <- gh::gh(
      "GET /repos/:owner/:repo/pulls/:pull_number/comments",
      owner = strsplit(owner_repo, "/")[[1]][1],
      repo = strsplit(owner_repo, "/")[[1]][2],
      pull_number = pull_number
    )
    
    # Fetch review comments on the pull request
    pr_review_comments <- gh::gh(
      "GET /repos/:owner/:repo/pulls/:pull_number/reviews",
      owner = strsplit(owner_repo, "/")[[1]][1],
      repo = strsplit(owner_repo, "/")[[1]][2],
      pull_number = pull_number
    )
    
    # Extract comment text and author
    extract_comment_and_author <- function(comment) {
      sprintf("%s: %s", comment$user$login, comment$body)
    }
    
    # Extract comments and authors from pull request comments
    extracted_pr_comments <- sapply(pr_comments, extract_comment_and_author)
    extracted_pr_review_comments <- sapply(pr_review_comments, extract_comment_and_author)
    
    # Combine both types of comments
    all_comments <- list(extracted_pr_comments, extracted_pr_review_comments)
    
    # Combine all comments into string
    all_comments_string <- paste(all_comments, collapse = "\n")
    
    # Set up GPT prompt and run model
    user_prompt <- "Summarise the below GitHub pull request comments and reviews, and output in markdown format. 
Briefly explain who made suggestions, what the conclusion was, and any actions resulting."
    
    llm_completion <- create_chat_completion(
      model = "gpt-4", #gpt-3.5-turbo-0125
      messages = list(list("role"="user","content" = paste0(user_prompt,all_comments_string))
      ),
      temperature = 0.1, # level of randomness in response
      openai_api_key = credential_load$value1,
      max_tokens = 500 # number of tokens (and hence $) used
    )
    
    llm_completion_content <- llm_completion$choices$message.content
  
    
    output$generated_answer <- renderUI({
      HTML(markdownToHTML(text = llm_completion_content, fragment.only = TRUE))
    })
    
    shinyjs::show("output-response1")

    waiter_hide()
    
  })
  
  
} # END SERVER



# Compile app -------------------------------------------------------------

shinyApp(ui = ui, server = server)


