#!/bin/bash
set -x
RGNAME=blackrockRG
az login --identity
az vm list -g $RGNAME -o table |tail -n +3 |grep -iv 'jumpvm\|anchrovm' |awk '{print $1}' > vmlist
for vm in `cat vmlist`; do az vm show -g $RGNAME -d --name $vm --query privateIps -o table |tail -n1 >> iplist; done
vm1=`cat iplist |head -n1`
echo "Starting tests test with Strongswan Disabled"
for client in `cat iplist |tail -n +2`; do
ssh -o StrictHostKeyChecking=no $vm1 'pgrep -x iperf3; if [ $? != 0 ]; then echo starting iperf3 server on vm1; nohup /usr/bin/iperf3 -s -p 5201 > /dev/null 2>&1 & fi'
ssh -o StrictHostKeyChecking=no $client "mkdir -p no_encryption; cd no_encryption; echo -e Executing IPERF Throughput test '\\n\\n' >> iperf_\$(hostname)_$(date +%Y%m%d).txt ;for block in 4k 8k 16k 64k 128k 256k; do echo Executing iperf for \$block >> iperf_\$(hostname)_$(date +%Y%m%d).txt; iperf3 -c $vm1 --port 5201 -l \$block -w \$block -P 35 --verbose |grep -i 'sender\\|receiver\\|CPU' |tail -n3 >> iperf_\$(hostname)_$(date +%Y%m%d).txt ; sleep 5s; echo -e '\n' >> iperf_\$(hostname)_$(date +%Y%m%d).txt; done"
ssh -o StrictHostKeyChecking=no $vm1 'pgrep -x qperf; if [ $? != 0 ]; then echo starting qperf server on vm1; nohup /usr/bin/qperf > /dev/null 2>&1 & fi'
ssh -o StrictHostKeyChecking=no $client "cd no_encryption; echo -e Executing QPERF Latency test '\\n\\n' >> qperf_\$(hostname)_$(date +%Y%m%d).txt ;for block in 4k 8k 16k 64k 128k 256k; do echo Executing qperf for \$block >> qperf_\$(hostname)_$(date +%Y%m%d).txt; qperf --ip_port 19766 --msg_size \$block -t 60 $vm1 tcp_bw tcp_lat >> qperf_\$(hostname)_$(date +%Y%m%d).txt ; sleep 5s; echo -e '\n' >> iperf_\$(hostname)_$(date +%Y%m%d).txt; done"
ssh -o StrictHostKeyChecking=no $vm1 'pgrep -x sockperf; if [ $? != 0 ]; then echo starting sockperf server on vm1; nohup /usr/local/bin/sockperf sr --tcp -p 12345 > /dev/null 2>&1 & fi'
ssh -o StrictHostKeyChecking=no $client "cd no_encryption; echo -e Executing SOCKPERF Latency test '\\n\\n' >> sockperf_\$(hostname)_$(date +%Y%m%d).txt ; for block in 4000 8000 16000 64000 128000 256000; do echo Executing sockperf for \$block >> sockperf_\$(hostname)_$(date +%Y%m%d).txt ; sockperf ping-pong -i $vm1 --tcp -m \$block -t 60 -p 12345 --full-rtt >> sockperf_\$(hostname)_$(date +%Y%m%d).txt; sleep 5s; echo -e '\n' >> sockperf_\$(hostname)_$(date +%Y%m%d).txt; done"
ssh -o StrictHostKeyChecking=no $vm1 'pgrep -x httpd; if [ $? != 0 ]; then echo starting httpd server on vm1; nohup sudo systemctl start httpd  > /dev/null 2>&1 & fi'
ssh -o StrictHostKeyChecking=no $client "mkdir -p no_encryption; cd no_encryption; echo -e Executing TCPPING Latency test '\\n\\n' >> tcpping_\$(hostname)_$(date +%Y%m%d).txt ; sudo tcpping -w 1 -x 60 $vm1 80 >> tcpping_\$(hostname)_$(date +%Y%m%d).txt"
ssh -o StrictHostKeyChecking=no $client "mv no_encryption no_encryption_$(date +%Y%m%d_%H%M%S)"
done


echo "Executing tests with strongswan Enabled"
for vms in `cat iplist`; do
ssh -o StrictHostKeyChecking=no $vms 'pgrep -x strongswan; if [ $? != 0 ]; then echo starting strongswan on $vms; nohup sudo systemctl start strongswan > /dev/null 2>&1 & fi'
done
for client in `cat iplist |tail -n +2`; do
echo "Initiating connection"
ssh -o StrictHostKeyChecking=no $vm1 "ping -c20 $client"
ssh -o StrictHostKeyChecking=no $client "ping -c20 $vm1"
echo "Initiating connection done. Please check manually if you don't recieve ping response on client"
ssh -o StrictHostKeyChecking=no $vm1 'pgrep -x iperf3; if [ $? != 0 ]; then echo starting iperf3 server on vm1; nohup /usr/bin/iperf3 -s -p 5201 > /dev/null 2>&1 & fi'
ssh -o StrictHostKeyChecking=no $client "mkdir -p with_encryption; cd with_encryption; echo -e Executing Throughput test '\\n\\n' >> iperf_\$(hostname)_$(date +%Y%m%d).txt ;for block in 4k 8k 16k 64k 128k 256k ; do echo Executing iperf for \$block >> iperf_\$(hostname)_$(date +%Y%m%d).txt; iperf3 -c $vm1 --port 5201 -l \$block -w \$block -P 35 --verbose |grep -i 'sender\\|receiver\\|CPU' |tail -n3 >> iperf_\$(hostname)_$(date +%Y%m%d).txt ; sleep 5s; echo -e '\n' >> iperf_\$(hostname)_$(date +%Y%m%d).txt; done"
ssh -o StrictHostKeyChecking=no $vm1 'pgrep -x qperf; if [ $? != 0 ]; then echo starting qperf server on vm1; nohup /usr/bin/qperf > /dev/null 2>&1 & fi'
ssh -o StrictHostKeyChecking=no $client "cd with_encryption; echo -e Executing QPERF Latency test '\\n\\n' >> qperf_\$(hostname)_$(date +%Y%m%d).txt ;for block in 4k 8k 16k 64k 128k 256k; do echo Executing qperf for \$block >> qperf_\$(hostname)_$(date +%Y%m%d).txt; qperf --ip_port 19766 --msg_size \$block -t 60 $vm1 tcp_bw tcp_lat >> qperf_\$(hostname)_$(date +%Y%m%d).txt ; sleep 5s; echo -e '\n' >> iperf_\$(hostname)_$(date +%Y%m%d).txt; done"
ssh -o StrictHostKeyChecking=no $vm1 'pgrep -x sockperf; if [ $? != 0 ]; then echo starting sockperf server on vm1; nohup /usr/local/bin/sockperf sr --tcp -p 12345 > /dev/null 2>&1 & fi'
ssh -o StrictHostKeyChecking=no $client "cd with_encryption; echo -e Executing SOCKPERF Latency test '\\n\\n' >> sockperf_\$(hostname)_$(date +%Y%m%d).txt ; for block in 4000 8000 16000 64000 128000 256000; do echo Executing sockperf for \$block >> sockperf_\$(hostname)_$(date +%Y%m%d).txt ; sockperf ping-pong -i $vm1 --tcp -m \$block -t 60 -p 12345 --full-rtt >> sockperf_\$(hostname)_$(date +%Y%m%d).txt; sleep 5s; echo -e '\n' >> sockperf_\$(hostname)_$(date +%Y%m%d).txt; done"
ssh -o StrictHostKeyChecking=no $vm1 'pgrep -x httpd; if [ $? != 0 ]; then echo starting httpd server on vm1; nohup sudo systemctl start httpd > /dev/null 2>&1 &  fi'
ssh -o StrictHostKeyChecking=no $client "mkdir -p with_encryption; cd with_encryption; echo -e Executing TCPPING Latency test '\\n\\n' >> tcpping_\$(hostname)_$(date +%Y%m%d).txt ; sudo tcpping -w 1 -x 60 $vm1 80 >> tcpping_\$(hostname)_$(date +%Y%m%d).txt"
ssh -o StrictHostKeyChecking=no $client "mv with_encryption with_encryption_$(date +%Y%m%d_%H%M%S)"
done

echo "Downloading test results on Jump VM"
for client in `cat iplist |tail -n +2`; do
scp -r $client:no_encryption_* .
scp -r $client:with_encryption_* .
done
