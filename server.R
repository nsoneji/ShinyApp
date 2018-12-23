# Bharat Batra | 11910105 | bharat_batra_cbas2019@isb.edu
# Nitin Soneji | 11810062 | nitin_soneji_cba2019w@isb.edu
# Rupesh Lad   | 11810031 | rupesh_lad_cba2019w@isb.edu

#TABA Assignment
#Problem 1: Building a Shiny App around the UDPipe NLP workflow

options(shiny.maxRequestSize = 30*1024^2)
shinyServer(function(input,output){  # server function for input and output 
  
 
  Dataset <- reactive({              # reactive function to dynamically capture the data
    if(is.null(input$file1)){
      return(NULL)
    }
    else{                                             # text cleaning
      text <- readLines(input$file1$datapath)
      text = str_replace_all(text,"<.*?>","")
      text = str_replace_all(text,"[^a-zA-Z\\s]", " ")
      text = str_replace_all(text,"[\\s]+", " ")
      text = str_replace_all(text,"<.*?>","")
      text = text[text != ""]
      
      return(text)
    }
  })
  
  model <- reactive({                                #loading selected model
    if(is.null(input$file2)){ 
           return (NULL)}
    else {
          udpipe_model = udpipe_load_model(input$file2$datapath)
          return(udpipe_model)
              
        }
  })
  
  annotated_df = reactive({        #creating annotated document using udpipe     
    
    x <- udpipe_annotate(model(),x = Dataset())
    x <- as.data.frame(x)
    return(x)
  })
  
  output$annotatedOutput = renderDataTable({   # creating data table of annotated data frame
    if(is.null(input$file1)){
      textOutput("No textfile is uploaded.")
      return(NULL)
    }
    else{
      #Adding progress bar to show user that it is processing
      withProgress(message = "Annotated Document processing in progress...",{
      out = annotated_df()[,-4]
      out = out %>% subset(.,xpos %in% input$xpos)
      incProgress(amount = 1, message ="Completed" )
      return(out)
      })
    }
  })
  
  plotname <- reactive(    # For loop for seeting the subtitle plot dynamically
    {  
      plotname = NULL
      
      
      for ( i in 1:length(input$xpos))
      {
        plotname = paste(plotname,input$xpos[i]) 
        
      }
      return (plotname)
    }
  )
  
  output$cooccurence = renderPlot({    # render coocurence plot
    if(is.null(input$file1)){
      return(NULL)
    }
    else{
      #Adding progress bar to show user that it is processing
      withProgress(message = "Co-occurances graph preparation in progress...", {
      text_cooc <- cooccurrence(
        x = subset(annotated_df(),xpos %in% input$xpos),
        term = "lemma",
        group = c("doc_id","paragraph_id","sentence_id"))
      
      wordnetwork <- head(text_cooc,50)
      wordnetwork <- igraph::graph_from_data_frame(wordnetwork)
      
      ggraph(wordnetwork, layout = "fr") +
        
        geom_edge_link(aes(width = cooc, edge_alpha = cooc), edge_colour = "red") +
        geom_node_text(aes(label = name), col = "blue", size = 4) +
        
        theme_graph(base_family = "Arial Narrow") +
        theme(legend.position = "none") +
        
        labs(title = "Cooccurence plot", subtitle = plotname() )
      
       })
      
    }
  }) 
  
})
  
