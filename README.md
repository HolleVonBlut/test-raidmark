# RaidMark — Mesa de Tácticas para Raids

> Addon de World of Warcraft **1.12 / Vanilla** para servidores privados (Turtle WoW).  
> Diseñado para Raid Leaders que necesitan comunicar estrategias visualmente en tiempo real.

---

## ✨ Características principales

- 🗺️ **Mapa táctico interactivo** con 30+ encuentros de AQ40 y Naxxramas
- 🔴 **Iconos de rol** arrastrables: Tank, Healer, DPS, Círculos, Marcas de raid, Calaveras
- 🏹 **Flechas direccionales** (N/S/E/O/NE/NO/SE/SO) con stretch ajustable por rueda del mouse
- 👥 **Panel de raiders** con asignación de roles por clase
- 💾 **Sistema de escenas** — 40 slots locales (10 GrandSlots × 4) para guardar disposiciones
- 🎯 **Modo de posicionamiento** — diseña en offline, sincroniza raiders reales con un click
- 📡 **Sincronización en red** — todo el raid ve los cambios en tiempo real
- 🔇 **Modo Offline** — diseña estrategias sin conexión al raid

---

## 📦 Instalación

1. Descarga el `.zip` desde [Releases](../../releases)
2. Extrae la carpeta `RaidMark` en:  
   `World of Warcraft\Interface\AddOns\`
3. Reinicia el juego o escribe `/reload`
4. Abre con `/rm` o `/raidmark`

---

## 🎮 Uso básico

### Abrir el mapa
```
/rm
```

### Seleccionar un encuentro
Haz click en el botón **▼ Encounter** (esquina superior izquierda del mapa).

### Colocar iconos
1. Selecciona un ícono del panel derecho
2. Haz click izquierdo en el mapa
3. Arrastra para moverlo · Click derecho para eliminar

### Flechas direccionales
- Selecciona una flecha del **dropdown** del botón de flecha
- **Rueda del mouse** sobre el cuadrado verde central = estirar/encoger
- Solo el RL y Assists pueden estirar flechas
- Disponible en **Rojo**, **Blanco** y **Amarillo**

---

## 👥 Roles y permisos

| Rol | Permisos |
|-----|----------|
| **Raid Leader (RL)** | Todo: colocar, mover, borrar, sync, offline, escenas |
| **Assist** | Colocar y mover iconos |
| **Raider** | Solo ver |

Activa permisos de Assist con el botón **Assist: ON/OFF** en la toolbar.

> **Nota:** Al entrar en Modo Offline, el Assist se desactiva automáticamente. Al salir, se restaura al estado que tenía antes.

---

## 💾 Sistema de Escenas

Guarda hasta **40 disposiciones** del lienzo organizadas en:
- **4 slots rápidos** (botones `1 2 3 4`)
- **10 GrandSlots** (dropdown `GS1 ▼`)

### Colores de los slots
- ⬜ **Gris** — vacío
- 🔴 **Rojo** — seleccionado, listo para guardar
- 🟡 **Amarillo** — tiene contenido guardado
- 🟢 **Verde** — mapa de posicionamiento (contiene posiciones de raid)

### Guardar una escena
1. Selecciona un slot (`1`–`4`) → se pone rojo
2. Presiona **[S]** (disquete)

### Cargar una escena
- Click en slot amarillo o verde → se pone naranja
- Click de nuevo → se carga al lienzo y se broadcastea al raid

> **Importante:** Los slots verdes (posicionamiento) cargan los cuadritos de posición **solo localmente** — el raid no los ve hasta que el RL presiona **Sync P**.

---

## 🎯 Modo de Posicionamiento

Diseña dónde va cada rol *antes* del pull, sin necesidad de estar en raid.

### Crear un mapa de posicionamiento

1. Presiona **M Offline** → aparece advertencia → presiona de nuevo para confirmar
2. En el panel de raiders verás los iconos de rol:
   - 🔵 **Tank** · 🟢 **Healer** · 🔴 **DPS Melee** · 🟠 **DPS Rang** · ⬜ **Edit**
3. Coloca hasta **40 posiciones** en el mapa
4. Guarda en un slot → el slot se pinta **verde**
5. Presiona **M Offline** para salir

> Si necesitas ajustar posiciones después, puedes volver al Modo Offline, editar el slot verde y salir — el cambio queda guardado para el siguiente Sync P.

### Usar el mapa en raid

1. **Carga el slot verde** → los cuadritos de posición aparecen en el lienzo *(solo el RL los ve)*
2. Presiona **Sync P** → el addon coloca cada raider en su posición correspondiente

**Reglas del Sync P:**
- Cada cuadrito = exactamente un raider
- Si hay más raiders del mismo rol que cuadritos, los sobrantes no se colocan
- Si hay más cuadritos que raiders, los cuadritos sobrantes permanecen visibles
- **Se puede presionar Sync P múltiples veces** sin riesgo de duplicados — por ejemplo cuando se conectan raiders tarde. Cada vez limpia las posiciones anteriores y recoloca desde cero
- Los cuadritos de posición siempre quedan visualmente *debajo* de los raiders reales
- Los cuadritos solo desaparecen al presionar **Limpiar**

> **Flujo recomendado para raids en progreso:**
> 1. Carga el slot verde una vez al inicio
> 2. A medida que llegan raiders y se asignan roles, presiona Sync P cuantas veces necesites
> 3. Si quieres reorganizar posiciones: entra a Modo Offline → edita el slot → sal → vuelve a cargar el slot → Sync P

---

## 🤖 Auto-asignación de roles

El RL puede asignar roles automáticamente via chat de raid (`/raid`).

> **Los roles asignados se guardan entre sesiones.** Sobreviven a `/reload`, al Modo Offline y al cierre del juego. Si un raider cambia de rol (respondiendo a un nuevo auto-assign), el nuevo rol sobreescribe el anterior sin afectar a los demás.

### Botones individuales (10 segundos)

Presiona **Healer**, **DD M**, **DD R** o **Tank**.  
Sale en `/rw`:  
*"Todos los Healers escriban [1] en /raid — tienes 10 segundos"*

Los últimos **3 segundos** se spamea la cuenta regresiva.  
Solo escucha el canal `/raid`.

### Auto-Total (20 segundos)

Pide todos los roles a la vez:

*"Escribe tu número: 1=Healer // 2=DPS Melee // 3=DPS Rango // 4=Tank"*

Al terminar reporta cuántos del total respondieron.  
Las respuestas **sobreescriben** el rol anterior raider por raider.

| Número | Rol |
|--------|-----|
| `1` | Healer |
| `2` | DPS Melee |
| `3` | DPS a Rango |
| `4` | Tank |

---

## 🔇 Modo Offline

Permite diseñar estrategias sin afectar al raid ni requerir estar en grupo.

**Al entrar:**
- Se limpia el lienzo (aviso previo en el box informativo)
- Si hay Assist activo, se desactiva automáticamente
- Toda comunicación de red queda bloqueada
- El box muestra `[ MODO OFFLINE ]` en rojo periódicamente

**Al salir:**
- Se limpia el lienzo nuevamente
- El Assist se restaura si estaba activo antes

**Funciones bloqueadas en Modo Offline:**
- Sync · Auto-assign · Auto-Total · Sync P

**Funciones disponibles:**
- Sistema de escenas (guardar/cargar slots) · Grid · Iconos · Flechas · Panel de raiders (muestra iconos de rol en lugar de raiders reales)

---

## 🗺️ Encuentros incluidos

**AQ40:** Twin Emperors · C'Thun Exterior · C'Thun Estómago · Skeram · Ouro · Huhuran · Viscidus · Fankriss · Sartura · Bug Trio

**Naxxramas:** Anub'Rekhan · Faerlina · Maexxna · Noth · Heigan · Loatheb · Razuvious · Gothik · 4 Horsemen · Patchwerk · Grobbulus · Gluth · Thaddius · Sapphiron · Kel'Thuzad

---

## ⚙️ Comandos slash

| Comando | Función |
|---------|---------|
| `/rm` | Abrir / cerrar el mapa |
| `/rm clear` | Limpiar todos los iconos |
| `/rm map <key>` | Cambiar mapa (ej: `twin_emperors`) |
| `/rm assist on/off` | Habilitar/deshabilitar permisos de Assist |

---

## 🔧 Requisitos

- World of Warcraft **1.12.1** (Vanilla)
- Servidor: **Turtle WoW** u otro servidor 1.12 compatible
- Se requiere ser **Raid Leader** para la mayoría de funciones

---

## 📝 Notas técnicas

- Protocolo de red propio via `SendAddonMessage` con separador `;`
- SavedVariables: `RaidMarkDB` (configuración + roles) · `RaidMarkSceneDB` (escenas)
- Los roles de raid persisten en disco — sobreviven a `/reload` y reinicios
- Compatible con grupos de party (no solo raids)
- Los iconos de flechas usan TGAs personalizados de 256×256
- Límite de 40 posiciones de rol en Modo Offline por sesión

---

## 👤 Autor

**Holle** — Turtle WoW  
*"By Holle - South Seas Server"*
