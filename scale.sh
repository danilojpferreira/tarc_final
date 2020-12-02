#!/bin/bash

incrementWorkers='0'
instanceType='t2.micro'
subnetId='subnet-3a0b891b'
keyName='tarc_key'
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
    fi


done;

if [ $incrementWorkers > 0] 
then
    curl "https://raw.githubusercontent.com/danilojpferreira/tarc_final/main/launch.sh" -o "launch.sh"
    for counter in {1..$incrementWorkers}; do 
        aws ec2 run-instances --image-id ami-0885b1f6bd170450c --count 1 --instance-type $instanceType --key-name $keyName --security-group-ids $securityGroups --subnet-id $subnetId --tag-specifications "ResourceType=instance,Tags=[{Key=nodeType,Value=worker}, {Key=nodeReference,Value=$counter}]" "ResourceType=volume,Tags=[{Key=nodeType,Value=worker}, {Key=nodeReference,Value=$counter}]"  --user-data file://launch.sh.txt
    done

else
    inverted=$incrementWorkers*-1
    instances=aws ec2 describe-instances --filters "Name=tag:nodeType,Value=[{Key=nodeType,Value=worker}]" --max-items $inverted --query Reservations[*].Instances[*].[InstanceId] --output text
    aws ec2 terminate-instances --instance-ids $instances
fi
