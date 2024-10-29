source("servel_limpiar.R")


datos_todos |> filter(comuna == "RENCA")


# mayores votos
datos_todos |> 
  group_by(comuna) |> 
  slice_max(votos) |> 
  arrange((votos)) |> 
  select(1:8)

# menores votaciones
datos_todos |> 
  group_by(comuna) |> 
  slice_max(votos) |> 
  arrange(votos) |> 
  select(1:8)

# top perdedores
datos_todos |> 
  select(1:6) |> 
  # filter(votos < 50) |> 
  filter(candidato != "Nulo/Blanco") |> 
  group_by(comuna) |> 
  slice_min(votos) |> 
  ungroup() |> 
  # filter(votos < 50) |>
  arrange(votos) |> 
  slice(1:20) |> 
  print(n=Inf) |> 
  gt() |> 
  fmt_percent(porcentaje)

library(gt)

# votos por sector
datos_todos |> 
  group_by(sector) |> 
  summarize(votos = sum(votos)) |> 
  arrange(desc(votos)) |> 
  gt() |> 
  fmt_number(votos, sep_mark = ".", drop_trailing_zeros = TRUE) |> 
  data_color(votos, 
             # target_columns = color, 
             method = "numeric", palette = "viridis")
  
datos_todos |> 
  mutate(partido = ifelse(partido == "", "Ninguno", partido)) |> 
  mutate(sector = case_match(sector, 
                             "Derecha" ~ "Derecha", 
                             "Izquierda" ~ "Izquierda",
                             .default = "Otros")) |> 
  group_by(sector, partido) |> 
  summarize(votos = sum(votos)) |> 
  arrange(sector, desc(votos)) |> 
  mutate(color = "") |> 
  gt() |> 
  fmt_number(votos, sep_mark = ".", drop_trailing_zeros = TRUE) |> 
  data_color(votos, 
             # target_columns = color, 
             method = "numeric", palette = "viridis") |> 
  cols_label(color = "")


