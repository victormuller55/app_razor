class UsuarioModel {
  int? id;
  String? nome;
  String? email;
  String? tipo;
  String? foto;
  bool? ativo;
  String? dataCriacao;
  String? dataEdicao;

  UsuarioModel({
    this.id,
    this.nome,
    this.email,
    this.tipo,
    this.foto,
    this.ativo,
    this.dataCriacao,
    this.dataEdicao,
  });

  factory UsuarioModel.empty() {
    return UsuarioModel(
      id: 0,
      nome: '',
      email: '',
      tipo: '',
      foto: '',
      ativo: false,
      dataCriacao: '',
      dataEdicao: '',
    );
  }

  factory UsuarioModel.fromMap(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] as int?,
      nome: json['nome'] as String?,
      email: json['email'] as String?,
      tipo: json['tipo'] as String?,
      foto: json['foto'] as String?,
      ativo: json['ativo'] as bool?,
      dataCriacao: json['data_criacao'] as String?,
      dataEdicao: json['data_edicao'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'nome': nome,
      'email': email,
      'tipo': tipo,
      'foto': foto,
      'ativo': ativo,
      'data_criacao': dataCriacao,
      'data_edicao': dataEdicao,
    };
  }
}
