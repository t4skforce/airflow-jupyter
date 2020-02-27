#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from jinja2 import Environment, PackageLoader, select_autoescape
env = Environment(
    loader=PackageLoader('templates'),
    autoescape=select_autoescape(['html', 'xml'])
)
