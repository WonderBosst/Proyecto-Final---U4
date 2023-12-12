import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:proyectofinal/autenticacion/login.dart';
import '../servicioremoto.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:math';

class inscripcionUsuario extends StatefulWidget {
  const inscripcionUsuario({super.key});

  @override
  State<inscripcionUsuario> createState() => _inscripcionUsuarioState();
}

class _inscripcionUsuarioState extends State<inscripcionUsuario> {
  File? _selectedImage;
  final usuario = TextEditingController();
  final password = TextEditingController();
  final nombreReal = TextEditingController();
  final urlCarpeta = TextEditingController(); //Aun no lo usas
  final urlImagenPerfil = TextEditingController(); //Aun no lo usas
  late String path; // Declaración de la variable path
  late String nombre; //Nombre del archivo

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Inscripción"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: Column(
            children: [
              // Código para seleccionar Imagen
              ElevatedButton(
                onPressed: () async {

                  //Selección de Archivo
                  final archivoAEnviar = await FilePicker.platform.pickFiles(
                    allowMultiple: false,
                    type: FileType.custom,
                    allowedExtensions: ['png','jpg','jpeg']
                  );

                  //Verificación de Selección
                  if(archivoAEnviar == null){
                    setState(() {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('ERROR! no se selecciono ARCHIVO'),
                        ),
                      );
                    });
                    return;
                  }

                  // Asignación de valores a las variables globales
                  path = archivoAEnviar.files.single.path!!;
                  nombre = archivoAEnviar.files.single.name!!;

                  setState(() {
                    _selectedImage = File(path);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Selecciono imagen'),
                      ),
                    );
                  });
                },
                child: const Text("Seleccionar Imagen"),
              ),
              SizedBox(height: 20),
              // Muestra la imagen seleccionada
              _selectedImage != null
                  ? Image.file(
                _selectedImage!,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              )
                  : Container(),
              SizedBox(height: 20,),
              TextField(
                controller: usuario,
                decoration: InputDecoration(
                    labelText: "Escribe usuario",
                    prefixIcon: Icon(Icons.verified_user)),
              ),
              SizedBox(height: 20,),
              TextField(
                controller: password,
                decoration: InputDecoration(
                    labelText: "Escribe contraseña",
                    prefixIcon: Icon(Icons.password)),
              ),
              SizedBox(height: 20,),
              TextField(
                controller: nombreReal,
                decoration: InputDecoration(
                    labelText: "Escribe tu nombre real",
                    prefixIcon: Icon(Icons.account_box_outlined)),
              ),
              SizedBox(height: 20,),
              SizedBox(
                width: 150,
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    bool autenticado = await autenticarUsuario();
                    if (autenticado) {
                      showDialog(
                        context: context,
                        builder: (builder) {
                          return AlertDialog(
                            title: const Text("MENSAJE:"),
                            content: Text(
                                "El usuario ya existe \n¡¡VUELVA A ESCRIBIR!!"),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    usuario.text = "";
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Aceptar"))
                            ],
                          );
                        },
                      );
                    } else {
                      // Generar el nombre de la carpeta
                      String carpetaNombre = generaNameCarpeta();
                      String carpetaDireccion = "imagenes/${carpetaNombre}";

                      // Crear la carpeta en Firebase Storage
                      /*  final Reference carpetaRef = FirebaseStorage.instance.ref().child("imagenes/$carpetaNombre/imagenes_perfil");
                    await carpetaRef.putString(""); // Subir un archivo vacío para crear la carpeta */

                      //Subida de archivo imagen seleccionada
                      DB.subirArchivo(path, carpetaNombre, nombre);

                      //Creación de JSON para los datos del usuario
                      var JSonTemporal = {
                        'usuario': usuario.text,
                        'password': password.text,
                        'nombre': nombreReal.text,
                        'urlcarpeta': carpetaDireccion,
                        'urlimagenperfil': "imagenes/$carpetaNombre/$nombre",
                        'eventosinvitado': []
                      };

                      //Insertar nuevo usuario en la base de datos de firebase
                      var baseRemota = FirebaseFirestore.instance;

                      baseRemota.collection("usuarios").add(JSonTemporal).then((
                          value) {
                        setState(() {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Se subio usuario e imagen'),
                            ),
                          );
                        });
                      });

                      //Limpieza de datos en los TextField y la imagen
                      setState(() {
                        usuario.text = "";
                        password.text = "";
                        nombreReal.text = "";
                        path = "";
                        nombre = "";
                        _selectedImage = null;
                      });
                    }
                  },
                  child: const Text("Registrarme"),
                ),
              ),
              SizedBox(height: 20,),
              SizedBox(
                width: 150,
                height: 60,
                child: ElevatedButton(onPressed: (){
                  setState(() {
                    usuario.text = "";
                    password.text = "";
                    nombreReal.text = "";
                    path = "";
                    nombre = "";
                    _selectedImage = null;
                  });
                  Navigator.push(context, MaterialPageRoute(builder: (builder) {
                    return login();
                  }));

                },
                    child: const Text("Regresar")),
              )
            ],
          ),
        ),
      ),
    );
  }

  String generaNameCarpeta(){
    final length = 20;
    final letterLowerCase = "abcdefghijklmnopqrstuvwxyz";
    final letterUpperCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    final numbers = "0123456789";

    String chars = "";
    chars += "$letterLowerCase$letterUpperCase$numbers";

    return List.generate(length, (index) {
      final indexRandom = Random.secure().nextInt(chars.length);

      return chars[indexRandom];
    }).join("");
  }

  Future<bool> autenticarUsuario() async {
    try {
      // Consulta la base de datos para verificar si existe el usuario y la contraseña
      var query = await FirebaseFirestore.instance
          .collection("usuarios")
          .where("usuario", isEqualTo: usuario.text)
          .where("password", isEqualTo: password.text)
          .get();

      // Si encuentra resultados, el usuario y la contraseña son correctos
      return query.docs.isNotEmpty;
    } catch (e) {
      // Maneja cualquier error que pueda ocurrir durante la consulta
      print("Error de autenticación: $e");
      return false;
    }
  }
}
