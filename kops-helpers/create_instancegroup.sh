#! /bin/bash

#=======================================================================================================
# Script to create a yaml spec for the node type instance group and pass the spec into 
# kops create --name <name> --state <state> -f <yaml_spec>
#=======================================================================================================

# parsing command line args
POSITIONAL_ARG=()
while [[ $# -gt 0 ]]
    do
        key="$1"
        case $key in
		--name)
		    CLUSTER_NAME="$2"
		    shift # moving past argument (--name)
		    shift # moving past value (NAME)
		    ;;
		--state)
		    KOPS_STATE_STORE="$2"
		    shift # moving past argument (--state)
		    shift # moving past value (KOPS_STATE_STORE)
		    ;;
		--subnet)
		    REGION_ZONE="$2"
		    shift # moving past argument (--subnet)
		    shift # moving past value (SUBNET value)
		    ;;
		--machine-type)
		    MACHINE_TYPE="$2"
		    shift # moving past argument (--machine-type)
		    shift # moving past value (MACHINE_TYPE value)
		    ;;
		--instance-type)
		    INSTANCE_TYPE="$2"
		    shift # moving past argument (--instance-type)
		    shift # moving past value (INSTANCE_TYPE value)
		    ;;
		--spot-price)
		    SPOT_PRICE="$2"
		    shift # moving past argument (--spot-price)
		    shift # moving past value (spot-price value)
		    ;;
		--root-volume-size)
		    ROOT_VOLUMEI_SIZE="$2"
		    shift # moving past argument (--root-volume-size)
		    shift # moving past value (root-volume-size value)
		    ;;
		--image)
		    IMAGE="$2"
		    shift # moving past argument (--image)
		    shift # moving past value (image value)
		    ;;
	        *)
		    POSITIONAL_ARG+=("$1") # capturing argument with no value (i.e. name of ig)
		    shift # moving past argument
		    ;;
	esac
    done
set -- "${POSITIONAL_ARG[@]}"

MACHINE_TYPE=${MACHINE_TYPE:=m3.2xlarge}
IMAGE=kope.io/${IMAGE:=k8s-1.7-debian-jessie-amd64-hvm-ebs-2017-07-28}
ROOT_VOLUME_SIZE=${ROOT_VOLUME_SIZE:=500}
SUBNET="${REGION_ZONE}"
IG_NAME="${POSITIONAL_ARG}"

if [[ "${CLUSTER_NAME}" == "" || "${KOPS_STATE_STORE}" == "" || "${IG_NAME}" == "" || ${SUBNET} == "" ]]; then
    echo "Expecting 4 positional arguments: cluster_name, kops_state_store, subnet and instancegroup_name to be created"
    echo "Usage: "
    echo "./create_instancegroup.sh --name <cluster_name> --state <kops_state_store> --subnet <subnet> --machine-type <machine_type> --image <image> --root-volume-size <root_volume_size> --instance-type <instance_type> --spot-price <spot_price> <instancegroup_name>"
    echo "NOTE: The script sets defaults to resources such as ROOT_VOLUME_SIZE, SPOT_INSTANCES, MACHINE_TYPE etc if not passed through command line args. Update the values as needed before running"
    exit 1
fi


# deafult is spot instances
INSTANCE_TYPE="${INSTANCE_TYPE:=spot}" # default is "spot" instance. other option is "on-demand"
SPOT_PRICE="${SPOT_PRICE:=0.40}"

cat >ig_spec.yaml <<EOF
apiVersion: kops/v1alpha2
kind: InstanceGroup
metadata:
  labels:
    kops.k8s.io/cluster: ${CLUSTER_NAME}
  name: ${IG_NAME}
spec:
  image: ${IMAGE}
  machineType: ${MACHINE_TYPE}
  maxPrice: "${SPOT_PRICE}"
  maxSize: 10
  minSize: 0
  rootVolumeSize: ${ROOT_VOLUME_SIZE}
  role: Node
  subnets:
  - ${SUBNET}
EOF

if [ "${INSTANCE_TYPE}" == "on-demand" ]; then
    cat >ig_spec.yaml <<EOF
apiVersion: kops/v1alpha2
kind: InstanceGroup
metadata:
  labels:
    kops.k8s.io/cluster: ${CLUSTER_NAME}
  name: ${IG_NAME}
spec:
  image: ${IMAGE}
  machineType: ${MACHINE_TYPE}
  maxSize: 10
  minSize: 0
  rootVolumeSize: ${ROOT_VOLUME_SIZE}
  role: Node
  subnets:
  - ${SUBNET}
EOF
fi

KOPS_CMD="kops create --name ${CLUSTER_NAME} --state ${KOPS_STATE_STORE} -f ig_spec.yaml ${IG_NAME}"

#run the kops create command
$KOPS_CMD

# delete the temporarily created instance group spec 
trap "{ rm -f ig_spec.yaml; }" EXIT
