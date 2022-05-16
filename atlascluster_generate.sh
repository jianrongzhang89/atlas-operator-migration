#!/bin/bash
echo 'This script will generate patch files for existing AtlasCluster CRs for MongoDB Atlas Operator RHODA Service Preview Release.
The generated files will be used to re-create  AtlasCluster CRs after the Atlas Operatot has been upgraded to the new rebased release.
This script will:
1) Shutdown MongoDB Atlas Operator pod.
2) Generate patch files for existing AtlasCluster CRs.
3) Delete all existing AtlasCluster CRs after the patch files are generated.

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

answer=`oc auth can-i get atlasclusters --all-namespaces`
if [[ $answer != "yes" ]]; then
  echo "You can not list atlasclusters. Check if you logged in as cluster-admin."
  exit 1
fi

clusters=`oc get atlascluster --all-namespaces |sed 1d`
if [ -z "$clusters" ] 
then
    echo "No altalsclusters CRs found. No migration is required."
    exit 0
fi

deps=`oc get deploy  --all-namespaces |grep mongodb-atlas-operator`
OPERATOR_NS=$(echo $deps |awk '{print $1}')
DEPLOY_NAME=$(echo $deps |awk '{print $2}')

echo "Found atlasclusters CRs. We will shutdown the Atlas Opeator pod in namespace $OPERATOR_NS. This is required for the migration process."
read -p "Would you like to continue (y/n)?" answer
case ${answer:0:1} in
    y|Y )
        echo "Shutdown Atlas Opeator"
        oc scale deploy $DEPLOY_NAME -n $OPERATOR_NS  --replicas=0
        echo "Atlas Opeator paused"
    ;;
    * )
        exit 1
    ;;
esac

[ ! -d "./backup" ] && mkdir ./backup
[ ! -d "./upgrade" ] && mkdir ./upgrade

rm ./backup/* ./upgrade/*

echo "Generating upgrade files."
while IFS= read -r cluster; 
do 
    NAMESPACE=$(echo $cluster |awk '{print $1}')
    NAME=$(echo $cluster |awk '{print $2}')
    LABELS=`oc get atlascluster $NAME -n $NAMESPACE -o=jsonpath='{.metadata.labels}'`
    OWNERREFS=`oc get atlascluster $NAME -n $NAMESPACE -o=jsonpath='{.metadata.ownerReferences}'`
    INSTANCENAME=`oc get atlascluster $NAME -n $NAMESPACE -o=jsonpath='{.spec.name}'`
    INSTANCESIZE=`oc get atlascluster $NAME -n $NAMESPACE -o=jsonpath='{.spec.providerSettings.instanceSizeName}'`
    PROJECTREF=`oc get atlascluster $NAME -n $NAMESPACE -o=jsonpath='{.spec.projectRef}'`
    PROVIDERNAME=`oc get atlascluster $NAME -n $NAMESPACE -o=jsonpath='{.spec.providerSettings.providerName}'`
    REGIONNAME=`oc get atlascluster $NAME -n $NAMESPACE -o=jsonpath='{.spec.providerSettings.regionName}'`
    # Back up the data
    oc get atlascluster $NAME -n $NAMESPACE -o json > ./backup/$NAME.$NAMESPACE.json
    echo "Creating patch file for $NAME in namespace $NAMESPACE"
    cat ./templates/atlascluster_tempalte.json		\
    | sed -e "s#{{ NAMESPACE }}#$NAMESPACE#g"	\
    | sed -e "s#{{ NAME }}#$NAME#g"	\
    | sed -e "s#{{ LABELS }}#$LABELS#g"	\
    | sed -e "s#{{ OWNERREFS }}#$OWNERREFS#g"	\
    | sed -e "s#{{ INSTANCENAME }}#$INSTANCENAME#g"	\
    | sed -e "s#{{ INSTANCESIZE }}#$INSTANCESIZE#g"	\
    | sed -e "s#{{ PROVIDERNAME }}#$PROVIDERNAME#g"	\
    | sed -e "s#{{ REGIONNAME }}#$REGIONNAME#g"	\
    | sed -e "s#{{ PROJECTREF }}#$PROJECTREF#g"	\
    > ./upgrade/$NAME.$NAMESPACE.json
done < <(printf '%s\n' "$clusters")

echo "Upgrade files generated."
ls -lrt  ./upgrade/*.json

echo "Now we will delete the old AtlasCluster CRs. If anything goes wrong, you can use the files under ./backup to recover"
read -p "Would you like to continue (y/n)?" answer
case ${answer:0:1} in
    y|Y )
        echo "Deleting AtlasCluster CRs in the cluster"
        oc delete atlascluster --all --all-namespaces
        echo "AtlasCluster CRs deleted"
    ;;
    * )
        exit 1
    ;;
esac 








