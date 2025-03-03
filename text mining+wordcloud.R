#########################################################################################
################################## Text Pre-Processing ##################################
#########################################################################################

# In the code below, we will go through the typical steps to pre-process/ clean text
# These are just guidelines. Depending on what text is used an input, there might be a need to
    # make slight changes to these pre-processing functions
# These are the thechniques covered in this notebook:
    # 1. Bring to lower case
    # 2. Remove numbers
    # 3. Remove stopwords 
    # 4. Remove punctuation 
    # 5. Remove/ change certain words
    # 6. Remove white space
    # 7. Lemmatization / Stemming
# Other techniques could be applied to text as well. For example, if you work with social media data,
    # you might want to remove tags and URLs from text. 
# After cleaning the data, let's transform it to:
    # DTM = Document Term Matrix
    # TDM = Term Document Matrix
    # Tf-Idf = Term Frequency-Inverse Document Frequency 


##############################
######## load packages #######
##############################
# if the packages below are not installed, then uncomment the install.packages() lines and run them
#install.packages("dplR")
#install.packages("tm")
#install.packages("textstem")
library(dplyr) # dplyr package is used for data manipulation; it uses pipes: %>%
library(tm) # contains the stopwords dictionary
library(textstem) # used for stemming and lemmatization
library(tidytext)
library(dplyr)
install.packages("wordcloud")
if (!require(devtools))  install.packages("devtools")
devtools::install_github('lchiffon/wordcloud2')
library(wordcloud2)
library(wordcloud) 


##############################
##### read the data in R #####
##############################
# it's good practice to set up the working directory
# all the files youo read in R or write from R will be in the working directory you set up
# if you copy the path of your file from the foler, change all the \ to /
scripts <- read.csv("NJD_word_frequency.csv")


##############################
### check the type of data ###
##############################
str(scripts)
head(scripts)


# For each cleaning task, let's create a new column to see the before and after


###############################
##### bring to lower case #####
###############################
# Text normalization allows words like "Something" and "something" be treated in the same way.
# You would usually transform all the words to lower case. 
# However, there might be times you don't wish to do so. 
# Ex: "US" and "us" mean different things and should remain as they are.
scripts <- scripts %>% mutate(Narrative_lower = tolower(CONTENT_TEXT)) # mutate() function is from the dplyr package and it is used to create a new column
head(scripts)

###############################
####### remove numbers ########
###############################
# this function looks for any number in the text and then removes it
# if desired to replace the numbers with a space, add a space inside the quotes: ' ' instead of ''
# [[:digit:]] is a regex expresion. Read more here: https://rstudio.com/wp-content/uploads/2016/09/RegExCheatsheet.pdf
scripts <- scripts %>% mutate(Narrative_noNumbers = gsub('[[:digit:]]','',Narrative_lower)) # gsub functoin searches for any digit in the text and removes it; 
head(scripts)


###############################
###### remove stopwords #######
###############################
# Stop words are the words that appear the most in the English vocabulary ("a", "the", "for).
# These don't provide important meaning and are therefore removed.
# R already provides packages that contain a collection of stopwords
# English stopwords
stopwords('en')
# Check the structure of the stopwords dictionary
str(stopwords('en')) # it is a vector in character format
# Subset the stopwords
stopwords('en')[1:152]
# remove certain stopwords
stopwords('en')[!stopwords('en') %in% c('i')]  # notice that the first stopword, i, was removed
    # stopwords('en') %in% c('i') ---> this gives back a vector with TRUE and FALSE
    # ! ---> this gives negation
# Add new stopwords
stopwords<- c(stopwords('en'), "under","potter","harry")  # notice that the stopwords have a new element: under
# Remove the stopwords from text; If you wish to modify the stopwords dictionary by adding/ removing any, then use code from above
stopwords_regex = paste(stopwords, collapse = '\\b|\\b')
scripts <- scripts %>% mutate(Narrative_noStopWords = gsub(stopwords_regex,'',Narrative_noNumbers))
head(scripts)

###############################
##### remove punctuation ######
###############################
# Punctuation (.,!?:;), symbols (*^&) are removed, unless there is a reason to keep them
scripts <- scripts %>% mutate(Narrative_noPunctuation = gsub('[[:punct:]]','',Narrative_noStopWords))
head(scripts)


################################
# remove/ change certain words #
################################
# Replace words that have typos with the correct words. If synonyms are present, these can be replaced as well.
# Example of fixing a typo
scripts <-scripts %>% mutate(Narrative_noTypos = gsub('thankssssssss','thanks',Narrative_noPunctuation))
head(scripts)




################################
###### remove whitespace #######
################################
# Remove extra white space (this would include space, tab, vertical tab, newline, form feed, carriage return):
scripts <- scripts %>% mutate(Narrative_noSpaces = gsub('\\s+',' ',Narrative_noTypos))
head(scripts)



# Stemming and Lemmatization are techniques to reduce the number of terms based on grammatical inflections.
  # Stemming removes the end of a words to bring the words to a common base form.
  # Lemmatization removes a word's suffix to reduce the size of the vocabulary while bringing it to its root form.
  # When doing text minening, you would use either stemming either lemmatization

################################
########### stemming ###########
################################
scripts <-scripts %>% mutate(Narrative_Stem = stem_strings(Narrative_noSpaces))
head(scripts)

################################
######## lemmatization #########
################################
scripts <-scripts %>% mutate(Narrative_Lemma = lemmatize_strings(Narrative_noSpaces))
head(scripts)


# We'll use lemmatization going forwards

# keep just the text column
my_text <- scripts %>% select(Narrative_Lemma)
head(my_text)



################################
########## create DTM ##########
################################
# To create a DTM, we need to change the data frame to a corpus. First, we need to have a data frame whose column names are doc_id and text.
# doc_id represents the document/ line of text;
# text represents the content; this is what will be used to create the DTM
# https://www.rdocumentation.org/packages/tm/versions/0.7-6/topics/DataframeSource
my_corpus <- my_text
my_corpus <- my_corpus %>% rename(text = Narrative_Lemma)  %>% mutate(doc_id = rownames(my_text))
my_corpus <- Corpus(DataframeSource(my_corpus))  # transform the data frame into a corpus
str(my_corpus)
# check the first conversation
inspect(my_corpus[[1]])
# Transform the text to DTM
my_dtm <- as.matrix(DocumentTermMatrix(my_corpus))
str(my_dtm)


################################
########## create TDM ##########
################################
my_tdm <- as.matrix(TermDocumentMatrix(my_corpus))
str(my_tdm)

################################
####### create WordCloud #######
################################
v <- sort(rowSums(my_tdm),decreasing=TRUE)
d <- data.frame(word = names(v),freq=v)
head(d, 10)
set.seed(12345)
#wordcloud(words = d$word, freq = d$freq, min.freq = 4,
#          max.words=400, random.order=FALSE, rot.per=0.35,
#          colors=brewer.pal(10, "Dark2"),
#          figPath = "/Users/yao/Quarter 1/MIS/Project-Herry Potter/shape.png"
#          )
wordcloud2(d,color = 'random-dark',gridSize = 1,
           figPath = "/Users/jay/Quarter2/Datathon/OneDrive_1_2-18-2022/NJdevilslogo.png")
wordcloud2(d)

################################
##### Plot Word Frequency ######
################################
  
barplot(d[1:10,]$freq, las = 2, names.arg = d[1:10,]$word,
        main ="Words Top 10 in Overall Script",
        col = "#92C5DE",
        ylab = "Frequency")

################################
######### create Tf-Idf ########
################################
my_tfidf <- as.matrix(DocumentTermMatrix(my_corpus, control = list(weighting = weightTfIdf)))
str(my_tfidf)
#Data_tfidf <- data.frame(word = my_text$Narrative_Lemma, fre = 1  )
#wordcloud2(Data_tfidf,backgroundColor = 'white')

