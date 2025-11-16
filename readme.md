# Resultados de votaciones de Servel por medio de web scraping

Flujo de R que scrapea datos desde el Servel, limpia los datos, y retorna visualizaciones en gráficos y tablas.

----

## Elecciones presidenciales y de diputados/as 2025

Scripts:
1. `servel_scraping_presidenciales.R`
2. `servel_limpiar_presidenciales.R`

----

## Elecciones Regionales 2024: Gobernadores regionales

![Mapa de resultados comunales de elección de gobernadores 2024](selección/servel_mapa_rm_p_resultados_2024-11-25.jpg)

Por las elecciones de Gobernadores de 2ª vuelta, nuevamente hice una pequeña cobertura en tiempo real de los resultados electorales. 

Modifiqué el sistema de web scrapping y generación automática de gráficos y tablas que usé para las elecciones regionales de octubre, esta vez enfocándome en resultados comunales y ventajas porcentuales. En menos de media hora ya había adaptado el sistema de la elección anterior para obtener los datos nuevos, ubicados en un sitio distinto, y adaptados a una elección de características diferentes. Mientras los datos se iban scrapeando automáticamente, pude dedicarme a desarrollar nuevas visualizaciones para presentar los resultados, conectar estas visualizaciones al flujo de trabajo, y empezar a obtenerlas de forma automática.

![resultados comunales de elección de gobernadores 2024](selección/servel_grafico_barras_2024-11-25.jpg)

Lamentablemente para mi (pero afortunadamente para el Servel) el conteo fue extremadamente rápido, así que solo pude hacer 3 o 4 actualizaciones de datos/visualizaciones y los conteos ya habían llegado a sobre el 95% de mesas escrutadas 🥲

![](selección/servel_tabla_Independencia_24-11-24_2003.png)

Es demasiado satisfactorio cuando se llega a un flujo de trabajo y procesamiento de datos donde solo se necesita especificar uno o dos parámetros, presionas ejecutar, y el sistema corre solo, entregándote resultados unos segundos más tarde con el sonido de una campanita. Y gracias a un desarrollo precabido, es posible tomar sistemas que fueron desarrollados para un fin, y adaptarlos para otro nuevo objetivo.

Todo el sistema de obtención de datos y visualización fue desarrollado en R.

![](selección/servel_grafico_Santiago_24-11-24_2003.jpg)

----

## Elecciones Municipales 2024: Alcaldes

![](selección/servel_resultados_multi_28-10-24_1054_c2.png)


Con motivo de las elecciones municipales, estuve generando algunas visualizaciones ”en tiempo real” de los resultados de las elecciones de alcaldías. 

![](selección/servel_grafico_Peñalolen_28-10-24_0101.jpg)

Los datos de conteo de votos los fui obteniendo minuto a minuto mediante web scraping con {RSelenium}, que permite programar un navegador web para que interactúe con un sitio como si fuera humano. Entonces, el navegador robot (marioneta, le llaman) iba apretando todos los botones, sin intervención de mi parte, para encontrar y copiar los resultados de cada comuna del país.

![](selección/servel_tabla_Las_Condes_28-10-24_0006.png)

Los nuevos resultados llegaban con frecuencia, así que había que echar a correr el proceso bajo presión, cada 10 minutos aprox. Todo iba bien: presionaba ejecutar, el proceso pasaba por todas las comunas, limpiaba los datos y retornaba visualizaciones. Hasta que, en la mitad del conteo, el sitio del Servel cambió! Por algún motivo, cambiaron a una versión similar del sitio, pero que internamente funcionaba distinto, entonces se desconfiguró todo el web scraping. Tuve que luchar contra el tiempo para reestablecerlo (terrible para mi, porque estaba aprendiendo Selenium 😭). Lo otro que me jugó en contra fue que no se me ocurrió automatizar la redacción de textos y posteo en redes sociales, que al final fue lo que me quitó más tiempo 😒

También faltó hacer visualizaciones más entretenidas, pero se hizo lo que se pudo para una idea que salió a la rápida. Es gratificante hacer andar un flujo largo de procesamiento de datos solo con un par de comandos, desde la obtención de los datos hasta que te arroja decenas o cientos de salidas ✨

![](selección/servel_grafico_Puente_Alto_27-10-24_2314.jpg)

Para los nerds, usé {RSelenium} para un script que recibía un vector de comunas e iteraba por ellas con {furrr}, y retornaba una lista con la tabla de resultados, el párrafo de las mesas escrutadas, y el nombre de la comuna. Luego, otro script de R cargaba el scraping más reciente y limpiaba los datos, calculaba porcentajes, coincidía partidos con sectores políticos, corregía a "independientes" que en realidad tienen sector político claro, arreglaba nombres (Servel usa eñes pero no tildes, por alguna razón), interpretaba el texto de las mesas como cifras individuales, sumaba votos nulos y blancos, entre otras cosas. Después tenía un script desde el que comandaba todos los demás pasos, que para partir borraba todas las salidas antiguas, y según las comunas que le pedía, generaba nuevos gráficos/tablas en una carpeta nueva. Sobre los gráficos y tablas, nada interesante, salvo que el alto de los gráficos dependía de la cantidad de candidatos, para que siempre mantuvieran espaciados correctos y no se deformaran si eran muchos o muy pocos candidatos/as.

Finalmente, el flujo de procesamientos de datos en R generó 238 gráficos y 240 tablas, de las cuales les comparto algunas. Esa fue mi experiencia intentando generar reportes en tiempo real sobre datos de elecciones. Para la siguiente votación espero tener algo más elaborado!


## Alcaldes electos en la Región Metropolitana
![](selección/servel_tabla_ganadores_rm_28-10-24_1054.png)

## Alcaldes de izquierda electos
![](selección/servel_tabla_ganadores_izq_28-10-24_1054.png)


----

## Funcionamiento

Los scripts `servel_scraping_x.R` realizan un web scraping (utilizando `{RSelenium}`) del sitio del Servel indicado que contengan los resultados. Los primeros pasos que los scrapping son apretar que el navegador automatizado y controlado por Selenium entre los resultados deseados, seleccione la desagregación geográfica, y obtenga las comunas disponibles para ver sus resultados. Luego se realiza una alteración a través de todas las comunas disponibles, donde el navegador automatizado entra a cada una de las comunas, da unos segundos de espera, y descarga la tabla de resultados y los párrafos de texto sobre las mesas escrutadas.

Posteriormente, el script `servel_limpiar.R` realiza una serie de operaciones de limpieza procesamiento de datos para dejar los datos disponibles para su visualización y análisis. Éste script carga automáticamente los datos scrapeados más recientes, permitiendo poder hacer un scraping constante y luego ejecutar este script para dejar los datos procesados. Dentro de este script:

- Calcular las mesas escrutadas a partir de la extracción de texto de un párrafo
- Categorizar las filas de datos que no corresponden a candidatos, sino a actos y a votos nulos o blancos
- Enviar las filas de información de pactos y votos totales a columnas
- Sumar los votos nulos y blancos en una sola categoría
- Calcular los porcentajes de votos y de mesas
- Clasificar los partidos políticos por sectores políticos
- Corregir determinados candidatos políticos a sectores políticos específicos, en consideración de que últimamente muchos candidatos políticos de marcada ideología y trayectoria en partidos políticos se postulan como independientes
- Corregir los nombres de algunos candidatos y candidatas, en consideración de qué el servil no incluye tildes en sus datos

Teniendo los datos procesados, se puede ejecutar el script `generar.R`, al cual se le especifica un vector de comunas de interés, y el script automáticamente produce gráficos y tablas para las comunas especificadas. Las visualizaciones resultantes se guardan en la carpeta apropiada para la elección, dentro de la carpeta del tipo de visualización correspondiente, y también son copiados a la carpeta `salidas`. La carpeta `salidas` es vaciada de contenidos cada vez que se ejecuta el script `generar.R`, asumiendo que no son necesarias las visualizaciones anteriores, dado que las visualizaciones generadas serían versiones actualizadas de las mismas, o de comunas distintas. Esto es muy útil para ir haciendo un reporte en tiempo real de los resultados, debido a que la ejecución del script `generar.R` produciría visualizaciones con los datos actualizados, y solamente de las comunas que deseas comunicar a continuación, ofreciéndotelas en una carpeta donde es fácil encontrarlas.

También se pueden ejecutar otros scripts de visualización de datos agrupados tales como:
- `grafico_barras.R`, que genera un gráfico de barras con los porcentajes de candidaturas por comuna
- `torta_x.R` que produce visualizaciones de torta o dona con la cantidad total de votos por sector, por partido, etc.
- `mapa_chile.R` que genera un mapa de Chile continental con resultados por comuna
- `mapa_rm.R`, `mapa_gobernadores_rm.R`, y `mapa_gobernadores_rm_p.R`, que generan mapas de la Región Metropolitana (perímetro urbano de la zona urbana de las comunas de la región metropolitana) con resultados por comuna, y con diferencia o margen de votos 


----

La licencia de este código permite el uso libre del mismo por parte de individuos y organizaciones, siempre y cuando vuelvan a publicar el código bajo la misma licencia si es que realizan cambios o mejoras al código. No se permite el uso comercial, privado, o remunerado de estos datos ni de este código. Para usar este código para servicios remunerados o por parte de privados, deben [ponerse en contacto conmigo.](https://bastianolea.rbind.io/contact/)