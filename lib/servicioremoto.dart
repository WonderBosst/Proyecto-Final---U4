import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:proyectofinal/modelos/evento.dart';
import 'package:proyectofinal/modelos/eventobuscado.dart';

var baseRemota = FirebaseFirestore.instance;
var carpetaRemota = FirebaseStorage.instance;

class DB {

  // Si se usan estos metodos
  static Future insertar(Map<String, dynamic> usuario) async{
    return await baseRemota.collection("usuarios").add(usuario);
  }

  static Future subirArchivo(String path, String nombreCarpeta, String nombreImagen) async {
    var file = File(path);

    return await carpetaRemota.ref("imagenes/$nombreCarpeta/$nombreImagen").putFile(file);
  }

  static Future subirArchivoAEvento(String path, String nombreCarpeta, String nombreImagen) async {
    var file = File(path);

    return await carpetaRemota.ref("$nombreCarpeta/$nombreImagen").putFile(file);
  }

  static Future<String> obtenerURLimagen(String urlImagenPerfil) async{
    return await carpetaRemota.ref("$urlImagenPerfil").getDownloadURL();
  }

  static Future<List<Evento>> mostrarTodosEventosMios(String userID) async {
    List<Evento> temporal = [];
    var query = await baseRemota.collection("eventos").where("idpropietario", isEqualTo: userID).get();

    query.docs.forEach((element) {
      Map<String, dynamic> dataTemp = element.data();

      Timestamp temp1 = dataTemp['fechainicio'];
      Timestamp temp2 = dataTemp['fechafinal'];
      DateTime fechaInicioEvent = temp1.toDate();
      DateTime fechaFinalEvent = temp2.toDate();
      var eventosLlamados = Evento(
        idPropietario: dataTemp["idpropietario"],
        urlCarpetaEvento: dataTemp["urlcarpetaevento"],
        propiedadDe: dataTemp["propiedadde"],
        descripcion: dataTemp["descripcion"],
        tipoEvento: dataTemp["tipoevento"],
        fechaInicio: fechaInicioEvent,
        fechaFinal: fechaFinalEvent,
        permisoPosterior: dataTemp["permisoposterior"],
        eventoBloqueado: dataTemp["eventobloqueado"],
      );
      temporal.add(eventosLlamados);
    });
    return temporal;
  }

  static Future<List<String>> obtenerURLImagenes(String urlCarpetaEvento) async {
    try {
      List<String> urls = [];
      ListResult result = await carpetaRemota.ref(urlCarpetaEvento).listAll();

      for (var item in result.items) {
        String url = await item.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      print("Error al obtener URLs de imágenes: $e");
      return [];
    }
  }

  static Future<String> actualizarEstadoEvento(String urlCarpetaEvento, bool nuevoEstado) async {
    try {
      // Obtener referencia al documento del evento
      QuerySnapshot<Map<String, dynamic>> eventoQuery = await baseRemota
          .collection('eventos')
          .where("urlcarpetaevento", isEqualTo: urlCarpetaEvento)
          .get();

      // Verificar si se encontraron documentos
      if (eventoQuery.docs.isNotEmpty) {
        // Obtener la referencia al primer documento encontrado
        DocumentReference eventoRef = eventoQuery.docs.first.reference;

        // Actualizar el atributo eventobloqueado
        await eventoRef.update({'eventobloqueado': nuevoEstado});

        print('Se actualizó el estado del evento exitosamente');
        return 'Éxito'; // Devolver un mensaje de éxito o cualquier otro valor significativo
      } else {
        print('No se encontró ningún evento con el URL de carpeta proporcionado.');
        return 'No se encontró ningún evento con el URL de carpeta proporcionado.';
      }
    } catch (error) {
      print('Error al actualizar el estado del evento: $error');
      return 'Error al actualizar el estado del evento: $error';
    }
  }

  static Future<Reference> obtenerReferenciaImagenEliminar(String urlImagenEliminar) async {
    // Obtener la referencia de la imagen
    return carpetaRemota.refFromURL(urlImagenEliminar);
  }

  static Future agregarEventoCompartido(Map<String,dynamic> hc, String id) async{
    // var documento = await baseRemota.collection("paciente").doc(id).get();
    await baseRemota.collection("usuarios").doc(id).get().then((value){
      if(value.data()!.length==0) return false;

      Map<String, dynamic> mapa = value.data()!;
      List<dynamic> invitacionesAEventos = mapa['eventosinvitado'];
      invitacionesAEventos.add(hc);
      //historiaCLinica.removeAt(3);
      //mapa["historiaclinica"] = historiaCLinica;

      baseRemota.collection("usuarios").doc(id).update(mapa);
    });
  }

  static Future<List<EventoBuscado>> buscarEvento(String codigoEvento) async {
    List<EventoBuscado> eventoEncontrado = [];

      var query = await baseRemota.collection("eventos").where("urlcarpetaevento", isEqualTo: "eventos/${codigoEvento}").get();

      query.docs.forEach((element) {
        Map<String, dynamic> dataTemp = element.data();
        var eventoLlamado = EventoBuscado(
          propiedadDe: dataTemp["propiedadde"],
          descripcion: dataTemp["descripcion"],
          tipoEvento: dataTemp["tipoevento"],
        );
        eventoEncontrado.add(eventoLlamado);
      });
    return eventoEncontrado;
  }

  static Future<List<DocumentSnapshot>> obtenerEventosInvitados(String userID) async {
    try {
      var document = await FirebaseFirestore.instance.collection("usuarios").doc(userID).get();

      if (document.exists) {
        List<dynamic> eventosInvitados = document['eventosinvitado'];

        if (eventosInvitados.isNotEmpty) {
          // Realizar una consulta para obtener los eventos que coinciden con los códigos
          var query = await FirebaseFirestore.instance.collection("eventos").where(
            'codigoevento',
            whereIn: eventosInvitados.map((evento) => evento['codigodelevento']).toList(),
          ).get();

          return query.docs;
        }
      }
    } catch (e) {
      print("Error al obtener eventos invitados: $e");
    }
    return [];
  }

  static Future subirArchivoNuevaImagen(String path, String urlcarpeta, String nombreImagen) async {
    var file = File(path);

    return await carpetaRemota.ref("$urlcarpeta/$nombreImagen").putFile(file);
  }

  static Future<String> actualizarRutaImagen(String rutaDeCarpeta, String NuevaRutaImagenPerfil, String UserID) async {
    try {
      // Obtener referencia al documento del evento
      QuerySnapshot<Map<String, dynamic>> eventoQuery = await baseRemota
          .collection('usuarios')
          .where("urlcarpeta", isEqualTo: rutaDeCarpeta)
          .get();

      // Verificar si se encontraron documentos
      if (eventoQuery.docs.isNotEmpty) {
        // Obtener la referencia al primer documento encontrado
        DocumentReference eventoRef = eventoQuery.docs.first.reference;

        // Actualizar el atributo eventobloqueado
        await eventoRef.update({'urlimagenperfil': NuevaRutaImagenPerfil});

        print('Se actualizó el estado del evento exitosamente');
        return 'Éxito'; // Devolver un mensaje de éxito o cualquier otro valor significativo
      } else {
        print('No se encontró ningún evento con el URL de carpeta proporcionado.');
        return 'No se encontró ningún evento con el URL de carpeta proporcionado.';
      }
    } catch (error) {
      print('Error al actualizar el estado del evento: $error');
      return 'Error al actualizar el estado del evento: $error';
    }
  }

  static Future subirNuevaImagen(String path, String nombreCarpeta, String nombreImagen) async {
    var file = File(path);

    return await carpetaRemota.ref("$nombreCarpeta/$nombreImagen").putFile(file);
  }

  //No se usan estos metodos, pero sirven de ejemplo
  static Future<ListResult> mostrarTodos(String urlCarpetaEvento) async{
    return await carpetaRemota.ref("$urlCarpetaEvento").listAll();
  }

  static Future agregarIdEvento(Map<String,dynamic> hc, String id) async{
    // var documento = await baseRemota.collection("paciente").doc(id).get();
    await baseRemota.collection("usuarios").doc(id).get().then((value){
      if(value.data()!.length==0) return false;

      Map<String, dynamic> mapa = value.data()!;
      List<dynamic> eventosUsuario = mapa['eventosusuario'];
      eventosUsuario.add(hc);
      //historiaCLinica.removeAt(3);
      //mapa["historiaclinica"] = historiaCLinica;

      baseRemota.collection("pacientes").doc(id).update(mapa);
    });
  }

  static Future<List> buscarUsuario() async {
    List temporal = [];
    var query = await baseRemota.collection("usuarios").get();

    query.docs.forEach((Element) {
      Map<String, dynamic> dataTemp = Element.data();
      dataTemp.addAll({'id': Element.id});
      temporal.add(dataTemp);
    });
    return temporal;
  }

}