# especificar la comuna, y genera un gráfico y una tabla que se guardan en la carpeta "output"
library(fs)
source("funciones.R")


# obtener datos ----
source("servel_scraping.R")
source("servel_limpiar.R")


# elegir comuna ----
comuna_elegida = "ANTOFAGASTA"
# comuna_elegida = "LA FLORIDA"
# comuna_elegida = "PUENTE ALTO"
# comuna_elegida = "SANTIAGO "
# comuna_elegida = "NUNOA"
# comuna_elegida = "PROVIDENCIA"
# comuna_elegida = "LAS CONDES"
# comuna_elegida = "LA PINTANA"
# comuna_elegida = "VINA DEL MAR"


# generar salidas ----
source("graficos.R", local = TRUE)
source("tablas.R", local = TRUE)

# copiar
file_copy(c(ultimo_archivo("graficos"),
            ultimo_archivo("tablas")), 
          "output", overwrite = TRUE)



# eliminar
file_delete(dir_ls("output"))
