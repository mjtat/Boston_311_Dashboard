library(zoo)
library(shiny)
library(ggplot2)
library(xts)

city_data <- readRDS('data.rds')

neighborhood_list <- list('South Boston / South Boston Waterfront', 'Allston / Brighton', 'Dorchester',
                          'Downtown / Financial District', 'Back Bay', 'Greater Mattapan', 'Charlestown', 'Roxbury',
                          'Jamaica Plain', 'Boston', 'Roslindale', 'East Boston', 'South End', 'Hyde Park', 'Beacon Hill',
                          'West Roxbury', 'Mission Hill', 'South Boston', 'Brighton', 'Fenway / Kenmore / Audubon Circle / Longwood',
                          'Mattapan', 'Allston', 'Chestnut Hill')

server <- function(input, output, session) {
    
    data <- city_data
    
    #Functions used later on the server end
    
    selectNeighborhood <- function(df, neighborhood) {
        df = df[df$neighborhood == neighborhood,]
    }
    
    selectDept <- function(df, dept_name) {
        data <- df[df$SUBJECT == dept_name,]
        return(data)
    }
    
    neighborhood_plot <- function(df, neighborhood, agg) {
        df <- df[df$neighborhood == neighborhood, ]
        df$open_dt <- as.POSIXlt(df$open_dt)
        time_series <- xts(df$request_duration, df$open_dt)
        time_series <- apply.weekly(time_series, agg)
        return(time_series)
    }
    
    #END FUNCTIONS
    
######################################################################    
    
    #Reactive Code that will change UI based on user input.
    
    neighborhood_dat <- reactive({
        data <- city_data
        data <- selectNeighborhood(data, input$neighborhood)
        
    })
    
    subject_data <- reactive({
        data <- neighborhood_dat()
        data <- list(unique(data$SUBJECT))
        data <- data[[1]]
        return(data)
    })
    
    observe({
        updateSelectInput(session, "select_subject",
                          choices = subject_data())
    })
    
    
    ts_data <- reactive({
       
        data <- selectDept(data, input$select_subject)
        data$open_dt <- as.POSIXlt(data$open_dt)
        means <- neighborhood_plot(data, input$neighborhood, mean)
        se <- neighborhood_plot(data, input$neighborhood, function(x) sqrt(var(x)/length(x)))
        means <- fortify.zoo(means)
        se <- fortify.zoo(se)
        means$se <- se$se
        means <- means[1:(nrow(means)-1),]
        return(means)
    })
    
    count_data <- reactive({
        data <- selectDept(data, input$select_subject)
        data$open_dt <- as.POSIXlt(data$open_dt)
        count <- neighborhood_plot(data, input$neighborhood, nrow)
        count <- fortify.zoo(count)
        count <- count[1:(nrow(count)-1),]
        return(count)
    })

    output$ts_plot <- renderPlot({
        plot_dat <- ts_data()
        plot <-ggplot(data = plot_dat, aes(x = Index)) + geom_line(aes(y = means), size = 1) + geom_ribbon(aes(ymin = means, ymax = (means + se) , alpha = .02), fill = "lightskyblue1") + scale_alpha(guide = 'none') + labs(x = 'Date' , y = "Mean Hours to Close 311 Request" ) + theme(axis.text.x = element_text(size = 16, angle = 45), axis.text.y = element_text(size = 16), axis.title.x = element_text(size = 20), axis.title.y = element_text(size = 20))
        plot
    })
    
    output$count_plot <- renderPlot({
        plot_dat <- count_data()
        plot_dat$Index <- as.POSIXlt(plot_dat$Index)
        plot <-ggplot(data = plot_dat, aes(x = Index)) + geom_line(aes(y = count), size = 1) + labs(x = 'Date' , y = "Mean Count of 311 Requests Closed" ) + theme(axis.text.x = element_text(size = 16, angle = 45), axis.text.y = element_text(size = 16), axis.title.x = element_text(size = 20), axis.title.y = element_text(size = 20))
        plot
        
    })
    
    output$info <- renderPrint({
        plot_dat <- ts_data()
        # With ggplot2, no need to tell it what the x and y variables are.
        # threshold: set max distance, in pixels
        # maxpoints: maximum number of rows to return
        # addDist: add column with distance, in pixels
        nearPoints(plot_dat, input$plot_click, threshold = 15, maxpoints = 1)
    })

  
}

ui <- fluidPage(
    
    titlePanel("Boston 311 Request Times"),
    
    sidebarLayout(
        
        sidebarPanel(
            selectInput("neighborhood", 
                        "Neighborhood: ",
                        choices = neighborhood_list),
            
            selectInput("select_subject", 
                        "Department: ",
                        "")
            
        ),
        
    
        tabPanel("Time Series Plot",
                 fluidRow(
                     column(12, verbatimTextOutput("info")),
                     column(12, plotOutput('ts_plot', click = "plot_click" )),
                     column(12, plotOutput('count_plot'))
                     
                
            )
        
        )
        
    )
        
)
       

shinyApp(ui = ui, server = server)

