## IPSEC strongSwan on Azure VMs

### Repo has four terraform templates
- loose_vms.tf - Creates VMs in each Zone within a region within single VNET and 3 subnets mapped to per zone.
- loosevms_peervnet.tf - Creates 2 VNETs in peered configuration. VMs are created in each VNET with Subnet and zone configuration
- ppg_avset_vms.tf - Creates a PPG resource within a VNET in a region. Then creates VMs within AVSET attached to this PPG to ensure very close co-location
- ppg_avset_zonal.tf - Creates a PPG resource tied to a zonal anchor VM. This ensures PPG is attached to a zone. Then creates an AVSET and attaches to the PPG. Later creates VMs within this PPG with AVSET ensuring close proximity with PPG in a zone along with AVset.


### Note :
1. Update variables.tf and terraform.tfvars according to scenarios, number and sizes of VMs required.

2. As a part of these terraform templates, an Azure User Managed Identity is also created which may be later used to download secrets or certificates from keyvault.
This User MSI is also created for Jump VM enabling it to easily run performance tests on the created VMs.

3. These templates also create NSG rules to Allow/Deny Outbound AzureCloud and Internet access. Azure Cloud facilitates access to Azure Management Plane IPs. Internet Outbound rule has been Allowed to install strongswan and many other rpms. Once the initial install is completed, these rules can be stopped in NSG.

4. As of now, there is no state maintained for terraform templates but can be done by creating azure storage account and container to store state files.


install_strongswan.sh - This script is called as a part custom data script during VM creation. This script installs and configures following :
- RHEL EPEL Repo
- Installs strongswan iperf3 qperf httpd git tcpping sockperf
- Creates OS level firewall rules to allow and open ports for communication of above installed services
- Configures strongswan connection settings
- Configures strongswan secrets
- Adds local user to sudoers group 
	

jumpvmsetup.sh - This is a small script with instructions used to install azure cli on the jump VM.
This az cli then fetches information of all installed VMs within the RG with help from the earlier created Azure MSI. This information is then used to run tests.

runtests.sh - This script must be manually copied to Jump VM and executed to run performance tests.
- RGNAME variable must be manually populated to run tests on VMs within desired RG.
- Tests are run with block sizes - 4k, 8k, 16, 64k, 128k and 256k
- This script performs following tests with and without encryption (strongswan) enabled. The first VM is designated as a server against which all remaining server (clients) run the tests.
	1. iperf3 - measures throughput 
	2. qperf - measures latency
	3. tcpping - measures initial connect latencies
	4. sockperf - measures subsequent latencies

The results are then scp'ed to jump VM.

	
	


