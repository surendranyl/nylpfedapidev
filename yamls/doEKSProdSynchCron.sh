echo "Prod Auto Synch Started `date`"  >> /home/ec2-user/k8sutils/logs/prodsynch_cron_audit.log

pfpass1=`curl -v -k -s --cert /home/ec2-user/k8sutils/certs/awseksping-cert.pem "https://pmws.newyorklife.com/AIMWebService/api/Accounts?AppID=PingFedCCP&safe=AWS_INF_APP1664_PROD&folder=root&object=PRD-Admin-PingFed"|cut -d"\"" -f4`

PF_APIEndpoint=https://www.cpfconsole.newyorklife.com/pf-admin-api/v1/configArchive/export

#PingFederate Synch

if [ -s /tmp/configArchivePRD.zip ]
then
        rm /tmp/configArchivePRD.zip
fi

cd /tmp
git clone https://068bceabb129402e0e007dd6908ec23380da17ba@git.nylcloud.com/ECS/nylpfedprod

curl -k --user administrator:$pfpass1 $PF_APIEndpoint -o /tmp/configArchivePRD.zip

if [ -s /tmp/configArchivePRD.zip ]
then
        if zipinfo -t /tmp/configArchivePRD.zip > /dev/null
        then
                unzip -o /tmp/configArchivePRD.zip -d /tmp/nylpfedprod/layered-profiles/pingfederate/instance/server/default/data

                if [ $? -eq 0 ]
                then
                        branch_name=CHG_`date +"%m%d%Y%I%M"`_autosynch
                        cd /tmp/nylpfedprod
                        git checkout -b $branch_name
                        git add .
                        git commit --message="Updated config for $branch_name"
                        git push --set-upstream origin $branch_name
                        git checkout master
                        git merge $branch_name
                        git push origin master
                fi
        else
                echo "Couldn't fetch PingFederate export archive, please check if the PingFederate Admin Server is up and running!"
        fi
else
     echo "Couldn't fetch PingFederate export archive, please check if the PingFederate Admin Server is up and running!"
fi

rm -rf /tmp/nylpfedprod

if [ -s /tmp/configArchivePRD.zip ]
then
        rm /tmp/configArchivePRD.zip
fi



echo "Prod Auto Synch Finished `date`"  >> /home/ec2-user/k8sutils/logs/prodsynch_cron_audit.log