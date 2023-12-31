#!/usr/bin/env just --justfile

set dotenv-load := true
wiki_domain_name := env_var('WIKI_DOMAIN_NAME')

preinstall:
  #!/usr/bin/env bash
  set -e
  cd terraform
  terraform init
  terraform apply -auto-approve
  ip_address=$(terraform output -raw elastic_ip)
  cd ..

  cat <<- EOF > inventory
  [mediawiki]
  $ip_address ansible_ssh_private_key_file=~/.ssh/mediawiki ansible_ssh_user=ec2-user ansible_ssh_common_args='-o StrictHostKeyChecking=no'
  EOF

  ansible-playbook --inventory inventory preinstall.yml --extra-vars wiki_domain_name={{wiki_domain_name}}

postinstall:
  #!/usr/bin/env bash
  set -e

  if [[ ! -f "LocalSettings.php" ]]; then
    echo "The LocalSettings.php file must be placed in this directory"
    exit 1
  fi
  ansible-playbook --inventory inventory postinstall.yml

clean:
  #!/usr/bin/env bash
  set -e
  cd terraform
  terraform destroy -auto-approve

restore:
  #!/usr/bin/env bash
  set -e
  just preinstall
  ansible-playbook --inventory inventory restore.yml --extra-vars wiki_domain_name={{wiki_domain_name}}
