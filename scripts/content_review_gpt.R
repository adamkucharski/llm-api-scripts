library(gh)
library(openai)
library(readr)

# Set credentials
# Sys.setenv(GITHUB_PAT = "GITHUB_PAT")
# Sys.setenv(OPENAI_API_KEY = "insert_your_key")

# Set local directory for outputs
# setwd("~/Documents/GitHub/llm-api-scripts/")

openai_api_key <- Sys.getenv("OPENAI_API_KEY")

# Set GitHub repository and path
owner_repo <- "epiverse-trace/tutorials-middle" #"tutorials"
path <- "episodes" #"episodes"

# Load personas
persona_vania_academic <- read_file("https://raw.githubusercontent.com/epiverse-trace/personas/master/vania-academica.qmd")
persona_lucia_field_epi <- read_file("https://raw.githubusercontent.com/epiverse-trace/personas/master/lucia-outbreaks.qmd")
persona_patricia_phd <- read_file("https://raw.githubusercontent.com/epiverse-trace/personas/master/patricia-discoverer.qmd")

persona_names <- c("vania_academic","lucia_field_epi","patricia_phd")
persona_bio_list <- c(persona_vania_academic,persona_lucia_field_epi,persona_patricia_phd)

# Load prompts

# Download files ----------------------------------------------------------

# Get the list of .Rmd files from a GitHub repo directory
get_rmd_files <- function(owner_repo, path) {
  # GitHub API endpoint
  contents <- gh::gh("/repos/:owner/:repo/contents/:path", 
                     owner = strsplit(owner_repo, "/")[[1]][1], 
                     repo = strsplit(owner_repo, "/")[[1]][2], 
                     path = path)
  
  # Filter for .Rmd files
  rmd_files <- Filter(function(x) grepl("\\.Rmd$", x$name), contents)
  
  # Return a list of Rmd file names and their download URLs
  list(
    names = sapply(rmd_files, `[[`, "name"),
    download_urls = sapply(rmd_files, `[[`, "download_url")
  )
}

# Function to download .Rmd file content
download_rmd_content <- function(download_urls) {
  sapply(download_urls, function(url) {
    read_file(url)
  })
}


# Get list of .Rmd files
rmd_files_info <- get_rmd_files(owner_repo, path)

# Download .Rmd file contents
rmd_contents <- download_rmd_content(rmd_files_info$download_urls)


# Run GPT review ----------------------------------------------------------

# Set up GPT prompt and run model
user_prompt_1 <- "You are the following person:"
user_prompt_2 <- read_file("prompts/review_prompt.txt")

# Loop over personas and tutorials
for(ii in 1:length(rmd_contents)){
for (kk in 1:length(persona_names)){
  
  # Create directory if needed
  file_path <- paste0("outputs/",owner_repo,"/")
  if(!dir.exists(file_path)){dir.create(file_path)}
  
  # Define loop variables
  tutorial_name <- sub("\\.Rmd$", "",rmd_files_info$names[ii])
  tutorial_contents <- rmd_contents[ii]
  
  persona_name <- persona_names[kk]
  persona_bio <- persona_bio_list[kk]
  
  # OpenAI GPT call
  llm_completion <- create_chat_completion(
    model = "gpt-4", #gpt-3.5-turbo-0125
    messages = list(list("role"="user","content" = paste0(user_prompt_1,persona_bio,
                                                          user_prompt_2,tutorial_contents))
    ),
    temperature = 0.2, # level of randomness in response
    openai_api_key = openai_api_key,
    max_tokens = 800 # number of tokens (and hence $) used
  )
  
  llm_completion_content <- llm_completion$choices$message.content
  
  # Write markdown file
  write_lines(llm_completion_content,paste0(file_path,"review_",tutorial_name,"_persona_",persona_name,".md"))

}
}





