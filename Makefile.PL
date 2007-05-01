#!/usr/bin/env perl

use inc::Module::Install;

use strict;
use warnings;

name           'MooseX-Method';
all_from       'lib/MooseX/Method.pm';

requires       'Moose' => '0.20';
requires       'Carp' => '0';
requires       'Scalar::Util' => '1.19';
requires       'Sub::Name' => '0.02';

build_requires 'Test::More' => '0.70';
build_requires 'Test::Exception' => '0.25';

auto_install;
WriteAll;

