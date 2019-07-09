

## Configure
Copy example files, and customise install location

    cp example.deploy-vars.yml deploy-vars.yml
    cp example.hosts hosts


## Ensure remote host is configuree

In the configured directory for `remote_running_loc` create a file `env-list` based on `example.env-list`


## Run the deployment

    ansible-playbook -i hosts main.yml --ask-become-pass


