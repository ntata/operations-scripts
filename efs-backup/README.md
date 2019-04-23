# Backup EFS
Script to backup efs volume and migrate to a new VPC

## How it works?
Using the script we generate two k8s resources - job and a configmap.
kubernetes job rolls out a pod that mounts the efs to be backed up and 
runs until completion of the set task. I'm loading the scripts to run
using a configmap. The scripts tars and zips the mounted efs volume
and ships it to the set s3 bucket.
 
## Prerequisites
- kubernetes config to run the job in the cluster of choice.
- set the volume name and volume-identifier in the script before executing.

## Usage
- Create k8s resources by running - 
- ```kubectl apply -f <configmap>; kubectl apply -f <job>```
