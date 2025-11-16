Sys.setlocale("LC_TIME", "es_ES.UTF-8") # meses en español

ultimo_archivo <- function(carpeta = "graficos") {
  fs::dir_info(carpeta) |> slice_max(modification_time, n = 1) |> pull(path)
}

corregir_comunas <- function(comuna_elegida) {
  comuna_elegida |> 
    str_to_lower() |> 
    case_match("concepcion" ~ "Concepción",
               "nunoa" ~ "Ñuñoa", 
               "san joaquin" ~ "San Joaquín",
               "penalolen" ~ "Peñalolén",
               "maipu" ~ "Maipú",
               "estacion central" ~ "Estación Central",
               "aysen" ~ "Aysén",
               .default = comuna_elegida) |> 
    str_to_title()
}

formatear_fecha <- function(x) {
  format(x, '%d-%m-%y_%H%M')
}


tiempo_aleatorio <- function(x) {
seq(x*0.9, x*2, by = 0.05) |> sample(1)
}