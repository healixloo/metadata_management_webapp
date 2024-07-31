.libPaths(c(.libPaths(),".R"))
# Apps
# configures
clouds<-c("./data_on_cloud/")
datafn<-"DataHub.txt"
users<-c("jing","melike","mark","tayyaba","ismail","ulas","lab","admin")
passwords<-c("jing","melike","mark","tayyaba","ismail","ulas","lab","admin")
admin_account<-c("jing","melike")
Sys.setlocale("LC_ALL", 'en_GB.UTF-8')
Sys.setenv(LANG = "en_US.UTF-8")

## starting
dir.create("/tmp/jing")

list.of.packages <- c("shinyFiles")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages(lib.loc="/tmp/jing")[,"Package"])]
if(length(new.packages)) install.packages(new.packages,repos = "http://cran.us.r-project.org",lib="/tmp/jing")
#list.of.packages <- c("shinymanager")
#new.packages <- list.of.packages[!(list.of.packages %in% installed.packages(lib.loc="/tmp/jing")[,"Package"])]
#if(length(new.packages)) withr::with_libpaths(new = "/tmp/jing", remotes::install_github('datastorm-open/shinymanager'))


library(shiny)
library(shinydashboard)
library(shinyBS)
library(shinyjs)
library(shinyFiles)
library(shinymanager)
#library(shinymanager)
#library(shinyWidgets)
library (xtable)

inactivity <- "function idleTimer() {
var t = setTimeout(logout, 120000);
window.onmousemove = resetTimer; // catches mouse movements
window.onmousedown = resetTimer; // catches mouse movements
window.onclick = resetTimer;     // catches mouse clicks
window.onscroll = resetTimer;    // catches scrolling
window.onkeypress = resetTimer;  //catches keyboard actions

function logout() {
window.close();  //close the window
}

function resetTimer() {
clearTimeout(t);
t = setTimeout(logout, 120000);  // time is in milliseconds (1000 is 1 second)
}
}
idleTimer();"


# data.frame with credentials info
credentials <- data.frame(
  user = users,
  password = passwords,
  # comment = c("alsace", "auvergne", "bretagne"), %>% 
  stringsAsFactors = FALSE
)

# Design ------------------------------------------------------------------
# Red star for mandatory fields 
appCSS <- 
  ".mandatory_star { color: red; }
#error { color: red; }"


# Increase the file size to be uploaded!
options(shiny.maxRequestSize=30*1024^2) # 30MB 

# To save the Data  -------------------------------------------------------

humanTime <- function() {
  format(Sys.time(), "%Y%m%d-%H%M%OS")
}

saveData <- function(data,annotation,outdir=clouds) {
  datat <- t(data)
  j<-annotation[annotation$Attribute=="textInput","IDs"][1]
  # Create a unique file name
  fileName <- sprintf("Readme_%s_%s.txt", 
                      datat[,j], 
                      digest::digest(data))
  # Write the data to a temporary file locally
  filePath <- file.path(outdir, fileName)
  data<-as.data.frame(data)
  data<-merge(data,annotation[,c("IDs","Labels")],by.x=0,by.y="IDs",all.y=T)
  data$rank<-as.numeric(sub("ID","",data$Row.names))
  data<-data[order(data$rank),]
  write.table(data[,c(1,3,2)],sep="\t", 
            filePath,fileEncoding = "UTF-8", 
            row.names = FALSE, 
            quote = TRUE)

}
###

div1<-div(
        id = "form1",
        uiOutput("ui1")
        ) # Closing div


###
# ShinyAPP ----------------------------------------------------------------
# Shiny app with 3 fields that the user can submit data for
shinyApp( 
  ui <- secure_app(head_auth = tags$script(inactivity),
        dashboardPage(skin = "green",
		     dashboardHeader(title = "Readme & Index", titleWidth = 250),
                     dashboardSidebar(#disable = TRUE,
                       width = 150,
                       sidebarMenu(menuItem("Menu"),
                                   menuItem("Form", tabName = "form_tab", icon = icon("clock")),
				   menuItem("Data", tabName = "data_tab", icon = icon("file-alt"),selected = TRUE),
                                   menuItem("File", tabName = "file_tab", icon = icon("file-alt")),
                                   menuItem("Help", tabName = "help_tab", icon = icon("question"))
                       )
                     ),
                     dashboardBody(
                       width=1500,
                       shinyjs::useShinyjs(), 
                       shinyjs::inlineCSS(appCSS), # you need this if you want to change the "design" of you form

                       # Form inputs -------------------------------------------------------------
                       tabItems(
                         # First tab content
                         tabItem(tabName = "form_tab",
#				 textOutput("text"),
#				 br(),
                                 tags$li(selectInput('type','Type to choose',choices=c('Dataset','Project','Resource')),class='dropdown'),
				 div1,
#                                 fluidRow(
#                                              tabBox(
#                                                  title = NULL, width = NULL,
#                                                  # The id lets us use input$tabset1 on the server to find the current tab
#                                                  id = "tabset1", #height = "38px",
#						  tabPanel("Dataset",div1)
#                                              )
#                                 ),
				
                                 actionButton("submit",
                                             "Submit"),
                                 # Submission progression bar or Error
                                 shinyjs::hidden(
                                 span(id = "submit_msg",
                                        "Submitting..."),
                                 div(id = "error",
                                       div(br(),
                                           tags$b("Error: "), # b tags is for bold text
                                           span(id = "error_msg"))))
				 
                         ), # closing tab 1 

			 # Additional tab      	
                         tabItem(tabName = "data_tab",
                                 DT::dataTableOutput("table"),
				 actionButton("runUpdateScript", "Update Script"),
				 tags$a(class="btn btn-default", href="https://gen100.leibniz-fli.de//shiny-3-6/jlu/auto_update_2/", "Update Link")
                         ), # Closing additional tab

                         # Second tab content
                         tabItem(tabName = "file_tab",
                                 shinyFilesButton('files', label='File select', title='Please select a file', multiple=T) ,
                                 #verbatimTextOutput('rawInputValue'),
                                 tableOutput("contents"),
                                 verbatimTextOutput('filepaths') ,
                                 downloadButton("downloadFile", "Download File"),
				 downloadButton("downloadHtml", "Download Html"),
				 actionButton("remove","Delete"),
				 #hr(),
				 fileInput("file1", "", accept = c("text/plain"), buttonLabel="Upload")

                         ), # Closing tab 2
                         tabItem(tabName = "help_tab",
                                 h2("Need help or information?"),
                                 h3("Contact"),
                                 HTML('If you came across any issue, please sent an email to <a href="mailto:jing.lu@leibniz-fli.de?subject=Question about Meta Form">Meta Project (jing.lu@leibniz-fli.de)</a>. This Template was generated on 2022-07-26 by Jeanne Wilbrandt modified by Melike Donertas under the use of https://data.research.cornell.edu/content/readme.'),
                                 h3("What's needed in the form?"),
                                 div(span("The red star ("), span("*",style="color:red"), span(") means that it's a mandatory field")
                                 ), # Close div 
                                 br(),
                                 p("Thank you for your feeddback. We appreciate all comments and ideas.")
                         ) # Closing tab 3                         
                       ), # Closing tabItems

                       # Thank you message -------------------------------------------------------    
                       shinyjs::hidden(
                         div(
                           id = "thankyou_msg",
                           h2("Your response was submitted successfully!"),
                           h3(actionLink("submit_another", 
                                      "Submit another response"))
                         ) # Closing div 
                       ) # Closing shinyjs::hidden

                     ) # Closing DashboardBody
  ) # Closing DashboardPage
  ), # Closing secure_app


  # Server ------------------------------------------------------------------
  server = function(input, output, session) {

  observeEvent(input$runUpdateScript, { 
		       system("Rscript /gen/lnxdata/shiny-server/jlu/meta_template_dry_20240506/auto_update_20240506.R")
		       shinyjs::info("Update script executed successfully.")
  })

  # Get the info of uploaded file
  fileinfo <- reactive({
	  req(input$file1)
	  # Get the name and path of the first file
	  list(name = input$file1$name[1], path = input$file1$datapath[1])
  })

   # Copy the uploaded file to a permanent location
   observe({
	   # Get the file name and path
	   filename <- fileinfo()$name
	   filepath <- fileinfo()$path
	   # Copy the file
	   newname <- paste0("upload_", filename)
	   newpath <- file.path(paste(clouds,dir_name(),"/",sep=""), newname)
	   file.copy(from = filepath, to = newpath)
   })

  result_auth <- secure_server(check_credentials = check_credentials(credentials))  
  output$res_auth <- renderPrint({
    reactiveValuesToList(result_auth)
  })

#  dir_name<-reactive({result_auth$user})
  dir_name <- reactive({
     # Check if result_auth$user contains "admin"
     if (any(grepl(paste(admin_account,collapse="|"), result_auth$user))) {
       return(paste0(dirname(result_auth$user), "/"))  # Assuming user path has a subdirectory
     } else {
       return(result_auth$user)
     }
  })
  # Display spreatsheet
  output$table <- DT::renderDataTable({	  
#    basepath <- paste(clouds,dir_name(),"/",datafn,sep="")
    basepath <- paste(clouds,"lab/",datafn,sep="")	  
    if (file.exists(basepath)) { mmttccaarrss<-reactiveFileReader(1000,session,filePath=basepath,readFunc=function(ff){df<-read.table(ff,header=TRUE,check.names=FALSE);colnames(df)<-stringr::str_split_fixed(colnames(df),":",2)[,1];return(df)})   
    DT::datatable(mmttccaarrss(), filter = "top", options = list(scrollX = TRUE))}
  })


  #roots =  c(wd = paste("./",dir_name(),sep=""))
  shinyFileChoose(input, 'files', 
                  roots = #{
                          #if (grepl("admin", dir_name())) {
                          #  c(wd="/gen/lnxdata/shiny-server/jlu/meta_template_dry_20240506/data_on_cloud/")
                          #} else {
                          #  c(wd = paste(clouds, dir_name(), sep=""))
                          #}
                          #},
			  c(wd = paste(clouds,dir_name(),sep="")), 
                  filetypes=c('csv', 'txt' , 'gz' , 'md5' , 'pdf' , 'fasta' , 'fastq' , 'aln'))
  
  output$rawInputValue <- renderPrint({str(input$files)})
  
  output$filepaths <- renderPrint({parseFilePaths(c(wd = paste(clouds,dir_name(),sep="")), input$files)})
  
  output$contents <- renderTable({
    inFile <- parseFilePaths(c(wd = paste(clouds,dir_name(),sep="")), input$files)
    if( NROW(inFile)) {
      df <- read.table(as.character(inFile$datapath),head=T,sep="\t")
      print(df)
    }
  })    

  output$downloadFile <- downloadHandler(
    filename = function() {
      as.character(parseFilePaths(c(wd = paste(clouds,dir_name(),sep="")), input$files)$name)
    },
    content = function(file) {
      fullName <- as.character(parseFilePaths(c(wd = paste(clouds,dir_name(),sep="")), input$files)$datapath)
      file.copy(fullName, file)
    }
  )

  output$downloadHtml <- downloadHandler(
    filename = function() {
      gsub(".txt",".html",as.character(parseFilePaths(c(wd = paste(clouds,dir_name(),sep="")), input$files)$name))
    },
    content = function(file) {
      inFile <- parseFilePaths(c(wd = paste(clouds,dir_name(),sep="")), input$files)
      if( NROW(inFile)) {
        df <- read.table(as.character(inFile$datapath),head=T,sep="\t")
        tab <- xtable (df)
	print (tab, type = "html", file = file)
      }
    }
  )
#################################################### 
output$text <- renderText({paste0("You are viewing tab \"", input$tabset1, "\"")})

ts1<-reactive({req(input$type)})
annotation<-reactive({
if (ts1()=="Dataset") {
   annotationx<-read.csv("./Annotation1.csv",header = T,stringsAsFactors = F,check.names = F)} else if (ts1()=="Project") {
   annotationx<-read.csv("./Annotation2.csv",header = T,stringsAsFactors = F,check.names = F)} else if (ts1()=="Resource") {
   annotationx<-read.csv("./Annotation3.csv",header = T,stringsAsFactors = F,check.names = F)} else {
   annotationx<-read.csv("./Annotation1.csv",header = T,stringsAsFactors = F,check.names = F)}

colnames(annotationx)[1]<-"IDs"
annotationx
})
# Fields definition -------------------------------------------------------
# Define the fields we want to save from the form
fields <- reactive({annotation()$IDs}) # the order here will be the same as the one that is saved in a CSV!

# Mandatory fields --------------------------------------------------------
# Defines mandatory fields:
fieldsMandatory <- reactive({annotation()[annotation()$Mandatory=="Y","IDs"]})

# Labeling with star for mandatory fields
labelMandatory <- function(label) {
  tagList(
    label,
    span("*", class = "mandatory_star")
  )
}

# Design ------------------------------------------------------------------
# Red star for mandatory fields
#appCSS <-
#  ".mandatory_star { color: red; }
###error { color: red; }"

    ## text input
    output$ui1 <- renderUI({
                                   ui_parts <- c()
                                   for (i in fields()) {    
                                      if (annotation()[annotation()$IDs==i,"Attribute"]=="helpText") {ui_parts[[i]] <-helpText(annotation()[annotation()$IDs==i,"Labels"],width =800)}
                                      else if (annotation()[annotation()$IDs==i,"Attribute"]=="textInput") {
                                        if (annotation()[annotation()$IDs==i,"Mandatory"]=="Y") {ui_parts[[i]] <-textInput(i,labelMandatory(annotation()[annotation()$IDs==i,"Labels"]),width =800)}
                                        else {ui_parts[[i]] <-textInput(i,annotation()[annotation()$IDs==i,"Labels"],width =800)}
                                      }  
                                      else if (annotation()[annotation()$IDs==i,"Attribute"]=="textAreaInput") {ui_parts[[i]] <-textAreaInput(i,annotation()[annotation()$IDs==i,"Labels"],rows=3,width =800)}    
                                      else if (annotation()[annotation()$IDs==i,"Attribute"]=="dateInput") {ui_parts[[i]] <-dateInput(i,annotation()[annotation()$IDs==i,"Labels"],width =800)}  
                                      else if (annotation()[annotation()$IDs==i,"Attribute"]=="checkboxInput") {ui_parts[[i]] <-checkboxInput(i,annotation()[annotation()$IDs==i,"Labels"],FALSE,width =800)} 
				      else if (annotation()[annotation()$IDs==i,"Attribute"]=="dropDown") {ui_parts[[i]] <-selectInput(i,annotation()[annotation()$IDs==i,"Labels"],choices=unlist(strsplit(annotation()[annotation()$IDs==i,"Mandatory"],";")),width =800)}
                                   }
                                   ui_parts
    })


########################################
    runjs(' 
          var el2 = document.querySelector(".skin-green");
          el2.className = "skin-green sidebar-mini";
          ')# this is createing a sidebar mini, but it wraps up the title to trim it... 

    # Whenever a field is filled, aggregate all from data
    formData <- reactive({
      fieldss<-intersect(fields(),names(input))
      # print all 	    
      #fieldss<-fields()
      data <- sapply(fieldss, function(x) input[[x]]) 
      data
    })

    observe({
      # check if all mandatory fields have a value
      mandatoryFilled <-
        vapply(fields(),
               function(x) {
                 !is.null(input[[x]]) && input[[x]] != ""
               },
               logical(1))
      mandatoryFilled <- all(mandatoryFilled)
      # enable/disable the submit button
#      shinyjs::toggleState(id = "submit", 
#                           condition = mandatoryFilled)

    })

    # When the Submit button is clicked, save the form data (action to take when submit button is pressed)
    observeEvent(input$submit, {
      shinyjs::disable("submit")
      shinyjs::info("The form has been submitted.")
      shinyjs::show("submit_msg")
      shinyjs::hide("error")
      tryCatch({
	dir_name<-reactive({result_auth$user})
	dir.create(paste(clouds,dir_name(),sep=""))
        saveData(formData(),annotation(),outdir=paste(clouds,dir_name(),"/",sep=""))
        shinyjs::reset("form1")
        shinyjs::hide("form1")
	shinyjs::reset("form2")
        shinyjs::hide("form2")
	shinyjs::reset("form3")
        shinyjs::hide("form3")
	shinyjs::hide("submit")
        shinyjs::show("thankyou_msg")
      },
      error = function(err) {
        shinyjs::text("error_msg", err$message)
        shinyjs::show(id = "error", anim = TRUE, animType = "fade")
      },
      finally = {
        shinyjs::enable("submit")
        shinyjs::hide("submit_msg")
      })
    })

    observeEvent(input$remove,{
         file.remove(as.character(parseFilePaths(c(wd=paste(clouds,dir_name(),sep="")),input$files)$datapath))
	 shinyjs::info("The selected file has been deleted.")
    })

    # Hide the thank you message and show the form 
    observeEvent(input$submit_another, {
      shinyjs::show("form1")
      shinyjs::show("form2")
      shinyjs::show("form3")
      shinyjs::show("submit")
      shinyjs::hide("thankyou_msg")
    })

  }
    )
