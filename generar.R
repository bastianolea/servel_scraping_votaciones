# especificar la comuna, y genera un gráfico y una tabla que se guardan en la carpeta "output"
library(fs)
library(purrr)
source("funciones.R")


# obtener datos ----
# source("servel_scraping.R")
source("servel_limpiar.R")


# elegir comuna ----
# comuna_elegida = "LA FLORIDA"
# comuna_elegida = "PUENTE ALTO"
# comuna_elegida = "SANTIAGO"
# comuna_elegida = "ÑUÑOA"
# comuna_elegida = "PROVIDENCIA"
# comuna_elegida = "LAS CONDES"
# comuna_elegida = "LA PINTANA"
# comuna_elegida = "VIÑA DEL MAR"

# comuna_elegida <- sample(comunas, 1)

comunas_elegidas = c("LA FLORIDA", "PUENTE ALTO", "SANTIAGO", "ÑUÑOA", 
                     "PROVIDENCIA", "LAS CONDES", "LA PINTANA", "VIÑA DEL MAR")

# generar salidas ----
walk(comunas_elegidas, \(comuna_elegida) {
  message("generando salidas para comuna ", comuna_elegida)
  
  # generar gráficos
  source("graficos.R", local = TRUE)
  
  # generar tablas
  source("tablas.R", local = TRUE)
  
  # copiar a carpeta de outputs
  file_copy(c(ultimo_archivo("graficos"),
              ultimo_archivo("tablas")), 
            "output", overwrite = TRUE)
})


# eliminar
# file_delete(dir_ls("output"))
beepr::beep()