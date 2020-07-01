#!/bin/bash
set -x
az login --identity
az vm list -g testrockRG -o table |tail -n +3 |grep -v jumpvm |awk '{print $1}' > vmlist
for vm in `cat vmlist`; do az vm show -g testrockRG -d --name $vm --query privateIps -o table |tail -n1 >> iplist; done
vm1=`cat iplist |head -n1`
#echo "starting iperf3 server on vm1"
#ssh $vm1 iperf3 -s -p 5201 &
#echo "starting sockperf server on vm1"
#ssh $vm1 sockperf sr --tcp -p 12345 &
#echo "starting qperf on vm1"
#ssh $vm1 qperf &
echo "Starting tests test with Strongswan Disabled"
for client in `cat iplist |tail -n +2`; do
ssh -o StrictHostKeyChecking=no $vm1 pgrep -x iperf3; if [ $? != 0 ]; then echo starting iperf3 server on vm1; `/usr/bin/iperf3 -s -p 5201 &`; fi 
ssh -o StrictHostKeyChecking=no $client "mkdir -p no_encryption; cd no_encryption; echo -e Executing IPERF Throughput test '\\n\\n' >> iperf_\$(hostname)_$(date +%Y%m%d).txt ;for block in 4k 8k 16k 64k 128k 256k; do echo Executing iperf for \$block >> iperf_\$(hostname)_$(date +%Y%m%d).txt; iperf3 -c $vm1 --port 5201 -l \$block -w \$block -P 35 --verbose |grep -i 'sender\\|receiver\\|CPU' |tail -n3 >> iperf_\$(hostname)_$(date +%Y%m%d).txt ; sleep 5s; echo -e '\n' >> iperf_\$(hostname)_$(date +%Y%m%d).txt; done"
ssh -o StrictHostKeyChecking=no $vm1 pgrep -x qperf; if [ $? != 0 ]; then echo starting qperf server on vm1; `/usr/bin/qperf &`; fi
ssh -o StrictHostKeyChecking=no $client "cd no_encryption; echo -e Executing QPERF Latency test '\\n\\n' >> qperf_\$(hostname)_$(date +%Y%m%d).txt ;for block in 4k 8k 16k 64k 128k 256k; do echo Executing qperf for \$block >> qperf_\$(hostname)_$(date +%Y%m%d).txt; qperf --ip_port 19766 --msg_size \$block -t 60 $vm1 tcp_bw tcp_lat >> qperf_\$(hostname)_$(date +%Y%m%d).txt ; sleep 5s; echo -e '\n' >> iperf_\$(hostname)_$(date +%Y%m%d).txt; done"
ssh -o StrictHostKeyChecking=no $vm1 pgrep -x sockperf; if [ $? != 0 ]; then echo starting sockperf server on vm1; `/usr/local/bin/sockperf sr --tcp -p 12345 &`; fi
ssh -o StrictHostKeyChecking=no $client "cd no_encryption; echo -e Executing SOCKPERF Latency test '\\n\\n' >> sockperf_\$(hostname)_$(date +%Y%m%d).txt ; for block in 4000 8000 16000 64000 128000 256000; do echo Executing sockperf for \$block >> sockperf_\$(hostname)_$(date +%Y%m%d).txt ; sockperf ping-pong -i $vm1 --tcp -m \$block -t 60 -p 12345 --full-rtt >> sockperf_\$(hostname)_$(date +%Y%m%d).txt; sleep 5s; echo -e '\n' >> sockperf_\$(hostname)_$(date +%Y%m%d).txt; done"
ssh -o StrictHostKeyChecking=no $vm1 pgrep -x httpd; if [ $? != 0 ]; then echo starting httpd server on vm1; systemctl start httpd; fi
ssh -o StrictHostKeyChecking=no $client "cd no_encryption; echo -e Executing TCPPING Latency test '\\n\\n' >> tcpping_\$(hostname)_$(date +%Y%m%d).txt ; tcpping -w 1 -x 60 $vm1 80 >> tcpping_\$(hostname)_$(date +%Y%m%d).txt"
ssh -o StrictHostKeyChecking=no $client "mv no_encryption no_encryption_$(date +%Y%m%d_%H%M%S)"
done


echo "Executing tests with strongswan Enabled"
for client in `cat iplist |tail -n +2`; do
ssh -o StrictHostKeyChecking=no $vm1 pgrep -x iperf3; if [ $? != 0 ]; then echo starting iperf3 server on vm1; `/usr/bin/iperf3 -s -p 5201 &`; fi
ssh -o StrictHostKeyChecking=no $client "systemctl start strongswan; mkdir -p with_encryption; cd iperf_encryption; echo -e Executing Throughput test '\\n\\n' >> iperf_\$(hostname)_$(date +%Y%m%d).txt ;for block in 4k 8k 16k 64k 128k 256k ; do echo Executing iperf for \$block >> iperf_\$(hostname)_$(date +%Y%m%d).txt; iperf3 -c $vm1 --port 5201 -l \$block -w \$block -P 35 --verbose |grep -i 'sender\\|receiver\\|CPU' |tail -n3 >> iperf_\$(hostname)_$(date +%Y%m%d).txt ; sleep 5s; echo -e '\n' >> iperf_\$(hostname)_$(date +%Y%m%d).txt; done"
ssh -o StrictHostKeyChecking=no $vm1 pgrep -x qperf; if [ $? != 0 ]; then echo starting qperf server on vm1; `/usr/bin/qperf &`; fi
ssh -o StrictHostKeyChecking=no $client "cd with_encryption; echo -e Executing QPERF Latency test '\\n\\n' >> qperf_\$(hostname)_$(date +%Y%m%d).txt ;for block in 4k 8k 16k 64k 128k 256k; do echo Executing qperf for \$block >> qperf_\$(hostname)_$(date +%Y%m%d).txt; qperf --ip_port 19766 --msg_size \$block -t 60 $vm1 tcp_bw tcp_lat >> qperf_\$(hostname)_$(date +%Y%m%d).txt ; sleep 5s; echo -e '\n' >> iperf_\$(hostname)_$(date +%Y%m%d).txt; done"
ssh -o StrictHostKeyChecking=no $vm1 pgrep -x sockperf; if [ $? != 0 ]; then echo starting sockperf server on vm1; `/usr/local/bin/sockperf sr --tcp -p 12345 &`; fi
ssh -o StrictHostKeyChecking=no $client "cd with_encryption; echo -e Executing SOCKPERF Latency test '\\n\\n' >> sockperf_\$(hostname)_$(date +%Y%m%d).txt ; for block in 4000 8000 16000 64000 128000 256000; do echo Executing sockperf for \$block >> sockperf_\$(hostname)_$(date +%Y%m%d).txt ; sockperf ping-pong -i $vm1 --tcp -m \$block -t 60 -p 12345 --full-rtt >> sockperf_\$(hostname)_$(date +%Y%m%d).txt; sleep 5s; echo -e '\n' >> sockperf_\$(hostname)_$(date +%Y%m%d).txt; done"
ssh -o StrictHostKeyChecking=no $vm1 pgrep -x httpd; if [ $? != 0 ]; then echo starting httpd server on vm1; systemctl start httpd; fi
ssh -o StrictHostKeyChecking=no $client "cd with_encryption; echo -e Executing TCPPING Latency test '\\n\\n' >> tcpping_\$(hostname)_$(date +%Y%m%d).txt ; tcpping -w 1 -x 60 $vm1 80 >> tcpping_\$(hostname)_$(date +%Y%m%d).txt"
ssh -o StrictHostKeyChecking=no $client "mv with_encryption with_encryption_$(date +%Y%m%d_%H%M%S)"
done

echo "Downloading test results on Jump VM"
for client in `cat iplist |tail -n +2`; do
scp -r $client:no_encryption_* .
scp -r $client:with_encryption_* .
done