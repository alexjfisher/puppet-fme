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

The providers provided by this module use the FME Server v2 REST API to configure various elements of the FME Server.

## Setup

### What fme affects

* `/etc/fme_api_settings.yaml`

### Setup Requirements

Before using any of the types, the `/etc/fme_api_settings.yaml` file must first be created.  This can be done using the `fme::api_settings` class.

### Beginning with fme

```
class {'fme::api_settings':
  username => 'admin',
  password => 'password',
}

fme_user {'myuser':
  fullname  => 'My User',
  password  => 'topsecret',
}
```

## Usage

TODO

## Reference

TODO

## Limitations

TODO
