# atlas-operator-migration

Thhe scripts will generate patch files for existing AtlasCluster CRs for MongoDB Atlas Operator RHODA Service Release so that the operator can be upraded to the latest rebased release that introuduced breaking changes in the CRD.

atlascluster_generate.sh: generate patch files
atlascluster_upgrade.sh: recreate AtlasCluster CRs based on the patch files after the operator has been upgraded.

Clone this repo to your local machine and switch to the bash shell.

You should have logged into the OpenShift cluster as a cluster administrator.

Sample output is as follows.
We first generate the patch files.
```
jianrzha-mac:atlas-operator-migration zhangj$ ./atlascluster_generate.sh 
This script will generate patch files for existing AtlasCluster CRs for MongoDB Atlas Operator RHODA Service Preview Release.
The generated files will be used to re-create  AtlasCluster CRs after the Atlas Operatot has been upgraded to the new rebased release.
This script will:
1) Shutdown MongoDB Atlas Operator pod.
2) Generate patch files for existing AtlasCluster CRs.
3) Delete all existing AtlasCluster CRs after the patch files are generated.

You must have logged into the OpenShift cluster as a cluster administrator in order to proceed.
Would you like to continue (y/n)?y
Yes
Found atlasclusters CRs. We will shutdown the Atlas Opeator pod in namespace openshift-dbaas-operator. This is required for the migration process.
Would you like to continue (y/n)?y
Shutdown Atlas Opeator
deployment.apps/mongodb-atlas-operator scaled
Atlas Opeator paused
rm: ./backup/*: No such file or directory
rm: ./upgrade/*: No such file or directory
Generating upgrade files.
Creating patch file for mytestcluster in namespace jianrong
Creating patch file for test10 in namespace test
Upgrade files generated.
-rw-r--r--  1 zhangj  staff  927 May 16 16:01 ./upgrade/mytestcluster.jianrong.json
-rw-r--r--  1 zhangj  staff  891 May 16 16:01 ./upgrade/test10.test.json
Now we will delete the old AtlasCluster CRs. If anything goes wrong, you can use the files under ./backup to recover
Would you like to continue (y/n)?y
Deleting AtlasCluster CRs in the cluster
atlascluster.atlas.mongodb.com "mytestcluster" deleted
atlascluster.atlas.mongodb.com "test10" deleted
AtlasCluster CRs deleted
jianrzha-mac:atlas-operator-migration zhangj$ 
```
After the MongoDB Atlas Operator has been upgraded to the new rebased release, run atlascluster_upgrade.sh to recreate the AtlasCluster CRs.
```
jianrzha-mac:atlas-operator-migration zhangj$ ./atlascluster_upgrade.sh 
This script recreate AtlasCluster CRs using the patch files after MongoDB Atlas Operator for RHODA has been upgraded to the new rebased release.

You must have logged into the OpenShift cluster as a cluster administrator in order to proceed.
Would you like to continue (y/n)?y
Yes
atlascluster.atlas.mongodb.com/mytestcluster created
atlascluster.atlas.mongodb.com/test10 created
Checking the updated AtlasCluster CRs...
{"clusterSpec":{"name":"mytestcluster","providerSettings":{"backingProviderName":"AWS","instanceSizeName":"M0","providerName":"TENANT","regionName":"US_EAST_1"}},"projectRef":{"name":"atlas-project-jckc8","namespace":"openshift-dbaas-operator"}}

AtlasCluster mytestcluster in namespace jianrong has been upgraded.
{"clusterSpec":{"name":"mytestcluster","providerSettings":{"backingProviderName":"AWS","instanceSizeName":"M0","providerName":"TENANT","regionName":"US_EAST_1"}},"projectRef":{"name":"atlas-project-jckc8","namespace":"openshift-dbaas-operator"}}
{"clusterSpec":{"name":"test10","providerSettings":{"backingProviderName":"AWS","instanceSizeName":"M0","providerName":"TENANT","regionName":"US_EAST_1"}},"projectRef":{"name":"atlas-project-8g665","namespace":"openshift-dbaas-operator"}}

AtlasCluster test10 in namespace test has been upgraded.
{"clusterSpec":{"name":"test10","providerSettings":{"backingProviderName":"AWS","instanceSizeName":"M0","providerName":"TENANT","regionName":"US_EAST_1"}},"projectRef":{"name":"atlas-project-8g665","namespace":"openshift-dbaas-operator"}}
AtlasCluster CR migration completed successfully.
jianrzha-mac:atlas-operator-migration zhangj$ 
```
