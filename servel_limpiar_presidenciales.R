library(dplyr)
library(fs)
library(readr)
library(purrr)
library(tidyr)
library(lubridate)
library(stringr)
library(tidyr)
library(forcats)

# cargar ----
# eleccion <- "alcaldes"
# eleccion <- "gobernadores"
eleccion <- "presidenciales"

# cargar último resultado de servel_scraping.R
archivos <- dir_info(paste0("datos/scraping/", eleccion)) |> 
  arrange(desc(modification_time))

ultimo <- archivos |> slice(1)

tabla_1 <- read_rds(ultimo$path)

fecha_scraping <- ultimo$modification_time


# limpiar ----
tabla_2 <- tabla_1 |> 
  list_rbind() |> 
  janitor::clean_names() |> 
  group_by(comuna) |> 
  fill(candidatos, .direction = "down") |> 
  mutate(votos = str_remove_all(votos, "\\.") |> as.numeric()) |> 
  mutate(total_votos = sum(votos)) |> 
  ungroup()


# mesas ----
tabla_3 <- tabla_2 |> 
  filter(str_detect(comuna, "PUENTE ALTO")) |>
  # select(mesas_texto) |> print()
  # select(mesas_texto) |> 
  mutate(mesas_texto = str_remove_all(mesas_texto, "\\.")) |> 
  mutate(mesas_texto_extraer = str_extract_all(mesas_texto, "\\d+\\,\\d+|\\d+")) |> 
  rowwise() |> 
  mutate(mesas_escrutadas = mesas_texto_extraer[[1]],
         mesas_totales = mesas_texto_extraer[[2]]) |> 
  ungroup() |> 
  mutate(across(c(mesas_escrutadas, mesas_totales), ~str_remove_all(.x, "\\."))) |> 
  mutate(across(c(mesas_escrutadas, mesas_totales), as.numeric)) |> 
  select(-mesas_texto_extraer)


# arreglar candidatos ----
tabla_4 <- tabla_3 |>
  # filtrar totales
  filter(candidatos != "Total Votación",
         candidatos != "Válidamente Emitidos") |> 
  mutate(orden = str_extract(candidatos, "\\d+") |> as.numeric(),
         orden = tidyr::replace_na(orden, 99)) |> 
  mutate(candidatos = str_remove(candidatos, "\\d+")) |>
  mutate(candidatos = candidatos |> str_trim(),
         candidatos = str_to_title(candidatos)) |> 
  # blancos y nulos
  mutate(tipo_totales = ifelse(tolower(candidatos) %in% c("válidamente emitidos", "votos nulos", "votos blancos", "votos en blanco", "total votación"), TRUE, FALSE))

# arreglar comunas ----
# tabla_4 |> slice(1) |> pull(comuna) |> unique() |> sort()
tabla_5 <- tabla_4 |> 
  mutate(comuna = str_remove(comuna,
                             "Total Votación de la Comuna -"),
         comuna = str_trim(comuna)
         # comuna = str_to_title(comuna)
         )

# sumar nulos y blancos ----
tabla_6 <- tabla_5 |> 
  # mutate(partido2 = ifelse(tipo_totales, "Nulo/Blanco", paste(candidato, partido))) |> 
  mutate(candidatos = ifelse(tipo_totales, "Nulo/Blanco", candidatos)) |> 
  group_by(comuna, candidatos) |> 
  summarize(votos = sum(votos, na.rm = T),
            # porcentaje = sum(porcentaje, na.rm = T),
            mesas_escrutadas = first(mesas_escrutadas),
            mesas_totales = first(mesas_totales), 
            orden = first(orden),
            .groups = "drop") |> 
  ungroup()


# calcular porcentajes ----
tabla_8 <- tabla_6 |> 
  group_by(comuna) |> 
  mutate(total_votos = sum(votos)) |> 
  mutate(porcentaje = votos / total_votos) |> 
  mutate(mesas_porcentaje = mesas_escrutadas / mesas_totales) |> 
  # missings a cero
  mutate(across(where(is.numeric), ~replace_na(.x, 0))) |> 
  ungroup() |> 
  relocate(porcentaje, .after = votos) |> 
  relocate(total_votos, .after = porcentaje)


# # sector político ----
# source("datos/partidos.R")
# 
# tabla_9 <- tabla_8 |> 
#   mutate(partido = ifelse(partido == "REPUBLICANO", "REP", partido)) |> 
#   mutate(sector = case_when(partido %in% partidos_izquierda ~ "Izquierda",
#                             partido %in% partidos_centro ~ "Centro",
#                             partido %in% partidos_derecha ~ "Derecha",
#                             partido %in% partidos_independientes ~ "Independiente",
#                             .default = "Otros")) |> 
#   mutate(sector = case_when(
#     # independientes de verdad
#     candidato == "Matias Jair Toledo Herrera" ~ "Izquierda",
#     candidato == "Catalina San Martin Cavada" ~ "Derecha",
#     # chantas que se hacen pasar por independientes
#     candidato == "Claudio Orrego Larrain" ~ "Centro",
#     candidato == "Ivan Poduje Capdeville" ~ "Derecha", # viña
#     candidato == "Karla Rubilar Barahona" ~ "Derecha", # puente alto
#     candidato == "Daniel Reyes Morales" ~ "Derecha", # la florida
#     candidato == "Sebastian Sichel Ramirez" ~ "Derecha",
#     candidato == "Marcela Cubillos Sigall" ~ "Derecha",
#     candidato == "James Daniel Argo Chavez" ~ "Derecha",
#     .default = sector)) |> 
#   # cambiar independientes que iban en listas de sector definido
#   mutate(sector = case_when(
#     sector == "Independiente" & str_detect(tolower(lista), "chile vamos") ~ "Derecha",
#     sector == "Independiente" & str_detect(tolower(lista), "centro demo") ~ "Centro",
#     sector == "Independiente" & str_detect(tolower(lista), "republicano") ~ "Derecha",
#     sector == "Independiente" & str_detect(tolower(lista), "contigo") ~ "Izquierda",
#     .default = sector)) |> 
#   # ordenar factor de sector político
#   mutate(sector = fct_relevel(sector, "Derecha", "Izquierda", "Independiente", "Centro", "Otros")) |> 
#   relocate(sector, .after = partido)
# 
# # tabla_9 |> 
# #   filter(comuna == "SAN JOAQUIN") |> 
# #   select(1:5, sector)
# # 
# # tabla_9 |> 
# #   filter(comuna == "LA FLORIDA") |> 
# #   select(1:5, sector)


# corregir nombres ----
tabla_10 <- tabla_8 |> 
  mutate(candidatos = str_replace_all(candidatos,
                                     c("Jose" = "José",
                                       "Artes" = "Artés",
                                       "Roman" = "Román",
                                       "Fernandez" = "Fernández",
                                       "Enriquez" = "Enríquez")
                                     )
  ) |> 
  # ordenar
  mutate(candidatos = forcats::fct_reorder(candidatos, orden)) |> 
  arrange(comuna, candidatos)


# terminar
datos_todos <- tabla_10 |> 
  rename(candidato = candidatos) |> 
  mutate(partido = "Ninguno",
         sector = "Ninguno")

datos_todos |> 
  print(n=Inf)

datos_todos |> arrange(desc(votos))


readr::write_csv2(datos_todos, "datos/resultados_presidenciales_2025.csv")
message("Datos limpios guardados")
