# Cloud Tasks

Tasks related to cloud.

## Project

Repository contains 3 directories
* aws
* gcp
* terraform

### Description

Each directory contains script(s) that create cloud resources.
* Create VPC, Subnet, Container Registry, Instance, Security Groups...
* Push spring-petclinic container image to private Container Registry
* Run container (using Docker) on the instance, get access to app.

### Executing

* Get the spring-petclinic image
```
docker pull magdalena01/spring-petclinic-multistage:spring-petclinic
```
* Add permissions to scripts
```
chmod 500 script_name.sh
```
* Execute script
```
./script_name.sh
```

## Acknowledgments

* [Spring-Petclinic](https://github.com/spring-projects/spring-petclinic)
