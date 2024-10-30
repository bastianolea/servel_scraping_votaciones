# obtener el género de los/as candidatos/as usando una LLM 
library(mall)
library(tictoc)

candidatos <- datos_todos |> 
  select(nombres = candidato, partido, sector) |> 
  distinct()

tic()
resultados <- llm_classify(candidatos,
             nombres,
             labels = c("masculino", "femenino"),
             pred_name = "genero")
toc()
# 5.8 minutos

resultados |> 
  filter(nombres != "Nulo/Blanco") |> 
  relocate(genero, .before = nombres) |> 
  slice_sample(n = 20)

resultados |> 
  count(sector, genero) |> 
  group_by(sector) |> 
  mutate(p = n/sum(n)*100) |> 
  select(-n) |> ungroup() |> 
  tidyr::pivot_wider(names_from = genero, values_from = p) |> 
  arrange(desc(femenino))

readr::write_csv2(resultados, "datos/candidaturas_genero.csv")
