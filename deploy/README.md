

## Configure
Copy example files, and customise install location

    cp example.deploy-vars.yml deploy-vars.yml
    cp example.hosts hosts



## Run the deployment

    ansible-playbook -i hosts main.yml --ask-become-pass


