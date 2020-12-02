#!/bin/bash

incrementWorkers=0
instanceType=t2.micro
subnetId=subnet-3a0b891b
keyName=tarc_key
region=us-east-1
securityGroups="sg-06e184115cac1dcc6 sg-b6276e83"

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
    for counter in {1..$incrementWorkers}; do 
        aws ec2 run-instances --region $region --image-id ami-0885b1f6bd170450c --count 1 --instance-type $instanceType --key-name $keyName --security-group-ids $securityGroups --subnet-id $subnetId --tag-specifications "ResourceType=instance,Tags=[{Key=nodeType,Value=worker},{Key=nodeReference,Value=$counter}]" "ResourceType=volume,Tags=[{Key=nodeType,Value=worker},{Key=nodeReference,Value=$counter}]"  --user-data file://launch.sh
        instance=$(aws ec2 describe-instances --region $region --filters "Name=tag:nodeReference,Values=$counter" --query Reservations[*].Instances[*].[InstanceId] --output text)
        aws elbv2 register-targets --region $region --target-group-arn "arn:aws:elasticloadbalancing:us-east-1:101501527885:targetgroup/all-instances/4d9b97f60837a331" --targets Id=$instance
    done

else
    inverted=$incrementWorkers*-1
    instances=$(aws ec2 describe-instances --region $region --filters "Name=tag:nodeType,Values=worker" --max-items $inverted --query Reservations[*].Instances[*].[InstanceId] --output text)
    aws ec2 terminate-instances  --region $region --instance-ids $instances
fi
