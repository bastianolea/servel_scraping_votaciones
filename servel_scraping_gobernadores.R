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
remote_driver$navigate("https://eleccionesgore.servel.cl/")

Sys.sleep(esperas*1.5)

# navegar ----

## apretar botón división geográfica
remote_driver$
  findElement("css selector", ".p-6 > div:nth-child(4) > div:nth-child(1) > div:nth-child(3) > button:nth-child(1)")$
  clickElement()

Sys.sleep(esperas)


# región metropolitana
remote_driver$
  findElement("css selector",
              "div.mb-10:nth-child(3) > div:nth-child(1) > div:nth-child(1) > select:nth-child(2) > option:nth-child(7)")$
  clickElement()


# apretar botón comuna
remote_driver$
  findElement("css selector",
              "div.mb-10:nth-child(3) > div:nth-child(1) > div:nth-child(3) > select:nth-child(2)")$
  clickElement()


# obtener comunas ----
sitio_comunas <- remote_driver$getPageSource()

# obtener opciones del selector de comunas
comunas <- sitio_comunas[[1]] |> 
  read_html() |> 
  html_elements(xpath = '/html/body/div/div/main/div/div/div[1]/div/div/div/div[3]/div/div[3]/select') |> 
  html_elements("option") |>
  html_text()

comunas

message("cantidad de comunas: ", length(comunas))

Sys.sleep(esperas)



# loop scraping ----

## seleccionar comunas ----
# # pruebas
# lista_comunas <- c(3:10)

# # todas las comunas
lista_comunas <- c(2:length(comunas)) # el 1 es "seleccionar opción"


# loop ----
message("obteniendo ", length(lista_comunas), " comunas")


tabla <- map(lista_comunas, \(comuna_n) {
  message("obteniendo comuna: ", comunas[comuna_n])
  
  tryCatch({
    # ## apretar botón comuna (no es necesario, se aprieta selección directamente en el loop)
    remote_driver$
      findElement("css selector",
                  "div.mb-10:nth-child(3) > div:nth-child(1) > div:nth-child(3) > select:nth-child(2)")$
      clickElement()
    
    Sys.sleep(tiempo_aleatorio(esperas/2))
    
    # seleccionar opción del dropdown
    remote_driver$
      findElement("xpath",
                  # paste0(".mb-4 > div:nth-child(1) > div:nth-child(3) > select:nth-child(2) > option:nth-child(", comuna_n, ")"))$
                  # paste0("div.mb-10:nth-child(3) > div:nth-child(1) > div:nth-child(3) > select:nth-child(2) > option:nth-child(", comuna_n, ")"))$
                  paste0("/html/body/div/div/main/div/div/div[1]/div/div/div/div[3]/div/div[3]/select/option[", comuna_n, "]"))$
      clickElement()
    # /html/body/div/div/main/div/div/div[1]/div/div/div/div[3]/div/div[3]/select/option[2]
    # /html/body/div/div/main/div/div/div[1]/div/div/div/div[3]/div/div[3]/select/option[3]
    
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
      html_elements("div.whitespace-nowrap > h1:nth-child(1)") |> 
      html_text()
    
    if (length(texto_mesas) == 0) warning("sin texto de mesas")
    
    
    # agregar la columna de comuna y las de mesas
    tabla_2 <- tabla[[1]] |> 
      mutate(comuna = comunas[comuna_n],
             mesas_texto = texto_mesas)
    
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
write_rds(tabla, 
          paste0("datos/scraping/gobernadores/resultados_", now(), ".rds"))


# cerrar server ----

driver$server$stop()
# remote_driver$closeWindow()
# remote_driver$quit()
# remote_driver$stop()
# remote_driver$closeall()

message("OK")