#!/bin/bash

base_directory="/opt/minecraft/servers/"
base_jar_directory="/opt/minecraft/tools/jars/"
base_stub_path="/opt/minecraft/tools/stubs/"
base_supervisor_path="/etc/supervisor/conf.d/"
server_types=("vanilla" "spigot")

select type in "${server_types[@]}"; do
	server_type="${type}"
	break;
done

server_stub_path="${base_stub_path}${server_type}-stub"

echo -e "\nServer name (snake-case):"

read server_name

full_path="${base_directory}${server_name}"

if [ -d $full_path ] 
then
	echo -e "\n$full_path already exists"
	exit
fi

echo -e "\nServer version (x.y.z):"

read server_version

jar_file="${base_jar_directory}${server_type}/${server_type}-${server_version}.jar"

if [ ! -f "$jar_file" ]; then
	echo -e "\n$jar_file has not been downloaded yet. Please download before trying again"
	exit	
fi

echo -e "\nServer port:"

read server_port

echo -e "\nMOTD:"

read motd

minecraft_script="${full_path}/server.sh"

echo -e "\n\n> Moving stubs, replacing variables...doing all the things"

# Execute commands as the minecraft user
sudo -i -u minecraft bash << EOF
mkdir "$full_path"

# Move server stub files to new server dir
cp -r "${server_stub_path}/." "${full_path}/"

# Move server executable to new server dir
cp "${base_stub_path}sh.stub" "${minecraft_script}"

# Update executable jar name to match version
sed -i "s/{version}/${server_version}/g" "${minecraft_script}"

# Make bash script executable
chmod 755 "${minecraft_script}"

# Move server properties to new server dir
cp "${base_stub_path}server.properties.stub" "${full_path}/server.properties"

# Update server port in properties
sed -i "s/{server_port}/${server_port}/g" "${full_path}/server.properties"

# Update server motd
sed -i "s/{motd}/${motd}/g" "${full_path}/server.properties"

# Move jar file to new server dir
cp "$jar_file" "${full_path}/server-${server_version}.jar"
EOF

# Move and upate supervisor conf
supervisor_conf="${base_supervisor_path}mc-${server_name}.conf"
sudo cp "${base_stub_path}supervisor.stub" "${supervisor_conf}"
sudo chown root:aclinton "${supervisor_conf}"
sudo chmod ug+w "${supervisor_conf}"
sudo sed -i "s/{server_name}/${server_name}/g" "${supervisor_conf}"

echo -e "\n> Built supervisor conf"

echo -e "\n\n> Server [${server_name}] is all ready to go on port [${server_port}]"

