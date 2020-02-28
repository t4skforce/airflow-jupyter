c = get_config()
# https://github.com/jupyterhub/jupyterhub-deploy-teaching/tree/master/roles/jupyterhub/templates
{% for key, value in config['JupyterHub'].items() %}c.JupyterHub.{{key|safe}} = {{value}}
{% endfor %}{% for key, value in config['Spawner'].items() %}c.Spawner.{{key|safe}} = {{value}}
{% endfor %}{% for key, value in config['Authenticator'].items() %}c.Authenticator.{{key|safe}} = {{value}}
{% endfor %}{% for ctx, cfg in config.items() %}{% if not ctx in ['JupyterHub','Spawner','Authenticator'] %}{% for key, value in cfg.items() %}c.{{ctx|safe}}.{{key|safe}} = {{value}}
{% endfor %}{% endif %}{% endfor %}
