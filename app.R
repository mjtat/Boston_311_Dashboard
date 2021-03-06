library(zoo)
library(shiny)
library(xts)
library(plotly)
library(forecast)
library(shinydashboard)

city_data <- readRDS('data.rds')



neighborhood_list <-list('Allston / Brighton', 'Allston', 'Back Bay',  'Beacon Hill', 'Boston', 'Brighton', 'Charlestown', 'Chestnut Hill', 'Dorchester', 'Downtown / Financial District', 'East Boston', 'Fenway / Kenmore / Audubon Circle / Longwood', 'Greater Mattapan',  'Hyde Park', 'Jamaica Plain', 'Mattapan', 'Mission Hill','Roslindale', 'Roxbury', 'South Boston', 'South Boston / South Boston Waterfront',  'South End','West Roxbury' )

server <- function(input, output, session) {

    data <- city_data
    
    #############
    # FUNCTIONS #
    #############
    
    # This function subsets the original data by a particular neighborhood.
    selectNeighborhood <- function(df, neighborhood) {
        df <- df[df$neighborhood == neighborhood,]
    }
    
    # This function subsets the data by department (subject) name. 
    selectDept <- function(df, dept_name) {
        data <- df[df$SUBJECT == dept_name,]
        return(data)
    }
    
    # The neighborhood_plot() function formats the data into a time_series format.
    neighborhood_plot <- function(df, neighborhood, agg) {
        df <- df[df$neighborhood == neighborhood, ]
        df$open_dt <- as.POSIXlt(df$open_dt)
        time_series <- xts(df$request_duration, df$open_dt)
        time_series <- apply.weekly(time_series, agg)
        time_series <- time_series[!is.na(index(time_series))]
        return(time_series)
    }
    
    # The create_forecast function takes a ts object, and models the time series
    # using ARIMA.
    create_forecast <- function(ts, forecastInt) {
        attr(ts, 'frequency') <- 7
        ts <- decompose(as.ts(ts))
        ts <- seasadj(ts)
        fit <- auto.arima(ts, allowdrift = TRUE)
        fcast <- forecast(fit, h=forecastInt)
        return(fcast)
    }
    
    # This large function creates the objects necessary to plot the time series.
    create_timeseries <- function(data) {
        data <- selectDept(data, input$select_subject)
        data$open_dt <- as.POSIXlt(data$open_dt)
        means <- neighborhood_plot(data, input$neighborhood, mean)
        roll_mean <- rollapply(means, 8, mean)
        se <- neighborhood_plot(data, input$neighborhood, function(x) sqrt(var(x)/length(x)))
        count <- neighborhood_plot(data, input$neighborhood, nrow)
        means <- fortify.zoo(means)
        roll_mean <- fortify.zoo(roll_mean)
        se <- fortify.zoo(se)
        count <- fortify.zoo(count)
        means$se <- se$se
        means$rolling_mean <- roll_mean$roll_mean
        means$count <- count$count
        means$Index <- as.Date(means$Index, format = "%Y-%m-%d")
        means <- means[means$Index >= input$date_select_min & means$Index <= input$date_select_max,]
        
    }
    
    #END FUNCTIONS
    
    #######################
    # REACTIVE SHINY CODE #
    #######################
    
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
    
    # Updates the department listing for each neighborhood, since
    # not all neighborhoods have the same type of requests.
    observe({
        updateSelectInput(session, "select_subject",
                          choices = subject_data())
    })
    
    # Creates plotting objects that will be rendered for the main time series plot.
    ts_data <- reactive({
        data <- selectDept(data, input$select_subject)
        data$open_dt <- as.POSIXlt(data$open_dt)
        means <- create_timeseries(data)
        return(means)
    })
    
    # Returns a forecasting object to be rendered.
    output$ts_forecast <- renderPlotly({
        data <- selectDept(data, input$select_subject)
        data$open_dt <- as.Date(data$open_dt, format = "%Y-%m-%d")
        ts <- neighborhood_plot(data, input$neighborhood, mean)
        fcast <- create_forecast(ts, input$forecast_months)
        plot <- autoplot(fcast)+ theme(panel.background=element_rect(fill="gray96")) +ylab(label = "Mean Weekly Hours") + xlab (label = "Week #")
        plot <- ggplotly(plot)
        return(plot)
    })

    # Returns a time_series object to be rendered.
    output$ts_plot <- renderPlotly({
        plot_dat <- ts_data()
        
        plot <- plot_ly(plot_dat, x = ~Index, y = ~means, type = 'scatter', mode = 'lines', name = 'Mean Request Close Time', line = list(color = c('royalblue2'), width = 3.5)) %>%
                add_trace(y = ~rolling_mean, name = 'Rolling Mean', line = list(color = c('orange3'), width = 2, dash = 'dot')) %>%
            add_trace(y = ~se+means, name = 'Standard Error of Weekly Request', line = list(color = c('lavender'), width = 2, dash = 'dash')) %>%
            add_trace(y = ~count, name = 'Number of Mean Requests', line = list(color = c('gary'), width = 2, dash = 'dash')) %>%
        layout(legend = list(x = 0.75, y = 0.95), xaxis = list(title = 'Open Request Date'), yaxis = list(title = "Mean Hours To Close Request / Number of Requests"))
        
        return(plot)
    })
    
    # Renders a data table object
    output$table <- renderTable({
        data <- ts_data()
        data$Index <- as.Date(data$Index, format = "%Y-%m-%d")
        data$Index <- as.character(data$Index)
        return(data)
    })
    
  
}

ui <-fluidPage(
    dashboardHeader(
        title=strong("Boston 311 Request Times", style="font-family: 'Arial'; font-size: 30px;", img(src='phone.png',height=40)), #add title with a map icon
        titleWidth = 330),

    sidebarLayout(
        
        sidebarPanel(
            selectInput("neighborhood", 
                        "Neighborhood: ",
                        choices = neighborhood_list),
            
            selectInput("select_subject", 
                        "Department: ",
                        ""),
            
            sliderInput("date_select_min",
                        "Minimum Date:",
                        min = as.Date("2011-04-20","%Y-%m-%d"),
                        max = as.Date("2017-04-19","%Y-%m-%d"),
                        value=as.Date("2011-04-20"),
                        timeFormat="%Y-%m-%d"),
            
            sliderInput("date_select_max",
                        "Maximum Date:",
                        min = as.Date("2011-04-20","%Y-%m-%d"),
                        max = as.Date("2017-04-19","%Y-%m-%d"),
                        value=as.Date("2017-12-01"),
                        timeFormat="%Y-%m-%d"),
            
            sliderInput('forecast_months',
                        "Weeks to Forecast:",
                        min = 1,
                        max = 52,
                        value = 20)
        ),
        
        tabsetPanel(type = "tabs",
                    tabPanel("Time Series Plot",
                             fluidRow(
                                 (column(12, h4("Click on the legend to hide/add lines. Hover over the lines to view the actual data points."))),
                                 column(12, plotlyOutput('ts_plot')))),
                    tabPanel('ARIMA Time Series Forecasting',
                                fluidRow(12, plotlyOutput("ts_forecast"))),
                    tabPanel("Data Table",
                             tableOutput("table"))
                     
                
            )
        
        )
        
    )
    
       

shinyApp(ui = ui, server = server)
