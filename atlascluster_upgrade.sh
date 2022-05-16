#!/bin/bash
echo 'This script recreate AtlasCluster CRs using the patch files after MongoDB Atlas Operator for RHODA has been upgraded to the new rebased release.

You must have logged into the OpenShift cluster as a cluster administrator in order to proceed.'
read -p "Would you like to continue (y/n)?" answer
case ${answer:0:1} in
    y|Y )
        echo Yes
    ;;
    * )
        exit 1
    ;;
esac

for FILE in ./upgrade/*; 
do 
    oc apply -f $FILE
done

echo "Checking the updated AtlasCluster CRs..."
fail="false"
oc get atlascluster --all-namespaces |sed 1d |
while IFS= read -r line; 
do 
    NAMESPACE=$(echo $line |awk '{print $1}')
    NAME=$(echo $line |awk '{print $2}')
    SPEC=`oc get atlascluster $NAME -n $NAMESPACE -o=jsonpath='{.spec}'`
    echo $SPEC
    if [[ $SPEC == *"clusterSpec"* ]]; then
        echo -e "\nAtlasCluster $NAME in namespace $NAMESPACE has been upgraded."
        echo $SPEC
    else # This should not happen
        echo -e "\nAtlasCluster $NAME in namespace $NAMESPACE has not been upgraded!"
        fail="true"
    fi
done

if [[ $fail == "true" ]]
then
    echo -e "AtlasCluster CR migration completed with errors."
else
    echo -e "AtlasCluster CR migration completed successfully."
fi







