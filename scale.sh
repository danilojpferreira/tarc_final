#!/bin/bash

incrementWorkers=0
instanceType=t2.micro
subnetId=subnet-9a8704c5
keyName=TARC_KEY
region=us-east-1
securityGroups=sg-46d3de73

for ((i=1;i<=$#;i++)); 
do
    elif [ ${!i} = "--incrementWorkers" ];
    then ((i++)) 
        incrementWorkers=${!i};  

    elif [ ${!i} = "--instanceType" ];
    then ((i++)) 
        instanceType=${!i};  

    elif [ ${!i} = "--subnetId" ];
    then ((i++)) 
        subnetId=${!i};  

    elif [ ${!i} = "--keyName" ];
    then ((i++)) 
        keyName=${!i};  

    elif [ ${!i} = "--securityGroups" ];
    then ((i++)) 
        securityGroups=${!i};  

    elif [ ${!i} = "--region" ];
    then ((i++)) 
        region=${!i};  
    fi
done;

if [ $incrementWorkers > 0] 
then
    curl "https://raw.githubusercontent.com/danilojpferreira/tarc_final/main/launch.sh" -o "launch.sh"
    for counter in `seq 1 $incrementWorkers`; do
        random=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | sed -e 's/^0*//' | head --bytes 3)
        aws ec2 run-instances --region $region --image-id ami-0885b1f6bd170450c --count 1 --instance-type $instanceType --key-name $keyName --security-group-ids $securityGroups --subnet-id $subnetId --tag-specifications "ResourceType=instance,Tags=[{Key=hash,Value=$random},{Key=TARC,Value=true},{Key=nodeType,Value=worker}]" --user-data file://launch.sh
        instance=$(aws ec2 describe-instances --region $region --filters "Name=tag:hash,Values=$random" --query Reservations[*].Instances[*].[InstanceId] --output text)
        aws elbv2 register-targets --region $region --target-group-arn arn:aws:elasticloadbalancing:us-east-1:807587852252:targetgroup/TARC-TARGET-GROUP/a499ba73d38018c2 --targets Id=$instance
    done

else
    inverted=$incrementWorkers*-1
    instances=$(aws ec2 describe-instances --region $region --filters "Name=tag:nodeType,Values=worker" --max-items $inverted --query Reservations[*].Instances[*].[InstanceId] --output text)
    aws ec2 terminate-instances  --region $region --instance-ids $instances
fi
