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
  findElement("css selector", "button.btn-menu:nth-child(3)")$
  clickElement()

Sys.sleep(esperas)

## apretar botón división geográfica
remote_driver$
  # findElement("xpath", "/html/body/div/div/main/div/div/div[2]/div/div/div/div[1]/div[3]/button")$
  findElement("css selector", "div.p-6:nth-child(2) > div:nth-child(4) > div:nth-child(1) > div:nth-child(3) > button:nth-child(1)")$
  clickElement()

Sys.sleep(esperas)

# ## apretar botón comuna (no es necesario, se aprieta selección directamente en el loop)
# remote_driver$
#   # findElement("css selector", ".mb-4 > div:nth-child(1) > div:nth-child(3) > select:nth-child(2)")$
#   findElement("css selector", "div.mb-10:nth-child(3) > div:nth-child(1) > div:nth-child(3) > select:nth-child(2)")$
#   clickElement()

## obtener opciones del dropdown
# webElem <- remote_driver$findElement(using = 'xpath', '//*[@id="app"]/div/main/div/div/div[2]/div/div/div/div[3]/div/div[3]/select')
webElem <- remote_driver$findElement('css selector', 'div.mb-10:nth-child(3) > div:nth-child(1) > div:nth-child(3) > select:nth-child(2)')
opts <- webElem$selectTag()
comunas <- opts$text # nombres de las comunas

message("cantidad de comunas: ", length(comunas))

Sys.sleep(esperas)


# loop scraping ----


## seleccionar comunas ----
# # pruebas
# lista_comunas <- c(3:10)

# # todas las comunas
# lista_comunas <- c(3:length(comunas)) 

# comunas de interés
comunas_interes <- c("LA FLORIDA", "PUENTE ALTO", "SANTIAGO", "ÑUÑOA", "MAIPU",
                     "PROVIDENCIA", "LAS CONDES", "LA PINTANA", "VIÑA DEL MAR")

lista_comunas <- tibble(comunas) |> 
  mutate(id = row_number()) |> 
  filter(comunas %in% comunas_interes) |> 
  pull(id)


# loop ----
message("obteniendo ", length(lista_comunas), " comunas")

tabla <- map(lista_comunas, \(comuna_n) {
  # comuna_n = 15
  message("obteniendo comuna: ", comunas[comuna_n])
  
  tryCatch({
    # seleccionar opción del dropdown
    remote_driver$
      findElement("css selector",
                  # paste0(".mb-4 > div:nth-child(1) > div:nth-child(3) > select:nth-child(2) > option:nth-child(", comuna_n, ")"))$
                  paste0("div.mb-10:nth-child(3) > div:nth-child(1) > div:nth-child(3) > select:nth-child(2) > option:nth-child(", comuna_n, ")"))$
      clickElement()
    
    # esperar
    Sys.sleep(tiempo_aleatorio(esperas/3))
    
    # obtener el código de fuente del sitio
    sitio <- remote_driver$getPageSource()
    
    sitio_codigo_fuente <- sitio[[1]] |> 
      read_html() 
    
    # extraer tabla
    tabla <- sitio_codigo_fuente |> 
      html_table()
    
    # extraer datos de mesas
    texto_mesas <- sitio_codigo_fuente |> 
      # html_elements(".pl-2") |> 
      html_elements("div.whitespace-nowrap > h1:nth-child(1)") |> 
      html_text()
    
    if (length(texto_mesas) == 0) warning("sin texto de mesas")
    
    numeros_texto_mesas <- texto_mesas |> 
      str_extract_all("\\d+\\.\\d+|\\d+") |> 
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
write_rds(tabla, paste0("datos/resultados_", now(), ".rds"))


# cerrar server ----

driver$server$stop()
# remote_driver$closeWindow()
# remote_driver$quit()
# remote_driver$stop()
# remote_driver$closeall()

message("OK")