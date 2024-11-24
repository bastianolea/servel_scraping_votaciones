# obtener el género de los/as candidatos/as usando una LLM 
library(mall)
library(dplyr)
library(tictoc)

# cargar
candidatos <- readr::read_csv2("datos/resultados_alcaldes_2024.csv")


# con nombres y apellidos
tic()
resultados <- candidatos |> 
  select(nombres = candidato, partido, sector) |>
  distinct(nombres, .keep_all = TRUE) |> 
  llm_classify(nombre,
               labels = c("masculino", "femenino"),
               pred_name = "genero")
toc()
# 5.8 minutos


# solo con nombres
tic()
resultados <- candidatos |> 
  select(nombres = candidato, partido, sector) |>
  distinct(nombres, .keep_all = TRUE) |> 
  mutate(nombre = stringr::str_extract(nombres, "\\w+")) |> 
  llm_classify(nombre,
               labels = c("masculino", "femenino"),
               pred_name = "genero")
toc()
# 1.7 minutos

# revisar resultados
resultados |> 
  filter(nombres != "Nulo/Blanco") |> 
  relocate(genero, nombre, .before = nombres) |> 
  slice_sample(n = 20)
# se equivoca en: Aracelli, Edita, Elizabeth

# contar género por sector político
resultados |> 
  count(sector, genero) |> 
  group_by(sector) |> 
  mutate(p = n/sum(n)*100) |> 
  select(-n) |> ungroup() |> 
  tidyr::pivot_wider(names_from = genero, values_from = p) |> 
  arrange(desc(femenino))

# guardar resultados
readr::write_csv2(resultados, "datos/candidaturas_genero.csv")
