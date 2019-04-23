# Create instancegroups
Script to create AWS instance groups

## When to use?
To create a new instance group using kops command. kops command does not expose all the available parameters
to create a new instance group. This script allows you to set all the detailed options. 

## Prerequisites
- Amazon credentials

## Usage
```
./create_instancegroup.sh --name <cluster_name> --state <kops_state_store> --subnet <subnet> --machine-type <machine_type> --image <image> --root-volume-size <root_volume_size> --instance-type <instance_type> --spot-price <spot_price> <instancegroup_name>
```
