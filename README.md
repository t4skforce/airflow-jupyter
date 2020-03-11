# airflow-jupyter
Docker build for easy integration of Apache Airflow and JupyterLab

## Notes

* (The Top 5 Magic Commands for Jupyter Notebooks)[https://towardsdatascience.com/the-top-5-magic-commands-for-jupyter-notebooks-2bf0c5ae4bb8]

## Local Build
```
make DEBUG=true
```
## change user stuff
```
# change password
echo "username:newpass"|chpasswd

# change uid and gid
# Please note that all files which are located in the user’s home directory will have the file UID changed automatically
usermod -u 2005 foo
groupmod -g 3000 foo

# However, files outside user’s home directory need to be changed manually.
# To manually change files with old GID and UID respectively
find / -group 2000 -exec chgrp -h foo {} \;
find / -user 1005 -exec chown -h foo {} \;
```

## Oauth2 Provider
* (ORY Hydra)[https://github.com/ory/hydra]
* (OAuth + JupyterHub Authenticator = OAuthenticator)[https://github.com/jupyterhub/oauthenticator/blob/master/oauthenticator/generic.py]

## Docker Spawner
* (dockerspawner)[https://github.com/jupyterhub/dockerspawner]

## Airflow
* (Airflow Celery)[https://github.com/puckel/docker-airflow/blob/master/docker-compose-CeleryExecutor.yml]
