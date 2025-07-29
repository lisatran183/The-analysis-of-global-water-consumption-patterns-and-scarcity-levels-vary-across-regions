library(shiny)
library(ggplot2)
library(plotly)
library(dplyr)
library(leaflet)

# Load Data
data <- read.csv("global_water_consumption.csv")

# Clean Column Names
data <- data %>% rename_all(make.names)

# Ensure Column Names Are Correct
colnames(data) <- gsub("[.]+", ".", colnames(data))

# UI
ui <- fluidPage(
  titlePanel("Global Water Consumption Dashboard"),
  sidebarLayout(
    sidebarPanel(
      selectInput("country", "Select Country:", choices = unique(data$Country)),
      sliderInput("year", "Select Year:", min = min(data$Year), 
                  max = max(data$Year), value = max(data$Year), step = 1)
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Consumption Trends", 
                 plotlyOutput("timeseries_plot"),
                 plotlyOutput("top_countries_bar")),
        tabPanel("Scarcity & Usage", 
                 plotlyOutput("stacked_area_chart"),
                 leafletOutput("water_map")),
        tabPanel("Sustainability Insights", 
                 plotlyOutput("boxplot_plot"),
                 plotlyOutput("depletion_bar_chart"))
      )
    )
  )
)

# Server
server <- function(input, output) {
  
  # Filtered Data
  filtered_data <- reactive({
    data %>% filter(Country == input$country & Year == input$year)
  })
  
  # Time Series Plot
  output$timeseries_plot <- renderPlotly({
    p <- ggplot(data %>% filter(Country == input$country), 
                aes(x = Year, y = `Total.Water.Consumption.Billion.Cubic.Meters.`)) +
      geom_line(color = "blue") +
      geom_point(color = "darkblue") +
      labs(title = "Total Water Consumption Over Time", x = "Year", 
           y = "Consumption (Billion Cubic Meters)")
    ggplotly(p)
  })
  
  # Top Water-Consuming Countries
  output$top_countries_bar <- renderPlotly({
    top_countries <- data %>% filter(Year == input$year) %>% 
      arrange(desc(`Total.Water.Consumption.Billion.Cubic.Meters.`)) %>% 
      head(10)
    
    p <- ggplot(top_countries, 
                aes(x = reorder(Country, -`Total.Water.Consumption.Billion.Cubic.Meters.`), 
                    y = `Total.Water.Consumption.Billion.Cubic.Meters.`, fill = Country)) +
      geom_bar(stat = "identity") +
      coord_flip() +
      labs(title = "Top 10 Water-Consuming Countries", x = "Country", 
           y = "Total Consumption (Billion Cubic Meters)")
    ggplotly(p)
  })
  
  # Stacked Area Chart - Water Usage Distribution
  output$stacked_area_chart <- renderPlotly({
    p <- ggplot(data %>% filter(Country == input$country), aes(x = Year)) +
      geom_area(aes(y = `Agricultural.Water.Use.`, fill = "Agriculture"), alpha = 0.6) +
      geom_area(aes(y = `Industrial.Water.Use.`, fill = "Industry"), alpha = 0.6) +
      geom_area(aes(y = `Household.Water.Use.`, fill = "Household"), alpha = 0.6) +
      labs(title = "Water Usage Distribution Over Time", x = "Year", y = "Percentage")
    ggplotly(p)
  })
  
  # Map Visualization with Clustering & Year Filtering
  output$water_map <- renderLeaflet({
    map_data <- data %>% filter(Year == input$year)  # Filter data by selected year
    leaflet(map_data) %>%
      addTiles() %>%
      addCircleMarkers(
        lat = runif(nrow(map_data), min = -90, max = 90),
        lng = runif(nrow(map_data), min = -180, max = 180),
        color = ~ifelse(`Water.Scarcity.Level` == "High", "red", 
                        ifelse(`Water.Scarcity.Level` == "Medium", "orange", "green")),
        popup = ~paste(Country, "Water Scarcity:", `Water.Scarcity.Level`),
        clusterOptions = markerClusterOptions() # Enable clustering to reduce clutter
      )
  })
  
  # Boxplot with Rotated X-Axis Labels
  output$boxplot_plot <- renderPlotly({
    p <- ggplot(data, aes(x = as.factor(Year), 
                          y = `Total.Water.Consumption.Billion.Cubic.Meters.`, 
                          fill = as.factor(Year))) +
      geom_boxplot() +
      labs(title = "Boxplot: Water Consumption Over the Years", x = "Year", 
           y = "Total Consumption (Billion Cubic Meters)") +
      theme(legend.position = "none", 
            axis.text.x = element_text(angle = 45, hjust = 1)) # Rotate x-axis labels for clarity
    ggplotly(p)
  })
  
  # Groundwater Depletion Rate
  output$depletion_bar_chart <- renderPlotly({
    depletion_top <- data %>% filter(Year == input$year) %>% 
      arrange(desc(`Groundwater.Depletion.Rate.`)) %>% head(10)
    
    p <- ggplot(depletion_top, aes(x = reorder(Country, -`Groundwater.Depletion.Rate.`), 
                                   y = `Groundwater.Depletion.Rate.`, fill = Country)) +
      geom_bar(stat = "identity") +
      coord_flip() +
      labs(title = "Top 10 Countries with Highest Groundwater Depletion", x = "Country", 
           y = "Depletion Rate (%)")
    ggplotly(p)
  })
  
}

# Run App
shinyApp(ui, server)
