#
class fme::api_settings (
  $username,
  $password,
  $host     = undef,
  $port     = undef,
  $protocol = undef
) {

  validate_string($username)
  validate_string($password)

  if ($host     != undef) { validate_string($host) }
  if ($port     != undef) { validate_integer($port) }
  if ($protocol != undef) { validate_re($protocol, '^https?$' ) }

  $filepath = $::kernel ? {
    'windows' => 'C:/fme_api_settings.yaml',
    'Linux'   => '/etc/fme_api_settings.yaml',
    default   => 'UNSUPPORTED'
  }

  if $filepath == 'UNSUPPORTED' { fail("kernel: ${::kernel} is unsupported") }

  file {$filepath:
    ensure  => file,
    content => template('fme/fme_api_settings.yaml.erb'),
    mode    => '0600', #file contains credentials
  }
}
