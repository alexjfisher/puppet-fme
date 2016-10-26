[![License](https://img.shields.io/github/license/ordnancesurvey/puppet-fme.svg)](https://github.com/ordnancesurvey/puppet-fme/blob/master/LICENSE)
[![Puppet Forge Version](https://img.shields.io/puppetforge/v/ordnancesurvey/fme.svg)](https://forge.puppetlabs.com/ordnancesurvey/fme)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/ordnancesurvey/fme.svg)](https://forge.puppetlabs.com/ordnancesurvey/fme)
[![Build Status](https://img.shields.io/travis/OrdnanceSurvey/puppet-fme.svg)](https://travis-ci.org/OrdnanceSurvey/puppet-fme)
[![Coverage Status](https://img.shields.io/coveralls/OrdnanceSurvey/puppet-fme.svg)](https://coveralls.io/github/OrdnanceSurvey/puppet-fme)

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with fme](#setup)
    * [What fme affects](#what-fme-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with fme](#beginning-with-fme)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module provides types and providers for FME resources.  The FME Server REST API is used.

## Module Description

The types provided by this module use the FME Server v2 REST API to configure various elements of the FME Server.

## Setup

### What fme affects

* `/etc/fme_api_settings.yaml` or `C:\fme_api_settings.yaml`

### Setup Requirements

Before using any of the types, the `/etc/fme_api_settings.yaml` file must first be created.  This can be done using the `fme::api_settings` class.
The providers all use rest-client.  Rest-client can usually be installed with puppet.  eg
```
package { 'rest-client':
  ensure   => 'installed',
  provider => 'gem',
}
```

### Beginning with fme

Declare the fme::api_settings class.  After that, you can use any of the types offered by the module.

## Usage

All the fme resource types use the API to query and update the server's configuration.
Before using any of these types, declare the fme::api_settings class and this will generate the API settings file containing the API credentials to use.

All the types autorequire the settings file.

Here is a simple example with comments.

```
# Configure access to REST API
class { 'fme::api_settings':
  username => 'admin',
  password => 'password',
  protocol => 'https',
  port     => 443,
}

# Create a user
fme_user { 'myuser':
  fullname => 'My User',
  password => 'topsecret',
}

# Create a repository
fme_repository { 'my_repo':
  ensure => present,
}

# Upload a workspace to the repository
fme_repository_item { 'my_repo/item.fmw':
  ensure => present,
  source => '/path/to/item.fmw',
}

# Upload an FME resource
fme_resource { 'FME_SHAREDRESOURCE_DATA:/foo/my_resource.data':
  ensure   => file,
  checksum => true,
  source   => '/path/to/my_resource.data',
}

# Modify an FME service for HTTPS
fme_service { 'fmedatadownload':
  url => "https://${::fqdn}/fmedatadownload",
}

```

## Reference

### Classes

#### Public Classes
*[`fme::api_settings`](#fmeapi_settings): Creates an fme_api_settings.yaml file

### `fme::api_settings`

#### Parameters

##### `username`
Sets the API username. **mandatory**

#### `password`
Sets the API password. **mandatory**

#### `host`
Sets the FME Server to connect to. Default: 'localhost'.

#### `port`
Sets the TCP port of the FME Server API. Default: 80.

#### `protocol`
Sets the protocol to use. Valid options: 'http' or 'https'. Default: 'http'.
## Limitations

This is an early release with only a few types implemented.
