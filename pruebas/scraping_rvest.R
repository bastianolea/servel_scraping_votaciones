library(rvest)

url = "https://provisorios.servel.cl"

sitio <- url |> 
  session() |> 
  read_html()

sitio |> 
  html_elements(".title-font")

sitio |> 
  html_elements("*")

sitio |> 
  html_elements("title")

sitio |> 
  html_elements("title") |> 
  html_text()
