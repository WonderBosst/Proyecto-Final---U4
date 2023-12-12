class Usuario {
  String usuarioID;
  String usuario;
  String password;
  String nombreReal;
  String urlCarpeta;
  String urlPerfil;
  List<dynamic> eventosUsuario;
  List<dynamic> eventosInvitado;

  Usuario({
    required this.usuarioID,
    required this.usuario,
    required this.password,
    required this.nombreReal,
    required this.urlCarpeta,
    required this.urlPerfil,
    required this.eventosUsuario,
    required this.eventosInvitado,
  });
}