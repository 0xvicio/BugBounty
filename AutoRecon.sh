#!/bin/bash

echo "Welcome!"
echo "Please, enter program name:"
read program

echo "Creating Directories. Please wait..."
mkdir $program 
cd $program

echo "Please, enter domain to BB: "
read domain
echo "$domain" >> scope.txt

echo "Scanning Subdomains for: $domain"
subfinder -d $domain | tee -a subs_subfinder.txt&
wait

assetfinder $domain.com | tee -a subs_assetfinder.txt
wait

amass enum -d $domain -nolocaldb | tee -a subs_amass.txt
wait

echo "Merging subdomains"
cat subs*| sort -u > all_subs.txt
wait
echo "Filtering out Resolving subdomains. Please, wait..."
cat all_subs.txt| httprobe -p http:81 -p https:4080 -p https:8443 -p http:8080 -p http:3000 -p http:6080 -p https:6080 -p https:9200 -p https:9090 | tee -a all_subs_probed1.txt
wait
cat all_subs.txt| httpx -threads 150 | tee -a all_subs_probed2.txt
wait

echo "Appending all probed subdomains & removing duplicate entries"
cat all_subs_probed* | sort -u > allsubs_probed.txt
wait

echo "Now comes the FUN part! Make sure you're running Burp Suite on port 8080"
echo "Identifying technologies"
~/tools/Whatweb/whatweb -i allsubs_probed.txt --proxy 127.0.0.1:8080 | tee -a technologies.txt
wait

echo "Identifying archived paths"
waybackurls $domain | tee -a waybackurls.txt
wait

echo "Identifying interesting directories"
gau $domain -subs -b jpg,gif,tiff,png  -t 10 -p 127.0.0.1:8080 | tee -a gau.txt
wait

echo "Using Parallel to "
cat allsubs_probed.txt | parallel -j50 -q curl -w 'Status:%{http_code}\t  Size:%{size_download}\t %{url_effective}\n' -o /dev/null -sk | tee -a parallels.txt
wait

echo "Using httpx to "
cat allsubs_probed.txt| httpx -title -tech-detect -status-code| tee -a httpx.txt
wait

echo "Look for specific vuln in URLpath (example: swagger)"
cat allsubs_probed.txt | httpx -path /swagger-api/ -status-code -content-length
wait

echo "Running Aquatone to screenshot subdomain pages"
cat allsubs_probed.txt | aquatone -ports xlarge -proxy 127.0.0.1:8080
wait

echo "Running Eyewitness to screenshot subdomain pages"
eyewitness -f allsubs_probed.txt --web --proxy-ip 127.0.0.1 --proxy-port 8080
wait

echo "Thank you for using this program. Hack on!!"
