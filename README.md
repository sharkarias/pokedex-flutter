# Pokedex

Este git ha sido realizado por María Tiburcio y Fernando Rodríguez.

Este proyecto se basa en la realización de una Pokedex con la capacidad de:
-visualizar la lista de pokemones usando el api PokeAPI
-filtrar y ordenar dicha lista según el gusto de la persona
-desarrollar la información de los pokemones seleccionados, sus estadísticas básicas, habilidades, evoluciones, daño por tipo, versión shiny, etc.
-lista de pokemones favoritos guardados en persistencia local
-juego interactivo de "¿Quién es ese pokemón?", que presenta la puntuación más alta de las personas utilizando la aplicación de forma local, además de su top 10 puntuaciones más altas.

# Decisiones del diseño

Decidimos dividir nuestro proyecto en formas que logremos identificar rápidamente qué es exactamente lo que debería estar realizando cada uno de nuestros documentos. Por instancia, 

/database : nos ayuda a organizar la información relevante para las persistencias locales dentro de nuestra aplicación.
/models : es donde guardamos nuestro DTO.
/screens : aquí tenemos todas las pantallas presentes dentro de la pokedex, como lo son la pantalla de favoritos, la de detalles específicos del pokemon, la lista de pokemones y el área interactiva de quién es ese pokemon.
/service : todo lo relevante a graphQL y llamar a la API dentro de nuestra aplicación, de una forma más dividida y concreta.

