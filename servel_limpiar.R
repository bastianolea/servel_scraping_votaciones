library(dplyr)
library(fs)
library(readr)
library(purrr)
library(tidyr)
library(lubridate)
library(stringr)
library(tidyr)

# cargar ----

# cargar último resultado de servel_scraping.R
archivos <- dir_info("datos") |> 
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
  mutate(total_votos = sum(votos)) |> 
  mutate(across(c(mesas_escrutadas, mesas_totales), as.numeric))


# repetidos ----
# # marcar casos repetidos (misma cantidad de votos)
# tabla_3 <- tabla_2 |> 
#   group_by(comuna, total_votos) |> 
#   nest() |> 
#   ungroup() |> 
#   mutate(repetido = ifelse(total_votos == lag(total_votos), TRUE, FALSE),
#          repetido = replace_na(repetido, FALSE))
# 
# # ver comunas repetidas
# tabla_3 |> 
#   unnest(cols = everything()) |> 
#   filter(repetido) |> 
#   distinct(comuna)
# 
# # dejar solo las no repetidas
# tabla_4 <- tabla_3 |> 
#   unnest(cols = everything()) |> 
#   filter(!repetido)


# marcar filas que no son candidatos ----
tabla_5 <- tabla_2 |> 
  mutate(tipo_totales = ifelse(lista_pacto %in% c("Válidamente Emitidos", "Votos Nulos", "Votos en Blanco", "Total Votación"), TRUE, FALSE)) |> 
  mutate(tipo_pacto = ifelse(lista_pacto |> str_detect("^\\w+-\\w+"), TRUE, FALSE)) |> 
  # corregir cifras
  mutate(votos = votos |> str_remove("\\.") |> as.numeric(),
         porcentaje = porcentaje |> str_remove("%$") |> as.numeric(),
         porcentaje = porcentaje / 100) |> 
  # recalcular total de votos
  group_by(comuna) |> 
  mutate(total_votos = sum(votos)) |> 
  print(n=Inf)


# sacar pactos y totales ----
tabla_6 <- tabla_5 |> 
  # select(-repetido) |> 
  # pasar fila con lista a columna
  mutate(lista = ifelse(tipo_pacto, lista_pacto, NA)) |> 
  fill(lista, .direction = "down") |> 
  mutate(lista = ifelse(tipo_totales, NA, lista)) |> 
  filter(!tipo_pacto) |> 
  select(-tipo_pacto) |> 
  # filtrar pacto independientes
  filter(lista_pacto != "CANDIDATURAS INDEPENDIENTES") |> 
  # filtrar totales
  filter(lista_pacto != "Total Votación",
         lista_pacto != "Válidamente Emitidos") |> 
  # arreglar candidatos
  rename(candidato = lista_pacto) |> 
  mutate(candidato = str_remove(candidato, "^\\d+"),
         candidato = candidato |> str_trim(),
         candidato = str_to_title(candidato))

# sumar nulos y blancos ----
tabla_7 <- tabla_6 |> 
  # mutate(partido2 = ifelse(tipo_totales, "Nulo/Blanco", paste(candidato, partido))) |> 
  mutate(candidato = ifelse(tipo_totales, "Nulo/Blanco", candidato)) |> 
  group_by(comuna, candidato, partido, lista) |> 
  summarize(votos = sum(votos, na.rm = T),
            porcentaje = sum(porcentaje, na.rm = T),
            mesas_escrutadas = first(mesas_escrutadas),
            mesas_totales = first(mesas_totales), 
            .groups = "drop") |> 
  ungroup()


# calcular porcentajes ----
tabla_8 <- tabla_7 |> 
  group_by(comuna) |> 
  mutate(total_votos = sum(votos)) |> 
  mutate(porcentaje = votos / total_votos) |> 
  mutate(mesas_porcentaje = mesas_escrutadas / mesas_totales) |> 
  # missings a cero
  mutate(across(where(is.numeric), ~replace_na(.x, 0))) |> 
  ungroup()


# sector político ----
source("partidos.R")

tabla_9 <- tabla_8 |> 
  mutate(sector = case_when(partido %in% partidos_izquierda ~ "Izquierda",
                            partido %in% partidos_centro ~ "Centro",
                            partido %in% partidos_derecha ~ "Derecha",
                            partido %in% partidos_independientes ~ "Independiente",
                            .default = "Otros")) |> 
  mutate(sector = case_when(
    # independientes de verdad
    candidato == "Matias Jair Toledo Herrera" ~ "Izquierda",
    candidato == "Catalina San Martin Cavada" ~ "Derecha",
    # chantas que se hacen pasar por independientes
    candidato == "Ivan Poduje Capdeville" ~ "Derecha", # viña
    candidato == "Karla Rubilar Barahona" ~ "Derecha", # puente alto
    candidato == "Daniel Reyes Morales" ~ "Derecha", # la florida
    candidato == "Sebastian Sichel Ramirez" ~ "Derecha",
    candidato == "Marcela Cubillos Sigall" ~ "Derecha",
    .default = sector))


# corregir nombres ----
tabla_10 <- tabla_9 |> 
  mutate(candidato = str_replace_all(candidato,
                                     c("Iraci" = "Irací",
                                       "Matias" = "Matías",
                                       "Martin" = "Martín",
                                       "Ivan" = "Iván",
                                       "Sebastian" = "Sebastián",
                                       "Fernandez" = "Fernández",
                                       "Rios" = "Ríos",
                                       "Ossandon" = "Ossandón",
                                       "Hector" = "Héctor")
  ))


# terminar
datos_todos <- tabla_10
