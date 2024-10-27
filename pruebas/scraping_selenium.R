library(dplyr)
library(rvest)
library(RSelenium)

# https://www.rselenium-teaching.etiennebacher.com/#/closing-selenium


driver <- rsDriver(port = 4567L, browser = "firefox", chromever = NULL) # can also be "chrome"

remote_driver <- driver[["client"]]

# remote_driver$open()

remote_driver$navigate("http://www.google.com/ncr")

remote_driver$navigate("https://provisorios.servel.cl")


# apretar botón alcalde
remote_driver$
  findElement("xpath", "/html/body/div/div/header/div/div/div[2]/div/button[2]")$
  clickElement()

# apretar botón división geográfica
remote_driver$
  findElement("xpath", "/html/body/div/div/main/div/div/div[2]/div/div/div/div[1]/div[3]/button")$
  clickElement()

# apretar botón comuna
remote_driver$
  findElement("css selector", ".mb-4 > div:nth-child(1) > div:nth-child(3) > select:nth-child(2)")$
  clickElement()


# obtener opciones del dropdown
webElem <- remote_driver$findElement(using = 'xpath', '//*[@id="app"]/div/main/div/div/div[2]/div/div/div/div[3]/div/div[3]/select')
opts <- webElem$selectTag()
comunas <- opts$text
length(comunas)


tablas <- list()

# seleccionar opción del dropdown
comuna_n = 5

message("obteniendo comuna: ", comunas[comuna_n])

remote_driver$
  findElement("css selector",
              # ".mb-4 > div:nth-child(1) > div:nth-child(3) > select:nth-child(2) > option:nth-child(3)")$
              paste0(".mb-4 > div:nth-child(1) > div:nth-child(3) > select:nth-child(2) > option:nth-child(", comuna_n, ")"))$
  clickElement()
# el numero es la opción

# obtener el código de fuente del sitio
sitio <- remote_driver$getPageSource()

# extraer tabla
tabla <- sitio[[1]] |> 
  read_html() |> 
  html_table()


tabla_2 <- tabla[[1]] |> 
  mutate(comuna = comunas[comuna_n])

tablas[[comuna_n]] <- tabla_2


tablas


# cerrar server
remote_driver$close()
remote_driver$closeServer()


# opts$elements[[4]][[1]]
# opts$value
# opts$value[[4]]$clickElement()


# remote_driver$findElement("id", opts$elements[[4]])$clickElement()
# 
# remote_driver$
#   findElement(using = 'xpath', 
#               '//*[@id="app"]/div/main/div/div/div[2]/div/div/div/div[3]/div/div[3]//*/option[@value = "BUIN"]')$
#   clickElement()
# 
# remote_driver$
#   findElement(using = 'xpath', 
#               "//*[@id='app']/html/body/div/div/main/div/div/div[2]/div/div/div/div[3]/div/div[3]/select[@value = 'BUIN']")$
#   clickElement()

