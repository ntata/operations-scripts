#!/bin/bash

API_VERSION="batch/v1"
EFS_VOLUME=changeMe
EFS_VOLUME_IDENTIFIER=changeMe
JOB_NAME=backup-efs-${EFS_VOLUME_IDENTIFIER}
REGISTRY=changeMe
BACKUP_S3_BUCKET_URI=changeMe

cat << EOF > "${JOB_NAME}-job.yaml"
---
apiVersion: ${API_VERSION}
kind: Job
metadata:
  name: ${JOB_NAME}
spec:
  backoffLimit: 4
  template:
    metadata:
      annotations:
        iam.amazonaws.com/role: changeMe
    spec:
      restartPolicy: OnFailure
      containers:
      - name: backup-efs
        image: ${REGISTRY}:changeMe
        imagePullPolicy: Always
        command: ["sh", "/opt/scripts/backup-efs.sh" ]
        env:
        - name: BACKUP_S3_BUCKET_URI
          value: ${BACKUP_S3_BUCKET_URI}
        - name: EFS_VOLUME
          value: ${EFS_VOLUME}
        volumeMounts:
        - mountPath: /mnt/efs
          name: ${EFS_VOLUME_IDENTIFIER}
        - mountPath: /opt/scripts
          name: efs-backup-script
      volumes:
      - name: ${EFS_VOLUME_IDENTIFIER}
        nfs:
          path: /
          server: ${EFS_VOLUME}
      - configMap:
          name: ${JOB_NAME}
        name: efs-backup-script
EOF

cat << EOF > "${JOB_NAME}-configmap.yaml"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${JOB_NAME}
data:
  backup-efs.sh: |-
    #!/bin/bash
    # script to tar zip mounted efs volume and push to s3 bucket
    TIMESTAMP="\`date +"%Y-%m-%d_%H-%M-%S"\`"

    # cd into mount dir
    cd /mnt/efs

    # zip the efs volume
    ZIP_COMMAND="tar -zcvf /tmp/${EFS_VOLUME_IDENTIFIER}-\${TIMESTAMP}.tar.gz ."
    eval "\${ZIP_COMMAND}"
    
    # push backup to s3
    PUSH_TO_S3_COMMAND="aws s3 cp /tmp/${EFS_VOLUME_IDENTIFIER}-\${TIMESTAMP}.tar.gz ${BACKUP_S3_BUCKET_URI}"
    eval "\${PUSH_TO_S3_COMMAND}"
EOF
