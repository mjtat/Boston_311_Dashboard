library(zoo)
library(shiny)
library(ggplot2)
library(xts)

public_works <- read.csv('public_works.csv')
public_works$open_dt <- as.POSIXlt(public_works$open_dt)

server <- function(input, output) {
    
    data <- public_works
    
    neighborhood_plot <- function(df, neighborhood, agg) {
        df <- df[df$neighborhood == neighborhood, ]
        time_series <- xts(df$request_duration, df$open_dt)
        time_series <- apply.weekly(time_series, agg)
        return(time_series)
    }
    
    ts_data <- reactive({
        dat <- neighborhood_plot(data, input$neighborhood, mean)
        dat2 <- neighborhood_plot(data, input$neighborhood, sd)
        dat <- fortify.zoo(dat)
        dat2 <- fortify.zoo(dat2)
        dat$sd <- dat2$dat2
        dat <- dat[1:(nrow(dat)-1),]
    })
    
    
    df_time_series <- fortify.zoo(time_series)
    df_roll_mean <- fortify.zoo(roll_mean)
    df_time_series <- df_time_series[1:304,]
    df_time_series$rollingmean<-df_roll_mean$roll_mean
    

    output$ts_plot <- renderPlot({
        plot_dat <- ts_data()
        plot <-ggplot(data = plot_dat, aes(x = Index)) + geom_line(aes(y = dat), size = 1) + geom_ribbon(aes(ymin = dat, ymax = (dat + sd) , alpha = .02), fill = "lightskyblue1") + scale_alpha(guide = 'none') + labs(x = 'Date' , y = "Mean Hours to Close 311 Request" )
        plot
        
        #ts_data <- neighborhood_plot(data, input$neighborhood)
        #ts_data <- fortify.zoo(ts_data)
        #autoplot.zoo(ts_data, geom = 'line')
    })
    
}
    

ui <- fluidPage(
    
    titlePanel("Plotting Example"),
    
    sidebarLayout(
    
        sidebarPanel(
            selectInput("neighborhood", 
                        "Neighborhood:",
                        choices = c(as.character(unique(public_works$neighborhood))))
            ),
        mainPanel(
            plotOutput("ts_plot")
        )
    )
)
            


shinyApp(ui = ui, server = server)
