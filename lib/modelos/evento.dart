class Evento {
  String idPropietario;
  String urlCarpetaEvento;
  String propiedadDe;
  String descripcion;
  String tipoEvento;
  DateTime fechaInicio;
  DateTime fechaFinal;
  bool permisoPosterior;
  bool eventoBloqueado;

  Evento({
    required this.idPropietario,
    required this.urlCarpetaEvento,
    required this.propiedadDe,
    required this.descripcion,
    required this.tipoEvento,
    required this.fechaInicio,
    required this.fechaFinal,
    required this.permisoPosterior,
    required this.eventoBloqueado
  });
}