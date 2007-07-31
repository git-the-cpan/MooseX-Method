#!/usr/bin/env perl

use inc::Module::Install;

use strict;
use warnings;

name           'MooseX-Method';
all_from       'lib/MooseX/Method.pm';

requires       'Moose' => '0.24';
requires       'Class::MOP' => '0.40';
requires       'Carp' => '0';
requires       'Scalar::Util' => '1.19';
requires       'Sub::Name' => '0.02';
requires       'Module::Find' => '0.05';

build_requires 'Test::More' => '0.70';
build_requires 'Test::Exception' => '0.25';
build_requires 'Test::Pod' => '1.26';

auto_install;
WriteAll;

