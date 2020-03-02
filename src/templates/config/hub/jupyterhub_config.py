c = get_config()
# https://github.com/jupyterhub/jupyterhub-deploy-teaching/tree/master/roles/jupyterhub/templates
{% for ctx, cfg in config.items() %}{% for key, value in cfg.items() %}c.{{ctx|safe}}.{{key|safe}} = {{value}}
{% endfor %}{% endfor %}
