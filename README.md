# RaidMark - Turtle WoW 1.12

**Autor:** Holle
**Versión:** 0.60
**Servidor:** Turtle WoW (WoW vanilla 1.12 - South Seas server)

---

## 📝 Descripción
**RaidMark** es una mesa de tácticas para raids que permite al **Raid Leader** colocar íconos sobre un mapa 2D táctico del encuentro. Estos se sincronizan en tiempo real con todos los miembros de la raid para coordinar movimientos y estrategias.






## 🛠 Instalación
1. **Cierra el juego** completamente.
2. Copia la carpeta `RaidMark` dentro de:  
   `World of Warcraft\Interface\AddOns\RaidMark\`.
3. **(Opcional):** Puedes usar el link de GitHub e instalarlo desde el launcher de Turtle WoW.

## 🚀 Primeros Pasos

### Abrir el Addon
Escribe en el chat el comando:  
`/rm`  
Esto abre o cierra la ventana de RaidMark, la cual puedes mover libremente.

### Seleccionar el Encuentro
Usa el menú desplegable en la esquina superior izquierda de la toolbar para elegir el mapa.  
**Mapas disponibles:**
* todo AQ40
* todo Naxxramas

## 📍 Gestión de Íconos
El panel derecho organiza los íconos en tres categorías principales:

| Categoría | Íconos Incluidos |
| :--- | :--- |
| **Roles** | Tank, Healer, DPS ranged, DPS melee, Caster y Flecha. |
| **Áreas** | Círculos de tamaños S, M, L y XL. |
| **Miembros** | Listado de miembros con nombre y color de clase. |

* **Colocar:** Haz clic en un ícono del panel y luego haz clic en el mapa donde quieras situarlo.
* **Mover:** Arrastra cualquier ícono directamente en el mapa para actualizar la posición en tiempo real.
* **Eliminar:** Haz clic derecho sobre el ícono que desees quitar.

## ⚙️ Toolbar y Comandos de Chat

### Botones de la Toolbar
* `[ v Encounter ]`: Selección de mapa del encuentro.
* `[ Limpiar ]`: Elimina todos los iconos del mapa de una sola vez.
* `[ Punteros]`: gestiona punteros por RED utiles para explicaciones, El RL tiene asegurado un puntero(rojo), los demas asistentes podran usar 3 punteros adicionales.
* `[ Sync ]`: Solicita al RL el estado actual del mapa (útil al reconectar) tambien sirve (solo si eres RL) para limpiar todos los slots de punteros de los asistentes.
* `[ Assist: ON/OFF ]`: Habilita que los asistentes puedan mover íconos.
* `[ Grid ]`: Habilita una rejilla de manera local para la facil ubicacion de iconos en el lienzo.
* `[ Scale ]`: Boton ciclico para alternar entre "100%, 90%, 80% de escala" útil para jugadores con resoluciones menores a 1080p.

### Comandos de Chat
* `/rm`: Abre o cierra la ventana.

## 🛡 Sistema de Permisos y Red
* **Raid Leader:** Control total sobre mapas, iconos y permisos.
* **Asistente:** Puede mover íconos solo si el RL activó la opción "Assist: ON".
* **Miembro:** Solo visualización; no puede interactuar con el mapa.

La transmisión se realiza por el canal de raid/party con un sistema de seguridad para evitar lag.

## IMPORTANTE: El puntero funciona por red a travez de interpolacion, requiere que no muevas tan rapido el mouse o los receptores veran "saltos" en el rastro del puntero.

## ❓ Solución de Problemas
* **Mapas en negro:** Borra el archivo `Cache.md5` dentro de la carpeta de tu personaje.
* **No funciona:** El addon requiere estar en un grupo o raid para sincronizar y ser usado.
* **No aparece en la lista:** Verifica que la carpeta se llame exactamente `RaidMark`.

---
*RaidMark v0.23 - Hecho con ❤️ para raiders en Turtle WoW*
