import 'dart:math';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:proyectofinal/autenticacion/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectofinal/modelos/eventobuscado.dart';
import 'package:proyectofinal/servicioremoto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

class paginaPrincipal extends StatefulWidget {
  final String userID;

  const paginaPrincipal({required this.userID, Key? key}) : super(key: key);

  @override
  State<paginaPrincipal> createState() => _paginaPrincipalState();
}

class _paginaPrincipalState extends State<paginaPrincipal> {

  //Variables para almacenar datos del usuario
  String nombreUsuario = "";
  String urlImagenPerfil = "";
  String urlCarpetaPersonal = "";

  //Variables de uso global
  File? _selectedImage;
  late String path;
  late String nombreImagen;
  int _index = 0;
  DateTime fechaYaPasoSiONo = DateTime.now();
  final propiedadDe = TextEditingController();
  final descripcion = TextEditingController();
  final tipoEvento = TextEditingController();
  DateTime fechaInicio = DateTime.now();
  DateTime fechaFinal = DateTime.now();
  final codigo = TextEditingController();
  int fechaProvisionalFinal = 0;
  final eventoEscogido = TextEditingController();
  final tipoEventoEscogido = TextEditingController();
  final codigoEscritoAEvento = TextEditingController();
  String eventoBuscado = "";

  List<String> tipoEventoOptions = ['Boda','Fiesta casual','Cumpleaños','Quinceañera','Posada navideña','Fiesta de halloween','Fiesta de playa','Fiesta patria','Bautizo','Aniversario','Otro'];
  String selectedTipoEvento = 'Boda';
  bool light1 = true;
  bool bloquear = false;
  bool eventoBloqueadoSiONo = false;
  bool isVisible = true;
  bool permisoEventoFecha = false;

  // Función para obtener datos del usuario desde Firestore
  Future<void> obtenerDatosUsuario() async {
    try {
      var document = await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(widget.userID)
          .get();

      if (document.exists) {
        // Actualizar los datos del usuario
        setState(() {
          nombreUsuario = document['nombre'];
          urlImagenPerfil = document['urlimagenperfil'];
          urlCarpetaPersonal = document['urlcarpeta'];
        });
      }
    } catch (e) {
      print("Error al obtener datos del usuario: $e");
    }
  }

  @override
  void initState(){
    obtenerDatosUsuario();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Album"),
        centerTitle: true,
      ),
      body: dinamico(),
      drawer: Drawer(
        child: ListView(
          padding:  EdgeInsets.zero,
          children: [
            DrawerHeader(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FutureBuilder(
                    future: DB.obtenerURLimagen(urlImagenPerfil),
                    builder: (context, URL){
                      if(URL.hasData){
                        return Container(
                          width: 100,
                          height: 100,
                          child: Image.network(URL.data!, fit: BoxFit.cover,),
                        );
                      }
                      return CircularProgressIndicator();
                    }),
                SizedBox(height: 10,),
                Text(nombreUsuario,
                  style: TextStyle(color: Colors.white, fontSize: 20),),
              ],
            ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            _itemDrawer(Icons.list, "Mis eventos", 0),
            _itemDrawer(Icons.insert_invitation, "Mis invitaciones", 1),
            _itemDrawer(Icons.add, "Crear evento", 2),
            _itemDrawer(Icons.settings, "Configurar perfil", 3),
            _itemDrawer(Icons.arrow_back, "Salir", 9),
          ],
        ),
      ),
    );
  }
  
  Widget dinamico(){
    switch(_index){
      case 0: {return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              child: Text(
                "Mis eventos",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, color: Colors.red),
              ),
            ),
            Expanded(
              child: misEventos(),
            ),
          ],
        );}
      case 1: {return misInvitaciones();}
      case 2: {return crearEvento();}
      case 3: {return configuracionPerfil();}
      case 4: {return agregarEvento();}
      case 5: {return invitacionesAEventos();}
      case 6: {return muestraCodigo();}
      case 7: {return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              child: SelectableText(
                "${tipoEventoEscogido.text}\n Codigo: ${eventoEscogido.text.replaceAll('eventos/','')}",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.red),
              ),
            ),
            Expanded(
              child: muestraImagenesEvento(eventoEscogido.text),
            ),
            SizedBox(height: 5,),
            ElevatedButton(onPressed: (){
              setState(() {
                if(eventoBloqueadoSiONo == false){
                  eventoBloqueadoSiONo = true;
                } else{
                  eventoBloqueadoSiONo = false;
                }
              });
              DB.actualizarEstadoEvento(eventoEscogido.text, eventoBloqueadoSiONo).then((_) {
                print('Estado del evento actualizado correctamente');
              }).catchError((error) {
                print('Error al actualizar el estado del evento: $error');
              });
            },
                child: Text("${eventoBloqueadoSiONo ? "Bloqueado" : "Desbloqueado"}")),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: () async{
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
                  nombreImagen = archivoAEnviar.files.single.name!!;

                  DB.subirArchivoAEvento(path, eventoEscogido.text, nombreImagen).then((value){
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Se subio imagen al evento'),
                      ),
                    );
                  });
                }, child: const Text("Agregar imagen")),
                SizedBox(width: 5,),
                ElevatedButton(onPressed: (){
                  setState(() {
                    _index = 0;

                    //Limpia controladores
                    eventoEscogido.text = "";
                    tipoEventoEscogido.text = "";
                  });
                }, child: const Text("Regresar")),
                SizedBox(width: 5,),
              ],
            )],
        );}
      case 8: {return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            child: Text(
              "${tipoEventoEscogido.text}\n",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.red),
            ),
          ),
          Expanded(
            child: muestraImagenesEvento("eventos/${eventoEscogido.text}"),
          ),
          SizedBox(height: 5,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Visibility(
                visible: isVisible,
                child: ElevatedButton(onPressed: () async{

                  //Selección de Archivo
                  final archivoAEnviar = await FilePicker.platform.pickFiles(
                    allowMultiple: false,
                    type: FileType.custom,
                    allowedExtensions: ['png','jpg','jpeg']);

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
                  nombreImagen = archivoAEnviar.files.single.name!!;

                  DB.subirArchivoAEvento(path, "eventos/${eventoEscogido.text}", nombreImagen).then((value){
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Se subio imagen al evento'),
                    ),
                  );
                });
                  }, child: const Text("Agregar imagen")),),
              SizedBox(width: 5,),
              ElevatedButton(onPressed: (){
                setState(() {
                  _index = 5;

                  //Limpia controladores
                  eventoEscogido.text = "";
                  tipoEventoEscogido.text = "";
                  descripcion.text = "";
                });
              }, child: const Text("Regresar")),
              SizedBox(width: 5,),
            ],
          )],
      );}
      default: {return Center();}
    }
  }

  Widget _itemDrawer(IconData icono, String titulo, int indice) {
    return ListTile(
      onTap: (){
        setState(() {
          fechaProvisionalFinal = fechaFinal.day;
          _index = indice;
        });
        if(_index != 9) {
          Navigator.pop(context);
        } else{
          Navigator.push(context, MaterialPageRoute(builder: (builder){
            return login(); }) );
        }
      }, //onTap
      title: Row(
        children: [
          Expanded(child: Icon(icono, size: 30,),),
          Expanded(child: Text(titulo,
            style: TextStyle(fontSize: 20),),
            flex: 2,
          ),
        ],
      ),
    );
  }

  //Seccion de los widgets que se mostraran en el body
  Widget muestraImagenesEvento(String eventoEscogido) {
    return FutureBuilder(
      future: DB.obtenerURLImagenes(eventoEscogido),
      builder: (context, listaImagenes) {
        if (listaImagenes.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (listaImagenes.hasError) {
          return Text('Error al cargar imágenes');
        } else {
          List<String> urls = listaImagenes.data as List<String>;

          List<Widget> imagenes = urls.map<Widget>((url) => GestureDetector(
            onTap: () {
              mostrarModal(context, url);
            },
            child: Image.network(url),)).toList();

          return GridView.extent(
            maxCrossAxisExtent: 100,
            padding: EdgeInsets.all(4),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: imagenes,
          );
        }
      },
    );
  }

  Widget muestraCodigo(){
    return Container(
      padding: EdgeInsets.all(50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Link hacia evento",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12,),
          TextField(
            controller: codigo,
            readOnly: true,
            enableInteractiveSelection: false,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              suffixIcon: IconButton(onPressed: (){
                final data = ClipboardData(text: codigo.text);
                Clipboard.setData(data);

                final snackBar = SnackBar(
                  content: Text("Link de evento copiado",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.teal,
                );

                ScaffoldMessenger.of(context)
                  ..removeCurrentSnackBar()
                  ..showSnackBar(snackBar);
              },
                icon: Icon(Icons.copy),),
            ),
          ),
        ],
      ),
    );
  }

  Widget misEventos(){
    return FutureBuilder(
        future: DB.mostrarTodosEventosMios(widget.userID),
        builder: (context, listaEventosMios){
          if(listaEventosMios.hasData){
            return ListView.builder(
              itemCount: listaEventosMios.data?.length,
                itemBuilder: (context, indice){
                return ListTile(
                  title: Text("${listaEventosMios.data?[indice].tipoEvento}"),
                  subtitle: Text("${listaEventosMios.data?[indice].descripcion}"),
                  onTap: (){
                    eventoEscogido.text = "${listaEventosMios.data?[indice].urlCarpetaEvento}";
                    tipoEventoEscogido.text = "${listaEventosMios.data?[indice].tipoEvento}";
                    eventoBloqueadoSiONo = listaEventosMios.data![indice].eventoBloqueado;
                    setState(() {
                      _index = 7;
                    });
                  },
                );
              });
          }
          return CircularProgressIndicator();
        });
  }
  
  Widget misInvitaciones(){
    return ListView(
      padding: EdgeInsets.all(50),
      children: [
        Container(
          color: Colors.grey,
          padding: const EdgeInsets.all(20),
          child: Text("Bienvenido a invitaciones",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30, color: Colors.white),
          ),
        ),
        SizedBox(height: 20,),
        ElevatedButton(
            onPressed: (){
              setState(() {
                _index = 4;
              });
            },
            child: const Text("Agregar evento")),
        SizedBox(height: 20,),
        ElevatedButton(
            onPressed: (){
              setState(() {
                _index = 5;
              });
            },
            child: const Text("Ver invitaciones a eventos")),
      ],
    );
  }

  Widget crearEvento(){
    return ListView(
      padding: EdgeInsets.all(40),
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          child: Text("EVENTO NUEVO",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30, color: Colors.red),
          ),
        ),
        SizedBox(height: 10,),
        Text("DESCRIPCION:"),
        SizedBox(height: 2,),
        TextField(
          controller: descripcion,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 5,),
        Text("FECHA INICIO:"),
        SizedBox(height: 2,),
        ElevatedButton(onPressed: pickDateTimeFecha1,
            child: Text("${fechaInicio.year}/${fechaInicio.month}/${fechaInicio.day} - 12:00 am")),
        SizedBox(height: 5,),
        Text("TIPO EVENTO:"),
        SizedBox(height: 2,),
        DropdownButton<String>(
          value: selectedTipoEvento,
          items: tipoEventoOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedTipoEvento = newValue!;
            });
          },
        ),
        SizedBox(height: 5,),
        Text("FECHA FINAL:"),
        SizedBox(height: 2,),
        ElevatedButton(onPressed: pickDateTimeFecha2,
            child: Text("${fechaFinal.year}/${fechaFinal.month}/${fechaProvisionalFinal} - 11:59 pm")),
        SizedBox(height: 5,),
        Text("PERMITIR AGREGAR FOTOS DESPUES DE LA FECHA FINAL"),
        SizedBox(width: 2,),
        Switch(
          activeColor: Colors.blue,
          activeTrackColor: Colors.blueGrey,
          inactiveThumbColor: Colors.black87,
          value: light1,
          onChanged: (value) {
          setState(() {
            light1 = value;
          });
        },
          ),
        ElevatedButton(
          onPressed: () async{
            if (descripcion.text.isEmpty ) {
              // Si está vacío, puedes mostrar un mensaje de error
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Campo vacio"),
                    content: Text("Por favor escriba la descripción"),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text("Aceptar"),
                      ),
                    ],
                  );
                },
              );
            } else {

              DateTime fechaInicioSinHora = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
              DateTime fechaFinalSinHora = DateTime(fechaFinal.year, fechaFinal.month, fechaFinal.day);

              // Validación para asegurarse de que fechaFinal y fechaInicio no sean el mismo dia
              if (fechaInicioSinHora != null && fechaFinalSinHora.isAtSameMomentAs(fechaInicioSinHora)) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Fechas incorrectas"),
                      content: Text("Las fechas no pueden coincidir el mismo día"),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text("Aceptar"),
                        ),
                      ],
                    );
                  },
                );
                return;
              }

              // Validación para asegurarse de que fechaInicio no sea despues de fechaFinal
              if (fechaFinalSinHora != null && fechaInicioSinHora.isAfter(fechaFinalSinHora)) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Fechas incorrectas"),
                      content: Text("La fecha de inicio no puede ser posterior a la fecha final"),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text("Aceptar"),
                        ),
                      ],
                    );
                  },
                );
                return;
              }

              // Validación para asegurarse de que fechaFinal no sea antes de fechaInicio
              if (fechaInicioSinHora != null && fechaFinalSinHora.isBefore(fechaInicioSinHora)) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Fechas incorrectas"),
                      content: Text("La fecha final no puede ser anterior a la fecha inicio"),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text("Aceptar"),
                        ),
                      ],
                    );
                  },
                );
                return;
              }

              // Generar el nombre de la carpeta
              String carpetaNombre = generaNameCarpeta();
              //String carpetaDireccion = "${urlCarpetaPersonal}/${carpetaNombre}";
              String carpetaDireccion = "eventos/${carpetaNombre}";

              // Crear la carpeta en Firebase Storage
              final Reference carpetaRef = FirebaseStorage.instance.ref().child("${carpetaDireccion}");
              await carpetaRef.putString(""); // Subir un archivo vacío para crear la carpeta

              //Agregación del evento
              var agregarEvento = {
                'urlcarpetaevento': carpetaDireccion,
                'idpropietario': widget.userID,
                'propiedadde': nombreUsuario,
                'descripcion': descripcion.text,
                'tipoevento': selectedTipoEvento,
                'fechainicio': Timestamp.fromDate(fechaInicio.toLocal()),
                'fechafinal': Timestamp.fromDate(fechaFinal.toLocal()),
                'permisoposterior': light1,
                'eventobloqueado': bloquear,
                'codigoevento': carpetaNombre,
              };


              //Acceso a la base de datos y agregación
              var baseRemota = FirebaseFirestore.instance;

              baseRemota.collection("eventos").add(agregarEvento).then((value) {
                setState(() {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Se subio el evento'),
                    ),
                  );
                  codigo.text = carpetaNombre;
                  _index = 6;

                  //Limpieza de controladores
                  descripcion.text = "";
                  light1 = true;
                  bloquear = false;
                  fechaInicio = DateTime.now();
                  fechaFinal = DateTime.now();
                  selectedTipoEvento = "Boda";
                  fechaProvisionalFinal = fechaFinal.day;
                });
              });
            }
            Future.delayed(const Duration(seconds: 8),(){
              setState(() {
                _index = 2;
              }); //setState
            });
          },
          child: const Text("CREAR"),
        ),
      ],
    );
  }

  Widget configuracionPerfil(){
    return Center(
      child: Column(
      children: [
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
            nombreImagen = archivoAEnviar.files.single.name!!;

            setState(() {
              _selectedImage = File(path);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Selecciono imagen'),
                ),
              );
            });
          },
          child: const Text("Cambiar Imagen de perfil"),),
        SizedBox(height: 10),
        // Muestra la imagen seleccionada
        _selectedImage != null
            ? Image.file(
          _selectedImage!,
          height: 100,
          width: 100,
          fit: BoxFit.cover,)
            : Container(),
        SizedBox(height: 10,),
        ElevatedButton(onPressed: (){
          //Subida de archivo imagen seleccionada
          DB.subirNuevaImagen(path, urlCarpetaPersonal, nombreImagen);
          DB.actualizarRutaImagen(urlCarpetaPersonal,"${urlCarpetaPersonal}/${nombreImagen}", widget.userID).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Se subio nueva imagen, la proxima vez que entre aparecera'),
              ),
            );
          }).catchError((error) {
            print('Error al actualizar el estado del evento: $error');
          });
        }, child: Text("Subir nueva imagen")),
      ],
      ),
    );
  }

  Widget agregarEvento(){
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(50),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              child: Text("AGREGAR EVENTO",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, color: Colors.red),
              ),
            ),
            SizedBox(height: 10,),
            Text("NUMERO DE INVITACION"),
            SizedBox(height: 5,),
            TextField(
              controller: codigoEscritoAEvento,
              decoration: InputDecoration(
                  labelText: "Escribe codigo",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code)),
            ),
            SizedBox(height: 10,),
            ElevatedButton(
              onPressed: () async{
                List<EventoBuscado> eventoEncontrado =  await DB.buscarEvento(codigoEscritoAEvento.text);
                if (eventoEncontrado.isNotEmpty) {

                  // Tomar el primer evento encontrado
                  EventoBuscado eventoEncontradoAutor = eventoEncontrado[0];

                  // Actualizar los controladores con los datos del evento encontrado
                  setState(() {
                    propiedadDe.text = eventoEncontradoAutor.propiedadDe;
                    descripcion.text = eventoEncontradoAutor.descripcion;
                    tipoEvento.text = eventoEncontradoAutor.tipoEvento;
                  });

                } else {
                  eventoBuscado = "No se encontró ningún evento con ese código";
                }
                setState(() {
                  eventoBuscado = "TIPO EVENTO: ${tipoEvento.text}\nPROPIEDAD DE: ${propiedadDe.text}\nDESCRIPCIÓN: ${descripcion.text}";
                });
              },
              child: const Text("Buscar evento"),
            ),
            SizedBox(height: 10,),
            Container(
              padding: const EdgeInsets.all(10),
              child: Text("${eventoBuscado}",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.red),
              ),
            ),
            SizedBox(height: 10,),
            ElevatedButton(
              onPressed: (){
                var nuevoeventoinvitado = {
                  'codigodelevento': codigoEscritoAEvento.text,
                };

                DB.agregarEventoCompartido(nuevoeventoinvitado, widget.userID).then((value){
                  setState(() {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Se agrego el evento a "Mis invitaciones" \n Vealo en: !!!Ver invitaciones a eventos¡¡¡'),
                      ),
                    );
                    descripcion.text = "";
                    propiedadDe.text = "";
                    tipoEvento.text = "";
                    eventoBuscado = "";
                    codigoEscritoAEvento.text = "";
                  });
                });
              },
              child: const Text("Agregar evento"),
            ),
            ElevatedButton(onPressed: (){
              setState(() {
                descripcion.text = "";
                propiedadDe.text = "";
                tipoEvento.text = "";
                eventoBuscado = "";
                codigoEscritoAEvento.text = "";
                _index = 1;
              });
            }, child: const Text("Regresar"))
          ],
        ),
      ),
    );
  }

  Widget invitacionesAEventos() {
    return FutureBuilder(
      future: DB.obtenerEventosInvitados(widget.userID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error al cargar eventos invitados');
        } else {
          List<DocumentSnapshot> eventosInvitados = snapshot.data as List<DocumentSnapshot>;

          return ListView.builder(
            itemCount: eventosInvitados.length,
            itemBuilder: (context, index) {
              var evento = eventosInvitados[index].data() as Map<String, dynamic>;

              return ListTile(
                title: Text("${evento['tipoevento']}"),
                subtitle: Text("${evento['descripcion']}"),
                onTap: (){
                  eventoEscogido.text = "${evento['codigoevento']}";
                  tipoEvento.text = "${evento['tipoevento']}";
                  descripcion.text = "${evento['descripcion']}";
                  eventoBloqueadoSiONo = evento['eventobloqueado'];
                  Timestamp fechaFinalTimestamp = evento['fechafinal'];
                  fechaYaPasoSiONo = fechaFinalTimestamp.toDate();
                  permisoEventoFecha = evento['permisoposterior'];
                  checaEventoBloqueadoYFechaYPermiso();
                  setState(() {
                    _index = 8;
                  });
                },
              );
            },
          );
        }
      },
    );
  }

  //Prueba de captura se usa si uno lo requiere no es necesario este widget
  Widget capturar() {
    final hoursInicio = fechaInicio.hour.toString().padLeft(2,'0');
    final minutesInicio = fechaInicio.minute.toString().padLeft(2,'0');
    return Center(
      child: Column(
        children: [
          ElevatedButton(onPressed: pickDateTimeFecha1,
              child: Text("${fechaInicio.year}/${fechaInicio.month}/${fechaInicio.day} - $hoursInicio:$minutesInicio")),
          SizedBox(height: 20,),
          ElevatedButton(
            onPressed: () {
              var datos = {
                'nombre': 'Valeria Felix',
                'usuario': 'ValeriaABC',
                'password': 'abc1234',
                'urlimagenperfil': 'imagenes/prueba/imagenes_perfil/sergio.jpg',
                'urlcarpeta': 'imagenes/prueba',
                'eventousuario': [
                  {
                    'ideventousuario': 'av1Lvf0p7ebGAEnpBvF5',
                    'urlcarpetaevento': 'imagenes/prueba/xdrk12ljpo',
                    'propiedadde': 'Valeria Felix',
                    'descripcion': 'Boda de juan',
                    'tipoevento': 'Boda',
                    'fechainicio':fechaInicio,
                    'fechafinal':fechaFinal,
                    'permisoposterior': false,
                    'eventobloqueado': false,
                  }
                ],
                'eventosinvitado':[
                  {
                    'urldecarpetaevento': 'D9wcU3GkPEiR4XslRaNT',
                    'urldecarpetaevento': 'MkCrTPCOqYS27rXnNLec',
                    'urldecarpetaevento': 'jX1KL6GeGheJ16ZMgYdx',
                  }
                ]
              };

              var base = FirebaseFirestore.instance;
              base.collection("usuarios").add(datos).then((value) {
                setState(() {
                });
              });
            },
            child: Text("INSERTAR"),
          ),
        ],
      )
    );
  }

  //Seleccionar fecha y tiempo de fecha inicio
  Future pickDateTimeFecha1() async {
    DateTime? date = await pickDate();
    if(date == null) return; //Presiono cancelar

    final fechaTiempo = DateTime(
      date.year,
      date.month,
      date.day,
      1,
      0,
    );

    setState(() {
      this.fechaInicio = fechaTiempo;
    });
  }

  //Seleccionar fecha y tiempo de fecha final
  Future pickDateTimeFecha2() async {
    DateTime? date = await pickDate();
    if(date == null) return; //Presiono cancelar

    /* TimeOfDay? time = await pickTime();
    if(time == null) return; //Presiono cancelar */

    final fechaTiempo = DateTime(
      date.year,
      date.month,
      date.day,
      24,
      59
    );

    setState(() {
      this.fechaFinal = fechaTiempo;
      fechaProvisionalFinal = fechaFinal.day - 1;
    });
  }

  //Manejo de calendario
  Future<DateTime?> pickDate() => showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100));

  //Genera el name de la carpeta de eventos
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

  //Mostrar showmodalbottomsheet
  void mostrarModal(BuildContext context, String urlImagen) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Eliminar'),
              onTap: () async {
                try {
                  // Obtener la referencia de la imagen a eliminar
                  final referencia = await DB.obtenerReferenciaImagenEliminar(urlImagen);

                  // Eliminar la imagen
                  await referencia.delete();

                  // Cerrar el modal
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Se elimino la imagen'),
                    ),
                  );
                } catch (error) {
                  print('Error al eliminar la imagen: $error');
                }
                setState(() {
                  _index = 7;
                });
              },
            ),
          ],
        );
      },
    );
  }

  //Checa si el evento no a sido bloqueado, si esta permitido introducir imagenes despues de fecha y si la fecha ya paso
  void checaEventoBloqueadoYFechaYPermiso(){
    DateTime fechaFinalSinHoras = DateTime(fechaYaPasoSiONo.year, fechaYaPasoSiONo.month, fechaYaPasoSiONo.day);
    if(eventoBloqueadoSiONo!= null && eventoBloqueadoSiONo == false){
      setState(() {
        isVisible = true;
      });
    }
    if(eventoBloqueadoSiONo!= null && eventoBloqueadoSiONo == true){
      setState(() {
        isVisible = false;
      });
    }
    if(permisoEventoFecha!= null && permisoEventoFecha == false){
      // Validación para asegurarse de que fechaInicio no sea despues de fechaFinal
      if (fechaFinalSinHoras != null && DateTime.now().isAfter(fechaFinalSinHoras)) {
        setState(() {
          isVisible = false;
        });
      }
    }
  }
}
