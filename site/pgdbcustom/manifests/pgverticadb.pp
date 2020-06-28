class pgdbcustom::pgverticadb {
  include postgresql::server

  postgresql::server::db { 'verticadb':
    user     => 'verticauser',
    password => postgresql::postgresql_password('verticauser', 'verticapwd'),
  }


  postgresql::server::role { 'verticarole':
    password_hash => postgresql::postgresql_password('verticarole', 'verticapwd'),
  }

  postgresql::server::database_grant { 'verticadb':
    privilege => 'ALL',
    db        => 'verticadb',
    role      => 'verticarole',
  }

}
