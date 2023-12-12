import 'package:flutter/material.dart';
import 'package:proyectofinal/autenticacion/inscripcion.dart';
import 'package:proyectofinal/proyectogeneral.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class login extends StatefulWidget {
  const login({super.key});

  @override
  State<login> createState() => _loginState();
}

class _loginState extends State<login> {
  final usuario = TextEditingController();
  final password = TextEditingController();
  final nombreReal = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Login"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FutureBuilder<String>(
                  future: obtenerUrlImagenFirebase(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else {
                      return Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(snapshot.data!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }
                  },
                ),
                SizedBox(height: 20,),
                TextField(
                  controller: usuario,
                  decoration: InputDecoration(
                      labelText: "Ingresa usuario",
                      prefixIcon: Icon(Icons.verified_user)),
                ),
                SizedBox(height: 20,),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: "Ingresa contraseña",
                      prefixIcon: Icon(Icons.password)),
                ),
                SizedBox(height: 20,),
                SizedBox(
                  width: 150,
                  height: 60,
                  child: ElevatedButton(
                      onPressed: () async {
                        // Llamada a la función para autenticar al usuario
                        var resultadoAutenticacion = await autenticarUsuario();
                        bool autenticado = resultadoAutenticacion['success'];
                        String userID = resultadoAutenticacion['userID']??'';
                        if (autenticado) {
                          Navigator.push(context, MaterialPageRoute(builder: (builder) {
                                return paginaPrincipal(userID: userID);
                              }));
                          usuario.text = "";
                          password.text = "";
                        } else {
                          showDialog(
                            context: context,
                            builder: (builder) {
                              return AlertDialog(
                                title: const Text("MENSAJE:"),
                                content: Text(
                                    "Contraseña o usuario incorrecto \n¡¡VUELVA A ESCRIBIR!!"),
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        usuario.text = "";
                                        password.text = "";
                                        Navigator.pop(context);
                                      },
                                      child: const Text("Aceptar"))
                                ],
                              );
                            },
                          );
                        }
                      },
                      child: Text("Autenticar")),
                ),
                SizedBox( height: 20,),
                SizedBox(
                  width: 150,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (builder) {
                        return inscripcionUsuario();
                      }));
                    },
                    child: const Text("Inscribirse"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String> obtenerUrlImagenFirebase() async {
    // Cambia 'imagenes/login.jpg' con la ruta correcta de tu imagen en Firebase Storage
    var ref = firebase_storage.FirebaseStorage.instance.ref('imagenes/login.jpg');
    return ref.getDownloadURL();
  }

  Future<Map<String, dynamic>> autenticarUsuario() async {
    try {
      // Consulta la base de datos para verificar si existe el usuario y la contraseña
      var query = await FirebaseFirestore.instance
          .collection("usuarios")
          .where("usuario", isEqualTo: usuario.text)
          .where("password", isEqualTo: password.text)
          .get();

      // Si encuentra resultados, el usuario y la contraseña son correctos
      if (query.docs.isNotEmpty) {

        var userID = query.docs.first.id;
        return {'success': true, 'userID': userID};
      } else {
        return {'success': false};
      }
    } catch (e) {
      // Maneja cualquier error que pueda ocurrir durante la consulta
      print("Error de autenticación: $e");
      return {'success': false};
    }
  }

}
