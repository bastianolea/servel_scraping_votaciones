library(dplyr)
library(rvest)
library(purrr)
library(tidyr)
library(lubridate)
library(stringr)
library(RSelenium)
library(readr)

source("funciones.R")

esperas = 2

# abrir server ----
driver <- rsDriver(port = 4566L, browser = "firefox", chromever = NULL) # can also be "chrome"

remote_driver <- driver[["client"]]

# configurar sitio ----
# remote_driver$navigate("https://provisorios.servel.cl")
remote_driver$navigate("https://elecciones.servel.cl")

Sys.sleep(esperas*1.5)

# navegar ----

## apretar botón alcalde 
remote_driver$
  # findElement("xpath", "/html/body/div/div/header/div/div/div[2]/div/button[2]")$
  # findElement("css selector", "button.btn-menu:nth-child(3)")$
  findElement("css selector", ".css-68fvpc > button:nth-child(3)")$
  clickElement()

Sys.sleep(esperas)

## apretar botón división geográfica
remote_driver$
  # findElement("xpath", "/html/body/div/div/main/div/div/div[2]/div/div/div/div[1]/div[3]/button")$
  # findElement("css selector", "div.p-6:nth-child(2) > div:nth-child(4) > div:nth-child(1) > div:nth-child(3) > button:nth-child(1)")$
  findElement("css selector", "button.css-1dptqwv:nth-child(3)")$
  clickElement()

Sys.sleep(esperas)

# ## obtener opciones del dropdown (versión anterior)
# # webElem <- remote_driver$findElement(using = 'xpath', '//*[@id="app"]/div/main/div/div/div[2]/div/div/div/div[3]/div/div[3]/select')
# # webElem <- remote_driver$findElement('css selector', 
#                                      # 'div.mb-10:nth-child(3) > div:nth-child(1) > div:nth-child(3) > select:nth-child(2)')
#                                      # "div.css-0:nth-child(3) > div:nth-child(1) > div:nth-child(2) > div:nth-child(1)")
# webElem <- remote_driver$findElement(using = 'xpath', 
#                                      "/html/body/div/div/div/div/div[1]/div/div/div[2]/div/div/div[3]/div/div/")
# opts <- webElem$selectTag()
# opts <- webElem
# comunas <- opts$text # nombres de las comunas

# ## apretar botón comuna (antes no era necesario, se apretaba la selección directamente en el loop, pero luego de la actualización del sitio hay que hacerlo)
remote_driver$
  # findElement("css selector", ".mb-4 > div:nth-child(1) > div:nth-child(3) > select:nth-child(2)")$
  findElement("css selector",
              # "div.mb-10:nth-child(3) > div:nth-child(1) > div:nth-child(3) > select:nth-child(2)")$
              "div.css-0:nth-child(3) > div:nth-child(1) > div:nth-child(2)")$
  clickElement()


sitio_comunas <- remote_driver$getPageSource()

comunas <- sitio_comunas[[1]] |> 
  read_html() |> 
  # html_elements("div.MuiPaper-root:nth-child(3)") |> 
  # html_elements(".MuiPaper-elevation") |> 
  # html_elements(xpath = "//*[@id='filtro-select']") |> 
  html_elements(xpath = '//*[@id=":r5:"]') |> 
# html_elements(".MuiPaper-root") |> 
  # html_elements(xpath = '//*[@id=":r4:"]') |> 
  # pluck(3) |> 
  html_elements("li") |>
  # html_elements(".MuiButtonBase-root") |> 
  html_text()

comunas



message("cantidad de comunas: ", length(comunas))

Sys.sleep(esperas)


# loop scraping ----


## seleccionar comunas ----
# # pruebas
# lista_comunas <- c(3:10)

# # todas las comunas
lista_comunas <- c(1:length(comunas))

# # comunas de interés
# source("datos/comunas.R")
# 
# lista_comunas <- tibble(comunas) |>
#   mutate(id = row_number()) |>
#   # filter(comunas %in% comunas_interes) |>
#   # filter(comunas %in% comunas_rm) |>
#   filter(comunas %in% c(comunas_interes, comunas_rm)) |>
#   pull(id)


# loop ----
message("obteniendo ", length(lista_comunas), " comunas")

tabla <- map(lista_comunas, \(comuna_n) {
  # comuna_n = 63
  message("obteniendo comuna: ", comunas[comuna_n])
  
  tryCatch({
    # ## apretar botón comuna (no es necesario, se aprieta selección directamente en el loop)
    remote_driver$
      # findElement("css selector", ".mb-4 > div:nth-child(1) > div:nth-child(3) > select:nth-child(2)")$
      findElement("css selector",
                  # "div.mb-10:nth-child(3) > div:nth-child(1) > div:nth-child(3) > select:nth-child(2)")$
                  "div.css-0:nth-child(3) > div:nth-child(1) > div:nth-child(2)")$
      clickElement()

    Sys.sleep(tiempo_aleatorio(esperas/2))
    
    # seleccionar opción del dropdown
    remote_driver$
      findElement("xpath",
                  # paste0(".mb-4 > div:nth-child(1) > div:nth-child(3) > select:nth-child(2) > option:nth-child(", comuna_n, ")"))$
                  # paste0("div.mb-10:nth-child(3) > div:nth-child(1) > div:nth-child(3) > select:nth-child(2) > option:nth-child(", comuna_n, ")"))$
                  paste0("/html/body/div[2]/div[3]/ul/li[", comuna_n, "]"))$
      clickElement()
    
    
    # esperar
    Sys.sleep(tiempo_aleatorio(esperas/2))
    
    # obtener el código de fuente del sitio
    sitio <- remote_driver$getPageSource()
    
    sitio_codigo_fuente <- sitio[[1]] |> 
      read_html() 
    
    # extraer tabla
    tabla <- sitio_codigo_fuente |> 
      html_table(convert = FALSE)
    
    # extraer datos de mesas
    texto_mesas <- sitio_codigo_fuente |> 
      # html_elements(".pl-2") |> 
      # html_elements("div.whitespace-nowrap > h1:nth-child(1)") |> 
      html_elements("p.MuiTypography-root:nth-child(6)") |> 
      html_text()
    
    if (length(texto_mesas) == 0) warning("sin texto de mesas")
    
    numeros_texto_mesas <- texto_mesas |> 
      str_extract_all("\\d+\\,\\d+|\\d+") |> 
      unlist()
    
    # agregar la columna de comuna y las de mesas
    tabla_2 <- tabla[[1]] |> 
      mutate(comuna = comunas[comuna_n],
             mesas_texto = texto_mesas,
             mesas_escrutadas = numeros_texto_mesas[1],
             mesas_totales = numeros_texto_mesas[2])
    
    return(tabla_2) 
    
  }, error = function(e) {
    warning(paste("error en comuna", comunas[comuna_n]), e)
    return(NULL)
  }
  )
})

# resultado ----
tabla
beepr::beep()


# guardar ----
write_rds(tabla, paste0("datos/scraping/resultados_", now(), ".rds"))


# cerrar server ----

driver$server$stop()
# remote_driver$closeWindow()
# remote_driver$quit()
# remote_driver$stop()
# remote_driver$closeall()

message("OK")