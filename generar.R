# especificar la comuna, y genera un gráfico y una tabla que se guardan en la carpeta "output"
library(fs)
library(purrr)
source("funciones.R")

# eleccion <- "alcaldes"
eleccion <- "gobernadores"

# eleccion_titulo <- "Elecciones Municipales 2024"
eleccion_titulo <- "Elecciones de Gobernadores 2024"

# eleccion_url <- "elecciones.servel.cl"
eleccion_url <- "eleccionesgore.servel.cl"


# eliminar anteriores
file_delete(dir_ls("salidas"))


# obtener datos ----
# source("servel_scraping.R")
source("servel_limpiar.R")


# elegir comuna ----
source("datos/comunas.R")

# comunas_elegidas = comunas_rm

# comunas_elegidas <- sample(comunas, 1)

# comunas_elegidas = c("LA FLORIDA", "PUENTE ALTO", "SANTIAGO", "ÑUÑOA", "SAN MIGUEL",
#                      "PROVIDENCIA", "LAS CONDES", "LA PINTANA", "VIÑA DEL MAR")

# comunas_elegidas <- comunas_interes
# comunas_elegidas <- c("LA FLORIDA", "PUENTE ALTO", "SANTIAGO", "ÑUÑOA", "MAIPU", 
#                       "SAN MIGUEL", "PROVIDENCIA", "LAS CONDES", "LA PINTANA", "VIÑA DEL MAR", 
#                       "RECOLETA", "MACUL","LA CISTERNA",
#                       "ESTACION CENTRAL", "PEÑALOLEN", "VALPARAISO", "RENCA")
comunas_elegidas <- c("ÑUÑOA", "LAS CONDES", "PEÑALOLEN")

# generar salidas ----
walk(comunas_elegidas, \(comuna_elegida) {
  message("generando salidas para comuna ", comuna_elegida)
  # comuna_elegida = "LA FLORIDA"
  # generar gráficos
  source("graficos/graficos.R", local = TRUE)
  
  # generar tablas
  source("tablas/tablas.R", local = TRUE)
  
  # generar mapa
  source("mapas/mapa_gobernadores_rm.R", local = TRUE)
  
  # copiar a carpeta de outputs
  file_copy(c(ultimo_archivo(glue("graficos/resultados/{eleccion}")),
              ultimo_archivo(glue("tablas/resultados/{eleccion}")),
              ultimo_archivo(glue("mapas/resultados/{eleccion}"))), 
            "salidas", overwrite = TRUE)
})

beepr::beep()