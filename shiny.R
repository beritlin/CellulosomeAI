library(shiny)
library(ggplot2)
library(plotly)


# 載入兩個不同的 UMAP 資料
df1 <- read.table("umap_txipv3_species_fungi.txt", header = TRUE)
df2 <- read.table("umap_txipv3_domain_fungi.txt",sep=",", header = TRUE)

ui <- fluidPage(
  titlePanel("UMAP for Fungi Kingfdom"),
  tabsetPanel(
    tabPanel("Species",
      sidebarLayout(
        sidebarPanel(
          selectInput("color_by1", "Color by:", 
                      choices = c("Division", "Subdivision", "Class"), 
                      selected = "Division")
        ),
        mainPanel(
          plotlyOutput("umap_plot1", height = "600px")
        )
      )
    ),
    tabPanel("Domain",
      sidebarLayout(
        sidebarPanel(
          selectInput("color_by2", "Color by:", 
                      choices = c("Cellulosome", "Associate", "Core"), 
                      selected = "Cellulosome")
        ),
        mainPanel(
          plotlyOutput("umap_plot2", height = "600px")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  output$umap_plot1 <- renderPlotly({
    p1 <- ggplot(df1, aes_string(x = "UMAP1", y = "UMAP2", 
                                 color = input$color_by1, 
                                 text = "Proteome_ID")) +
      geom_point(size = 2, alpha = 0.8) +
      theme_bw()  +
      theme(legend.position = "bottom")
    ggplotly(p1, tooltip = "text")
  })

output$umap_plot2 <- renderPlotly({
  # 分開 NA 與非 NA 資料
  df_na <- df2[is.na(df2[[input$color_by2]]), ]
  df_non_na <- df2[!is.na(df2[[input$color_by2]]), ]
  
  # 繪圖
  p2 <- ggplot() +
    # NA 點：底層、淡灰色、小點、無 legend
    geom_point(data = df_na, aes(x = UMAP1, y = UMAP2, text = PFAM),
               color = "gray95", size = 1, alpha = 0.1, show.legend = FALSE) +
    
    # 非 NA 點：上層、有顏色、有 legend
    geom_point(data = df_non_na, aes_string(x = "UMAP1", y = "UMAP2",
                                            color = input$color_by2,
                                            text = "PFAM"),
               size = 2, alpha = 0.8, show.legend = FALSE) +
    theme(legend.position = "none") +
    theme_bw() 
  
  ggplotly(p2, tooltip = "text")
})
}

shinyApp(ui, server)
