#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import click
import os
import stat
import json
import re
from jinja2 import Environment, Undefined, FileSystemLoader, BaseLoader, select_autoescape
from jinja2.lexer import Token
from jinja2.ext import Extension
import logging
logging.basicConfig(format='%(asctime)s %(levelname)s %(message)s',level=logging.INFO)
log = logging.getLogger(__name__)

class PythonEscapeExtension(Extension):
    def __init__(self, environment):
        super(PythonEscapeExtension, self).__init__(environment)
        environment.filters['python']=self.filter
    def filter(self,val):
        if isinstance(val, Undefined):
            val._fail_with_undefined_error()
        if isinstance(val, str):
            return "'{}'".format(val)
        elif isinstance(val, set):
            if len(val) > 0:
                return "set({})".format(str(list(val)))
            else:
                return "set()"
        elif isinstance(val, dict):
            return '{{{}}}'.format(', '.join(["'{}': {}".format(k,self.filter(v)) for k,v in val.items()]))
        else:
            return str(val)
    """
    Insert a `| python` filter at the end of every variable substitution.
    This will ensure that all injected values are converted to YAML.
    """
    def filter_stream(self, stream):
        if not stream.name or not stream.name.endswith('.py'):
            for token in stream:
                yield token
        else:
            safe = False
            for token in stream:
                if token.type == 'name' and token.value == 'safe':
                    safe = True
                elif token.type == 'variable_end':
                    if not safe:
                        yield Token(token.lineno, 'pipe', '|')
                        yield Token(token.lineno, 'name', 'python')
                    safe = False
                yield token


def dict_merge(base_dct, merge_dct):
    base_dct.update({
        key: dict_merge(base_dct[key], merge_dct[key])
        if isinstance(base_dct.get(key), dict) and isinstance(merge_dct[key], dict)
        else merge_dct[key]
        for key in merge_dct.keys()
    })

def render_value(value, **kwargs):
    if "{{" in value and "}}" in value:
        value = Environment(loader=BaseLoader).from_string(value).render(**kwargs)
        return None if value == '' else value
    return value

def transform_config(config={}):
    if isinstance(config,dict):
        ret_dict = {}
        for key,value in config.items():
            if isinstance(value,dict):
                ret_dict[key] = value = transform_config(value)
            if key.endswith(':set') and isinstance(value, list):
                value = set(value) if value else set()
                ret_dict[':'.join(key.split(':')[:-1])]=set(value) if value else set()
            elif key.endswith(':str'):
                value = render_value(value,env=os.environ)
                ret_dict[':'.join(key.split(':')[:-1])]=str(value) if value else ""
            elif key.endswith(':int') and isinstance(value,str):
                value = render_value(value,env=os.environ)
                ret_dict[':'.join(key.split(':')[:-1])]=int(value) if not value is None else None
            elif isinstance(value,str):
                value = render_value(value,env=os.environ)
                ret_dict[key]=value
            else:
                ret_dict[key]=value
        config = ret_dict
    return config

def load_conf_files(templates,target_file,conf_file):
    filesloaded = set()
    config = {}
    # load from template folder 1st
    system_conf = os.path.abspath(os.path.join(templates,conf_file))
    if os.path.exists(system_conf):
        try:
            with open(system_conf) as config_file:
                dict_merge(config,json.load(config_file))
                log.info("loaded {}".format(system_conf))
                filesloaded.add(system_conf)
        except:
            log.exception("error loading {}".format(system_conf))
    else:
        log.warning('file does not exist! {}'.format(system_conf))

    # load conf file direct beside target file
    target_conf = os.path.abspath('{}.config.json'.format(target_file))
    if os.path.exists(target_conf):
        try:
            with open(target_conf) as config_file:
                dict_merge(config,json.load(config_file))
                log.info("loaded {}".format(target_conf))
                filesloaded.add(target_conf)
        except:
            log.exception("error loading {}".format(target_conf))

    # load override from $HOME/.config
    user_override = os.path.abspath(os.path.join(os.getenv('HOME','/'),'.config',conf_file))
    if not user_override in filesloaded:
        if os.path.exists(user_override):
            try:
                with open(user_override) as config_file:
                    dict_merge(config,json.load(config_file))
                    log.info("loaded {}".format(user_override))
            except:
                log.exception("error loading {}".format(user_override))

    # load from ENV_FILE
    env_var = os.path.splitext(os.path.split(conf_file)[-1])[0].upper()
    if os.getenv('{}_FILE'.format(env_var)):
        conf_file = os.path.abspath(os.getenv('{}_FILE'.format(env_var)))
        if os.path.exists(conf_file):
            try:
                with open(conf_file) as config_file:
                    dict_merge(config,json.load(config_file))
                    log.info("loaded {}={}".format('{}_FILE'.format(env_var),conf_file))
                    filesloaded.add(conf_file)
            except:
                log.exception("error loading {}".format(user_override))
        else:
            log.warning('file does not exist! {}'.format(conf_file))

    # LOAD ENV_JSON
    if os.getenv('{}_JSON'.format(env_var)):
        dict_merge(config,json.loads(os.getenv('{}_JSON'.format(env_var),'{}')))
        log.info("loaded {}".format('{}_JSON'.format(env_var)))

    return config

def render(env,template,ctx):
    rendered = template.render(**ctx)
    if re.search('\{\{.*?\}\}',rendered):
        rendered = env.from_string(rendered).render(**ctx)
    return rendered

@click.command()
@click.argument('templates', default="/root/templates" ,type=click.Path(exists=True))
@click.option('--stdout/--no-stdout', default=False)
@click.argument('output', default="/" ,type=click.Path(exists=True))
def main(templates,stdout,output):
    if stdout: log.setLevel(logging.ERROR)
    env = Environment(
        extensions=(PythonEscapeExtension,),
        loader=FileSystemLoader(templates),
        autoescape=select_autoescape(['html', 'xml'])
    )
    for template in env.list_templates():
        if not template.endswith('.config.json'):
            source_file = os.path.abspath(os.path.join(templates,template))
            target_file = os.path.abspath(os.path.join(output,template))
            path, filename = os.path.split(template)
            conf_file = os.path.join(path,'{}.config.json'.format(filename))
            config = load_conf_files(templates,target_file,conf_file)
            template = env.get_template(template)
            log.info("rendering {} -> {}".format(template,target_file))
            target_directory = os.path.dirname(target_file)
            if stdout:
                print("#"*10,target_file,"#"*10)
                print(render(env=env,template=template,ctx={"config":transform_config(config),"env":os.environ}))
                continue
            else:
                if not os.path.exists(target_directory):
                    os.makedirs(target_directory)
                with open(target_file,'w') as out_file:
                    out_file.write(render(env=env,template=template,ctx={"config":transform_config(config),"env":os.environ}))
                perms = stat.S_IMODE(os.lstat(source_file).st_mode)
                os.chmod(target_file,perms)
                log.info("rendered {} ({})".format(target_file,perms))

if __name__ == '__main__':
    main()
