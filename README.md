# Mediawiki Deployment

Provides an extremely simple Mediawiki deployment intended to run on a single EC2 instance.

The AWS infrastructure is created with Terraform and Ansible is used for provisioning. The setup uses a few containers which are coordinated using Docker Compose. A Systemd service controls the use of Compose. It is not a completely automated setup, but the whole process is documented.

SSL is not configured yet.

## Prerequisites

Install Terraform and Ansible on your platform. Due to the use of Ansible, if you use Windows, you'll need to run the process from WSL. The use of a virtualenv is recommended for Ansible. Install [just](https://github.com/casey/just) on your platform.

Configure your AWS credentials:
```
export AWS_ACCESS_KEY_ID=<your access key id>
export AWS_SECRET_ACCESS_KEY=<your secret access key>
export AWS_DEFAULT_REGION=<your region>
```

Provide the MariaDB passwords by creating a `.env` file at the root of this directory, and populate it as follows:
```
WIKI_DOMAIN_NAME=<your domain name>
MARIADB_PASSWORD=<password>
MARIADB_ROOT_PASSWORD=<password>
```

Ansible will copy the file to the EC2 instance and it will be used by `docker-compose`.

Both of these passwords will be referenced during the Mediawiki installation.

Create an SSH keypair for the instance:
```
ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/mediawiki
```

## Preinstallation

Kick the process off:
```
just preinstall
```

This will run Terraform, then Ansible, which should result in Mediawiki deployed on the EC2 instance.

Now go to your DNS provider and create an A record which points your domain to the elastic IP address assigned to the EC2 instance.

To confirm that the A record is available, you can use `dig A <your domain> @1.1.1.1 +noall +answer`.

## Mediawiki Installation

### Create Database User

Before proceeding with the install, an additional database user needs to be created; it's not completely clear why, but the install won't complete without doing this.

SSH to the EC2 instance:
```
ssh -i ~/.ssh/mediawiki ec2-user@<elastic ip>
```

Now run these commands:
```
sudo docker exec -it data-mariadb-1 mysql -u root -p
# provide your root password
# Now from the mysql console, run these commands:
CREATE USER wiki@mariadb IDENTIFIED BY '<MARIADB_PASSWORD>';
GRANT ALL PRIVILEGES ON wiki.* TO wiki@mariadb;
exit # Back to the Bash shell
exit
```

This should allow the install process to complete.

### Install Process

The Mediawiki instance should now be accessible using http://<your domain>. It now needs to go through an installation phase.

Go to the Mediawiki instance in the browser and go through the install, which has a wizard-type interface with several pages.

On the 'Connect to Database' page, use these for the values:
```
Database host: mariadb
Database name: wiki
Database table prefix: leave blank
Database username: root
Database password: <MARIADB_ROOT_PASSWORD>
```

On the next page, `Database settings`, untick 'Use the same account as for installation', then supply these values:
```
Database username: wiki
Database password: <MARIADB_PASSWORD>
```

On the next page, 'Name', call the wiki whatever you want and create an admin account using whatever credentials you wish.

The next page is 'Options'. For 'User rights profile', select 'Authorized editors only'. In the 'Extensions' section, tick 'VisualEditor' and 'WikiEditor'.

You can now complete the installation.

## Post Installation

After the install completes, it will automatically download the newly generated `LocalSettings.php` from your browser. We need to redeploy the setup using this file.

Copy the file to the root of this repository directory.

Now make a couple of edits to it:
```
$wgServer = "http://<your domain>";
# Remove the $wgLogos declaration
$wgLogo = "$wgResourceBasePath/images/logo.png";
```

Note: `$wgServer` may already be correctly set.

Now run the post-install playbook:
```
just postinstall
```

Access the wiki using the elastic IP. You should be able to log in as the admin user you created in the install process, and the custom logo should be visible.

## Backup and Restore

The initial setup is deployed with a backup script that copies the necessary files and directories up to S3. It runs as a cron job on a nightly basis. There is a very brief period of downtime during the backup process; maybe something like 5 seconds.

We can restore a backup to a completely fresh EC2 instance using a slightly different process. All the initial steps in the setup section are necessary to install the tools. Then, after that, you can run:
```
just restore
```

This will re-create the infrastructure and run an Ansible playbook which will do almost everything the same way as the preinstall playbook, with a few minor differences, like not starting the service.

After running this script and getting a new Elastic IP, update the DNS A record to point to said IP.

Next, SSH into the new instance and run the restore script at `/mnt/data/restore.sh`. As an argument to the script, you need to supply the name of one of the zip files in the S3 bucket. This should restore all the data, and after this, you can run `systemctl start mediawiki`. At that point, the Mediawiki instance should be accessible again with the data from the backup point.
