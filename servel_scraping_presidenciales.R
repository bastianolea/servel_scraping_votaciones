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
driver <- rsDriver(browser = "firefox", 
                   port = 4561L, verbose = F,
                   chromever = NULL, phantomver = NULL)

remote_driver <- driver[["client"]]

# configurar sitio ----
remote_driver$navigate("https://elecciones.servel.cl")

Sys.sleep(esperas*1.5)

# navegar ----

# apretar botón presidente
remote_driver$
  findElement("xpath",
              '//*[@id="4"]')$
  clickElement()

Sys.sleep(tiempo_aleatorio(esperas))

# apretar botón división geográfica
remote_driver$
  findElement("css selector", 
              "#filtros_boton > div:nth-child(3)")$
  clickElement()

Sys.sleep(tiempo_aleatorio(esperas))


# región metropolitana
remote_driver$
  findElement("css selector",
              ".p-6 > div:nth-child(3) > div:nth-child(3) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > select:nth-child(2) > option:nth-child(8)")$
  clickElement()

Sys.sleep(tiempo_aleatorio(esperas))




# obtener comunas ----
sitio_comunas <- remote_driver$getPageSource()

# obtener opciones del selector de comunas
comunas <- sitio_comunas[[1]] |>
  read_html() |> 
  html_elements(".p-6 > div:nth-child(3) > div:nth-child(3) > div:nth-child(1) > div:nth-child(1) > div:nth-child(3) > select:nth-child(2)") |> 
  html_elements("option") |>
  # html_attr("data-id")
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
  # comuna_n <- 2

  # message("obteniendo comuna: ", comunas[comuna_n])
  
  tryCatch({
    
    # seleccionar región metropolitana para reiniciar selector de provincia
    remote_driver$
      findElement("css selector",
                  ".p-6 > div:nth-child(3) > div:nth-child(3) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > select:nth-child(2) > option:nth-child(8)")$
      clickElement()
    
    # seleccionar opción del dropdown
    remote_driver$
      findElement("css selector",
                  paste0("div.mb-10:nth-child(3) > div:nth-child(1) > div:nth-child(1) > div:nth-child(3) > select:nth-child(2) > option:nth-child(", comuna_n, ")"))$
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
    
    # confirmar
    stopifnot("resultados sin filas" = nrow(tabla[[3]]) >= 8)
    
    # extraer datos de mesas
    texto_mesas <- sitio_codigo_fuente |> 
      html_elements("p.text-subtitulo:nth-child(6)") |> 
      html_text()
    
    # confirmar
    if (length(texto_mesas) == 0) warning("sin texto de mesas")
    
    # extraer nombre de comuna 
    nombre_comuna <- sitio_codigo_fuente |> 
      html_elements(xpath = '/html/body/div/div/main/div/div/div[2]/div/div/div[1]/div/div[1]/div[2]/p[1]') |> 
      html_text()
    
    # confirmar
    stopifnot("sin nombre de comuna" = length(nombre_comuna) == 1)
    
    # agregar la columna de comuna y las de mesas
    tabla_2 <- tabla[[3]] |> 
      mutate(comuna_id = comuna_n,
             comuna = nombre_comuna,
             mesas_texto = texto_mesas)
    
    message(nombre_comuna)
    return(tabla_2) 
    
  }, error = function(e) {
    warning(paste("error en comuna", comunas[comuna_n]), e)
    return(NULL)
  }
  )
})



# resultado ----
tabla

tabla |> 
  bind_rows() |> 
  distinct(comuna)

beepr::beep()


# guardar ----
write_rds(tabla, 
          paste0("datos/scraping/presidenciales/resultados_", now(), ".rds"))


# cerrar server ----

driver$server$stop()
# remote_driver$closeWindow()
# remote_driver$quit()
# remote_driver$stop()
# remote_driver$closeall()

message("OK")