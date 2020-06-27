class profile::pgdb {
  include postgresql::server

  postgresql::server::db { 'mydatabasename':
    user     => 'mydatabaseuser',
    password => postgresql::postgresql_password('mydatabaseuser', 'mypassword'),
  }
}
