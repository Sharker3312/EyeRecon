#!/bin/bash

#ApiKeys
#GHAPIKEY="False"

function check_tools(){
	tools=(assetfinder amass waybackurls findomain gospider sublist3r gauplus httpx gowitness)
	var=0

	for  tool in ${tools[@]}
	do
	counter="$(which $tool |awk "/$tool/ {print}" |wc -l)"
	if [ "$counter" == "1" ]; then
		echo -e "\033[33m$tool\033[1;32m[OK]"
	else
		echo -e "\033[33m$tool\033[1;31m[OK]"
		var=1
	fi
	done


	if [ "$var" == "1" ]; then
		echo -e "\n\n\033[35mPlease check, and install all tools"
		exit
	else
		clear
	fi

}
subdomainEnumeration(){
	output_folder="Recon"
	domain="$(echo $target|cut -d '.' -f1)"

    if [ -n "$target" ] && [ -n "$output_folder" ]; then
		[[ ! -d $output_folder ]] && mkdir $output_folder 2>/dev/null
		[[ ! -d $output_folder/$domain ]] && mkdir $output_folder/$domain 2>/dev/null
		[[ ! -d $output_folder/$domain/screenshoot ]] && mkdir $output_folder/$domain/screenshoot 2>/dev/null
		[[ ! -d $output_folder/$domain/subdomains ]] && mkdir $output_folder/$domain/subdomain 2>/dev/null
        if [ "$QUIET" != "True" ]; then

			printf "\n\033[1;32m"
			printf "\t███████╗██╗   ██╗██████╗     ███████╗███╗   ██╗██╗   ██╗███╗   ███╗\n"
			printf "\t██╔════╝██║   ██║██╔══██╗    ██╔════╝████╗  ██║██║   ██║████╗ ████║\n"
			printf "\t███████╗██║   ██║██████╔╝    █████╗  ██╔██╗ ██║██║   ██║██╔████╔██║\n"
			printf "\t╚════██║██║   ██║██╔══██╗    ██╔══╝  ██║╚██╗██║██║   ██║██║╚██╔╝██║\n"
			printf "\t███████║╚██████╔╝██████╔╝    ███████╗██║ ╚████║╚██████╔╝██║ ╚═╝ ██║\n"
			printf "\t╚══════╝ ╚═════╝ ╚═════╝     ╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝\n"
			printf "\033[m\n"


			echo -e "\033[33m[!] All subdomains will be saved in \033[1;31m$output_folder/$domain/subdomain/$domain.txt\033[m"
			
			echo -e "\033[36m>>>\033[35m Running assetfinder 🔍\033[m"
            assetfinder $target | tee -a $output_folder/$domain/subdomain/$domain.txt >/dev/null || $GOPATH/bin/assetfinder $target | tee -a $output_folder/$domain/subdomain/$domain.txt
			
			echo -e "\033[36m>>>\033[35m Running subfinder 🔍\033[m"
			subfinder --silent -d $target | tee -a $output_folder/$domain/subdomain/$domain.txt >/dev/null || $GOPATH/bin/subfinder --silent -d $target | tee -a $output_folder/$domain/subdomain/$domain.txt
			
			echo -e "\033[36m>>>\033[35m Running amass 🔍\033[m"
			amass enum -passive -d $target | tee -a $output_folder/$domain/subdomain/$domain.txt >/dev/null || $GOPATH/bin/amass enum --passive -d $target | tee -a $output_folder/$domain/subdomain/$domain.txt
			
			echo -e "\033[36m>>>\033[35m dns.bufferover.run 🔍\033[m"
			curl -s -k "https://dns.bufferover.run/dns?q=.$target"  | jq -r '.FDNS_A'[],'.RDNS'[]  | cut -d ',' -f2 | grep -F ".$target" | tee -a $output_folder/$domain/subdomain/$domain.txt >/dev/null 

			echo -e "\033[36m>>>\033[35m CTFR 🔍\033[m"
			python3 tools/ctfr/ctfr.py -d $target |unfurl -u domains |tee -a $output_folder/$domain/subdomain/$domain.txt >/dev/null
 

			echo -e "\033[36m>>>\033[35m Running WayBackUrls 🔍\033[m"
			waybackurls $target | unfurl -u domains | tee -a  $output_folder/$domain/subdomain/$domain.txt >/dev/null

			echo -e "\033[36m>>>\033[35m Running Gauplus 🔍\033[m"
			gauplus -t 40 -random-agent -subs $target | unfurl -u domains | tee -a $output_folder/$domain/subdomain/$domain.txt >/dev/null

			echo -e "\033[36m>>>\033[35m Getting Subdomains from RapidDNS.io 🔍\033[m"
			curl -s "https://rapiddns.io/subdomain/$target?full=1#result" | grep "<td><a" | cut -d '"' -f 2 | grep http | cut -d '/' -f3 | sed 's/#results//g' | sort -u | tee -a $output_folder/$domain/subdomain/$domain.txt >/dev/null
			
			echo -e "\033[36m>>>\033[35m Getting Subdomains from Riddler.io 🔍\033[m"
			curl -s "https://riddler.io/search/exportcsv?q=pld:$target" | grep -Po "(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | sort -u | tee -a $output_folder/$domain/subdomain/$domain.txt >/dev/null
			
			echo -e "\033[36m>>>\033[35m Getting Subdomains from SecurityTrails 🔍\033[m"
			curl -s "https://securitytrails.com/list/apex_domain/$target" | grep -Po "((http|https):\/\/)?(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | grep ".$domain" | sort -u | tee -a $output_folder/$domain/subdomain/$domain.txt >/dev/null
			
			echo -e "\033[36m>>>\033[35m Running findomain 🔍\033[m"
			findomain -q --target $target | tee -a $output_folder/$domain/subdomain/$domain.txt >/dev/null || $GOPATH/bin/findomain -q --target $target | tee -a $output_folder/$domain/subdomain/$domain.txt >/dev/null
		
			#echo -e "\033[36m>>>\033[35m Running Gospider 🔍\033[m"
			#gospider -s https://$target -t 20 -d 3 --sitemap --robots -w -r |cut -d ' ' -f3|unfurl -u domains| tee -a $output_folder/subdomains/$target.txt 

			echo -e "\033[36m>>>\033[35m Running Sublist3r 🔍\033[m"
			sublist3r -d $target -o $output_folder/$domain/subdomain/$domain.txt >/dev/null
		
			#if [ "$GHAPIKEY" != "False" ]; then
				#echo -e "\n\033[36m>>>\033[35m Running Github-Subdomains 🔍\033[m"
				#github-subdomains -t $GHAPIKEY -d $target | tee -a $output_folder/subdomains/$target.txt
				#cat $output_folder/subdomains/$target.txt | grep -v ">>>*" | grep -v "\*" >> $SCRIPTPATH/subs_$domain.txt
			#	rm $output_folder/subdomains/$target.txt
			#	mv $SCRIPTPATH/subs_$domain.txt $$output_folder/subdomains/$target.txt
			#fi	
		fi
		cat $output_folder/$domain/subdomain/$domain.txt|grep -v  "www." >>$output_folder/$domain/subdomain/$domain.txt
		sort -u $output_folder/$domain/subdomain/$domain.txt -o $output_folder/$domain/subdomain/$domain.txt
		
    fi
	clear
}
portsWeb(){


	
	printf "\n\033[1;32m"
	printf "\t █████╗  ██████╗████████╗██╗██╗   ██╗███████╗    ██████╗  ██████╗ ██████╗ ████████╗███████╗\n"
	printf "\t██╔══██╗██╔════╝╚══██╔══╝██║██║   ██║██╔════╝    ██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝██╔════╝\n"
	printf "\t███████║██║        ██║   ██║██║   ██║█████╗      ██████╔╝██║   ██║██████╔╝   ██║   ███████╗\n"
	printf "\t██╔══██║██║        ██║   ██║╚██╗ ██╔╝██╔══╝      ██╔═══╝ ██║   ██║██╔══██╗   ██║   ╚════██║\n"
	printf "\t██║  ██║╚██████╗   ██║   ██║ ╚████╔╝ ███████╗    ██║     ╚██████╔╝██║  ██║   ██║   ███████║\n"
	printf "\t╚═╝  ╚═╝ ╚═════╝   ╚═╝   ╚═╝  ╚═══╝  ╚══════╝    ╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝\n"
    printf "\033[m\n"                                                                                     
	echo -e "\033[36m>>>\033[35m Searching Active ports 🔍\033[m"


	output_folder="Recon"
	domain="$(echo $target|cut -d '.' -f1)"
	UNCOMMON_PORTS_WEB="81,300,591,593,832,981,1010,1311,1099,2082,2095,2096,2480,3000,3128,3333,4243,4567,4711,4712,4993,5000,5104,5108,5280,5281,5601,5800,6543,7000,7001,7396,7474,8000,8001,8008,8014,8042,8060,8069,8080,8081,8083,8088,8090,8091,8095,8118,8123,8172,8181,8222,8243,8280,8281,8333,8337,8443,8500,8834,8880,8888,8983,9000,9001,9043,9060,9080,9090,9091,9092,9200,9443,9502,9800,9981,10000,10250,11371,12443,15672,16080,17778,18091,18092,20720,32000,55440,55672"

	cat $output_folder/$domain/subdomain/$domain.txt  | httpx -silent -ports $UNCOMMON_PORTS_WEB -random-agent -status-code 200,403  -threads 50 >> $output_folder/$domain/subdomain/ports$domain.txt 
	clear

}

sub_Alive(){
	domain="$(echo $target|cut -d '.' -f1)"
	output_folder="Recon"

	printf "\n\033[1;32m"
	printf "\t █████╗  ██████╗████████╗██╗██╗   ██╗███████╗    ██████╗  ██████╗ ███╗   ███╗ █████╗ ██╗███╗   ██╗███████╗\n"
	printf "\t██╔══██╗██╔════╝╚══██╔══╝██║██║   ██║██╔════╝   ██╔══██╗██╔═══██╗████╗ ████║██╔══██╗██║████╗  ██║██╔════╝\n"
    printf "\t███████║██║        ██║   ██║██║   ██║█████╗       ██║  ██║██║   ██║██╔████╔██║███████║██║██╔██╗ ██║███████╗\n"
	printf "\t██╔══██║██║        ██║   ██║╚██╗ ██╔╝██╔══╝       ██║  ██║██║   ██║██║╚██╔╝██║██╔══██║██║██║╚██╗██║╚════██║\n"
	printf "\t██║  ██║╚██████╗   ██║   ██║ ╚████╔╝ ███████╗    ██████╔╝╚██████╔╝██║ ╚═╝ ██║██║  ██║██║██║ ╚████║███████║\n"
	printf "\t╚═╝  ╚═╝ ╚═════╝   ╚═╝   ╚═╝  ╚═══╝  ╚══════╝    ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝\n"
    printf "\033[m\n"
	echo -e "\033[36m>>>\033[35m Searching Active Domains 🔍\033[m"
	cd $output_folder/$domain/subdomain/
	cat $domain.txt | httpx  -silent -random-agent -status-code 200,403,301,302 -threads 50  |cut -d ' ' -f1|unfurl -u domains |tee -a live$domain.txt  >/dev/null
	rm $domain.txt
	sort -u live$domain.txt -o live$domain.txt
	mv live$domain.txt $domain.txt
	cd ../../../
	uniq="$(cat $output_folder/$domain/subdomain/$domain.txt | wc -l)"
	echo -e "\n\033[1;32m[!] Found \033[1;31m$uniq\033[1;32m subdomains\033[m"
	clear
}

screenshoot(){


	printf "\n\033[1;32m"
	printf "\t███████╗ ██████╗██████╗ ███████╗███████╗███╗   ██╗███████╗██╗  ██╗ ██████╗  ██████╗ ████████╗\n"
	printf "\t██╔════╝██╔════╝██╔══██╗██╔════╝██╔════╝████╗  ██║██╔════╝██║  ██║██╔═══██╗██╔═══██╗╚══██╔══╝\n"
	printf "\t███████╗██║     ██████╔╝█████╗  █████╗  ██╔██╗ ██║███████╗███████║██║   ██║██║   ██║   ██║\n"
	printf "\t╚════██║██║     ██╔══██╗██╔══╝  ██╔══╝  ██║╚██╗██║╚════██║██╔══██║██║   ██║██║   ██║   ██║\n"   
	printf "\t███████║╚██████╗██║  ██║███████╗███████╗██║ ╚████║███████║██║  ██║╚██████╔╝╚██████╔╝   ██║ \n"  
	printf "\t╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝  \n" 
	printf "\033[m\n"
	echo -e "\033[36m>>>\033[35m Running Gowitness 🔍\033[m"



	domain="$(echo $target|cut -d '.' -f1)"
	gowitness file -f $output_folder/$domain/subdomain/$domain.txt --disable-logging --threads 50 -P $output_folder/$domain/screenshoot/ >/dev/null
	clear
}

###############################################################################################################
########################################### START SCRIPT  #####################################################
###############################################################################################################
check_tools

usage() { echo -e "\033[33mUsage: $0 [-d <domain>] " 1>&2; exit 1; }

PROGARGS=$(getopt -o 'd:s:' --long 'domain:,screen:' -n 'reconFTW' -- "$@")
# Note the quotes around "$PROGARGS": they are essential!
eval set -- "$PROGARGS"
unset PROGARGS

while true; do
    case "$1" in
        '-d'|'--domain')
            target=$2

			subdomainEnumeration
			sub_Alive
			portsWeb

            shift 2
            continue
            ;;
        '-s'|'--screen')
            screen=$2

			screenshoot

            shift 2
            continue
            ;;
      '--help'| '-h'| *)
            #. ./reconftw.cfg
			            #banner
            #help
			            #tools_installed			
			            exit 1
		    ;;
    esac
done



