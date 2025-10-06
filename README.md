# Traductor de Lengua de Señas Chilena [TDLDS]

**Lengua de Señas** es una aplicación móvil desarrollada en **Flutter** que permite **traducir gestos de Lengua de Señas Chilena (LSCh)** a texto en tiempo real mediante modelos de inteligencia artificial.  
Su propósito es mejorar la comunicación entre personas sordas y oyentes, promoviendo la inclusión social a través de tecnología accesible.

## OBJETIVOS DEL PROYECTO
Desarrollar una aplicación móvil que:
  - 🎥 Reconozca gestos de la **Lengua de Señas Chilena (LSCh)** mediante video.
  - 🧾 Traduzca los gestos a texto comprensible y claro.
  - 🤝 Promueva la inclusión comunicacional y el acceso equitativo a la información.

## 🚀 Características principales

- 🎥 **Traducción por video:**  
  Permite grabar un video con gestos en lengua de señas para obtener una traducción automática a texto.

- 🧠 **Modelo de IA integrado (TensorFlow Lite):**  
  La app utiliza un modelo entrenado con **YoloV8n** para reconocer gestos, letras y palabras completas.

- 🖼️ **Sección de Gestos Reconocibles:**  
  Presenta una galería con ejemplos visuales de todos los gestos y su correspondiente interpretación en texto.

- 🗂️ **Vista completa del gesto:**  
  Permite visualizar en pantalla completa la imagen y el nombre de cada gesto disponible.

- 🎨 **Diseño accesible y adaptable:**  
  Interfaz moderna, limpia y fácil de usar, optimizada para distintos tamaños de pantalla.

## 📱 Estructura general de la aplicación
```text
lib/
├── main.dart
├── ui/
│   ├── pantalla_principal.dart     # Página principal (inicio de la app)
│   ├── gestos_reconocibles.dart    # Sección con galería de gestos
│   └── vista_completa.dart         # Pantalla para ver cada gesto en detalle
│
├── services/
│   ├── grabar_video.dart           # Servicio para grabar o seleccionar video
│   ├── predecir_video.dart         # Lógica de predicción usando el modelo .tflite
│   └── procesar_video.dart         # Servicio para extraer frames del video
│
├── utils/
│   └── etiquetas.dart              # Lista de etiquetas (nombres de los gestos reconocidos)
│
├── widgets/
│   └── mostrar_resultado.dart      # Widget que muestra la traducción predicha
│
assets/
├── Letras/                         # Carpeta con ejemplos de imágenes de cada gesto (A, B, C, HOLA, etc.)
├── Logo.png                        # Logo de la aplicación
├── MODELO.tflite                   # Modelo de IA entrenado para reconocimiento de gestos
└── data.yaml                       # Archivo auxiliar del dataset
│
pubspec.yaml                        # Archivo de configuración de Flutter
```

## 🛠️ Tecnologías utilizadas
- **Flutter:** Framework para desarrollo de aplicaciones móviles multiplataforma.
- **Dart:** Lenguaje de programación utilizado en Flutter.
- **TensorFlow Lite:** Biblioteca para ejecutar modelos de aprendizaje automático en dispositivos móviles.
- **YOLOv8:** Modelo de detección de objetos utilizado para identificar gestos en los videos.
- **Roboflow:** Plataforma para crear y compartir modelos de IA.
- **Google Colab:** Entorno para entrenar y evaluar modelos de IA en la nube.
- **Android Studio:** Herramienta IDE de desarrollo integrada en Android Studio, utilizada para la creacion y compilación de aplicaciones móviles.

## 📦 Instalación y configuración
1. Clona este repositorio:
   ```bash
   git clone https://github.com/TheDanger01/lengua_de_senas.git
    cd lengua_de_senas
    ```
2. Asegúrate de tener Flutter instalado. Si no lo tienes, sigue las instrucciones en [flutter.dev](https://flutter.dev/docs/get-started/install).
3. Instala las dependencias:
   ```bash
   flutter pub get
   ```
4. Conecta un dispositivo móvil o inicia un emulador.
5. Ejecuta la aplicación:
   ```bash
   flutter run
   ```
   
## 👥 Autores

👨‍💻 **Desarrollador:** [*Wilson Moreno*](https://github.com/TheDanger01)  
🤝 **Colaborador:** [*Brandon Reyes*](https://github.com/bdreyes12)  

📘 *Proyecto de Título 2025*  
🏫 **Universidad del Bío-Bío — Ingeniería Civil Informática**

## 📄 Licencia
Este proyecto está bajo la Licencia MIT. 
Consulta el archivo [LICENSE](LICENSE) para más detalles.