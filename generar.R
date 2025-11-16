# especificar la comuna, y genera un gráfico y una tabla que se guardan en la carpeta "output"
library(fs)
library(purrr)
library(glue)

source("funciones.R")

# eleccion <- "alcaldes"
# eleccion <- "gobernadores"
eleccion <- "presidenciales"

# eleccion_titulo <- "Elecciones Municipales 2024"
# eleccion_titulo <- "Elecciones de Gobernadores 2024"
eleccion_titulo <- "Elecciones presidenciales 2025"

eleccion_url <- "elecciones.servel.cl"
# eleccion_url <- "eleccionesgore.servel.cl"


# eliminar anteriores
file_delete(dir_ls("salidas"))


# obtener datos ----
# source(glue("servel_scraping_{eleccion}.R"))
source(glue("servel_limpiar_{eleccion}.R"))


# elegir comuna ----
source("datos/comunas.R")

# borrar todo
# file_delete(dir_ls("salidas"))

comunas_elegidas = comunas_rm

# comunas_elegidas <- sample(comunas, 1)

# comunas_elegidas = c("LA FLORIDA", "PUENTE ALTO", "SANTIAGO", "ÑUÑOA", "SAN MIGUEL",
#                      "PROVIDENCIA", "LAS CONDES", "LA PINTANA", "ESTACION CENTRAL")
# 
# # comunas_elegidas <- comunas_interes
# comunas_elegidas <- c("LA FLORIDA", "PUENTE ALTO", "SANTIAGO", "ÑUÑOA", "MAIPU",
#                       "SAN MIGUEL", "PROVIDENCIA", "LAS CONDES", "LA PINTANA",
#                       "RECOLETA", "MACUL","LA CISTERNA",
#                       "ESTACION CENTRAL", "PEÑALOLEN", "INDEPENDENCIA")

# comunas_elegidas <- c("SANTIAGO", "PUENTE ALTO", "LAS CONDES", "PEÑALOLEN")
# comunas_elegidas <- c("SANTIAGO", "ESTACION CENTRAL", "INDEPENDENCIA", "RECOLETA")

comunas_elegidas <- c("VITACURA", "LO BARNECHEA", "LAS CONDES", "LA REINA")
comunas_elegidas <- c("PUENTE ALTO", "PIRQUE", "LA FLORIDA", "SAN JOSE DE MAIPO")

# generar salidas ----
walk(comunas_elegidas, \(comuna_elegida) {
  message("generando salidas para comuna ", comuna_elegida)
  # comuna_elegida = "LA FLORIDA"
  # comuna_elegida = "PUENTE ALTO"
  # generar gráficos
  source("graficos/graficos.R", local = TRUE)
  
  # generar tablas
  source("tablas/tablas.R", local = TRUE)
  
  source("textos/textos.R", local = TRUE)
  
  # copiar a carpeta de outputs
  file_copy(c(ultimo_archivo(glue("graficos/resultados/{eleccion}")),
              ultimo_archivo(glue("tablas/resultados/{eleccion}")),
              ultimo_archivo(glue("textos/resultados/{eleccion}"))
              ), 
            "salidas", overwrite = TRUE)
})

beepr::beep()


