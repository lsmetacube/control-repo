class pgdbcustom::pgmscluster (
  $user                 = 'rep',
  $master_IP_address,
  $slave_IP_address,
  $port                 = 5432,
  $password,
  $trigger_file         = undef,
  $extra_acls           = [],
  $pg_hba_custom        = {},
  $pg_hba_conf_defaults = true,
)
{
  validate_bool(is_ip_address($master_IP_address))
  validate_bool(is_ip_address($slave_IP_address))
  validate_bool($pg_hba_conf_defaults)
  validate_hash($pg_hba_custom)

  # Increase sysctl maximum File Descriptors
  sysctl { 'fs.file-max': value => '65536' }
  # Increase maximum File Descriptors in /etc/security/limits.conf
  limits::fragment {
    "*/soft/nofile":
      value => "65535";
    "*/hard/nofile":
      value => "65535";
  }

  if $::ipaddress == $slave_IP_address {
    $default_slave_acl = ["host replication $user $master_IP_address/32 md5"]
    class { 'postgresql::server':
      ipv4acls             => concat($default_slave_acl, $extra_acls),
      listen_addresses     => "*",
      manage_recovery_conf => true,
      pg_hba_conf_defaults => $pg_hba_conf_defaults,
    }
    postgresql::server::recovery { 'postgresrecovery':
      standby_mode => 'on',
      primary_conninfo => "host=$master_IP_address port=$port user=$user password=$password",
      trigger_file => "$trigger_file",
    }
    postgresql::server::config_entry { 'wal_keep_segments':
      value => '32',
    }
    postgresql::server::config_entry { 'wal_level':
      value => 'hot_standby',
    }
    postgresql::server::config_entry { 'archive_mode':
      value => 'on',
    }
    postgresql::server::config_entry { 'archive_command':
      value => 'cd .',
    }
    postgresql::server::config_entry { 'max_wal_senders':
      value => '2',
    }
    postgresql::server::config_entry { 'hot_standby':
      value => 'on',
    }
    postgresql::server::config_entry { 'hot_standby_feedback':
      value => 'on',
    }
    postgresql::server::config_entry { 'max_connections':
      value => '1000',
    }
  }
  else {
    $default_master_acl = ["host replication $user $slave_IP_address/32 md5"]
    class { 'postgresql::server':
      ipv4acls         => concat($default_master_acl, $extra_acls),
      listen_addresses => "*",
      pg_hba_conf_defaults => $pg_hba_conf_defaults,
    }
    file { '/var/lib/postgresql/9.3/main/recovery.conf':
      ensure => 'absent',
    }
    postgresql::server::config_entry { 'wal_keep_segments':
      value => '32',
    }
    postgresql::server::role { "$user":
      password_hash      => postgresql_password("$user", "$password"),
        replication      => true,
        connection_limit => 1,
	require		 => Class['Postgresql::Server'],
    }
    postgresql::server::config_entry { 'wal_level':
      value => 'hot_standby',
    }
    postgresql::server::config_entry { 'archive_mode':
      value => 'on',
    }
    postgresql::server::config_entry { 'archive_command':
      value => 'cd .',
    }
    postgresql::server::config_entry { 'max_wal_senders':
      value => '1',
    }
    postgresql::server::config_entry { 'hot_standby':
      value => 'on',
    }
    postgresql::server::config_entry { 'max_connections':
      value => '1000',
    }
  }
  if $pg_hba_conf_defaults == 'false' {
    notify{'pg hba conf':}
    create_resources ('postgresql::server::pg_hba_rule',$pg_hba_custom)
  }
}
