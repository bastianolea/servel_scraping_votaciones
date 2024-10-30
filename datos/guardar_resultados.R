library(dplyr)

# obtener datos
source("servel_limpiar.R")

# limpiar y guardar
datos_todos |> 
  # reordenar columnas
  relocate(total_votos, .after = votos) |> 
  relocate(mesas_porcentaje, .after = mesas_totales) |> 
  relocate(sector, .after = lista) |> 
  relocate(porcentaje, .after = votos) |> 
  # ordenar candidatos
  mutate(partido = replace_na(partido, ""),
         candidato = fct_reorder(candidato, porcentaje),
         candidato = fct_relevel(candidato, "Nulo/Blanco",after = 0)) |> 
  arrange(comuna, desc(candidato)) |> 
  readr::write_csv2("datos/resultados_alcaldes_2024.csv")
