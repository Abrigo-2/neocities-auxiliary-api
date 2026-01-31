#/bin/bash

# Usage tip 1: place this file on the current directory of your neocities directory, then run:
#   source neocities-auxiliary-api.sh 
# on the terminal.

# Usage tip 2: simply type
#   neo-help
# on the terminal.

function neo-commit(){
# to find which files were modified and deleted in the last commit, do: 
# git log -1 --stat
# to output the paths of all files involved in the last commit, do: 
# git show --name-only

# Deletions are run first, then insertions.


# Add the path of all deleted files to: neoaux-commit-DEL.out
directory=$( cat ./neoaux-commit-DEL.out | _exclude )
directory_size=$( echo "$directory" | wc -l )

i1=1
while [ $i1 -le $directory_size ]; do 

current_file=$( echo "$directory" | head -n $i1 | tail -n 1 )
echo "$(tput bold)attempt $i1$(tput sgr0): deleting file $(tput setaf 1)$current_file$(tput sgr0) ...";

# -F "neocities-name=@local-name"
curl -u "$NEOCITIES_LOGIN_DATA" -d "filenames[]=$current_file" "https://neocities.org/api/delete"

((i1++))
done

# Add the path of all modified or added files to: neoaux-commit-add.out
directory=$( cat ./neoaux-commit-add.out | _exclude )
directory_size=$( echo "$directory" | wc -l )

i=1
while [ $i -le $directory_size ]; do 

current_file=$( echo "$directory" | head -n $i | tail -n 1 )
echo "$(tput bold)attempt $(($i1 + $i))$(tput sgr0): uploading file $(tput setaf 1)$current_file$(tput sgr0) ...";

# -F "neocities-name=@local-name"
curl -u "$NEOCITIES_LOGIN_DATA" -F "$current_file=@$current_file" "https://neocities.org/api/upload"

((i++))
done
# If you notice the attempts log skipping around (aka jumping from 1 to 3...), it may be because an entry got excluded.
}

function _exclude(){
# Reads contents from pipe. Only ever receives a list of files.
output=""
while read -r line; do
output="$output
$line"
done

# Every line in neocities-exclude.out is a pattern that'll be excluded from the pipe.
exclude_list=$( cat ./neoaux-exclude.out )
exclude_list_size=$( echo "$exclude_list" | wc -l )

i=1
while [ $i -le $exclude_list_size ]; do

current_line=$( echo "$exclude_list" | head -n $i | tail -n 1 )
output=$(echo "$output" | grep -v "$current_line" )

((i++))
done

# Outputs the curated file list, with all exclusions applied.
echo "$output"
}

# Outputs instructions on how to use this script.
function neo-help(){
echo -e "$(tput bold)*** This library assumes you've got $(tput setaf 2)cURL$(tput sgr0)$(tput bold) and $(tput setaf 2)Git$(tput sgr0)$(tput bold) set up, and that your current directory has been properly set up as a Git repository! ***$(tput sgr0)"
echo -e "\n"

echo -e "$(tput setaf 2)neo-login$(tput sgr0): Logs your neocities' username and password to be used in file uploads. $(tput bold)Run this script before all else.$(tput sgr0)\n  $(tput setaf 1)$(tput bold)CAUTION:$(tput sgr0)$(tput setaf 1) Your site credentials will be saved to an environment variable ($(tput sgr0)$(tput bold)NEOCITIES_LOGIN_DATA$(tput sgr0)$(tput setaf 1)) as $(tput sgr 0 1)$(tput setaf 1)plain, readable text.$(tput sgr0) for the duration of this shell session.\n  If you fail to log in, you may have to start over in a new bash terminal."
echo -e "\n"

echo -e "$(tput setaf 2)neoaux-exclude.out$(tput sgr0): Each $(tput sgr 0 1)line$(tput sgr0) in this file holds a single pattern that'll be searched for in the path of every file involved in a batch upload, in order to exclude them.\n  Think of it as a $(tput bold).gitignore$(tput sgr0) file.\n  $(tput sgr 0 1)Current neoaux-exclude.out configuration:$(tput sgr0) $(cat ./neoaux-exclude.out | tr "\n" " ")\n  $(tput bold)Recommended neoaux-exclude.out configuration:$(tput sgr0) .git .gitignore .sh .out"
echo -e "$(tput setaf 1)_exclude: $(tput bold)You won't need to modify this function.$(tput sgr0)"
echo -e "\n"

echo -e "$(tput setaf 2)neo-push$(tput sgr0): uploads a single file to your neocities repository.\n  $(tput bold)Takes 1 single argument:$(tput sgr0) your file's path."

echo -e "$(tput setaf 2)neo-push-all$(tput sgr0): upload every single file within the current directory to your neocities repository.\n  $(tput bold)Takes no arguments.$(tput sgr0)\n  $(tput setaf 1)Subject to neoaux-exclude.out$(tput sgr0)"

echo -e "$(tput setaf 2)neo-push-errorlog$(tput sgr0): Reads the log printed by $(tput bold)neocities-push-all.sh$(tput sgr0) and throws back every file upload attempt which failed.\n  $(tput bold)Usage:\n  1.$(tput sgr0) Copy the $(tput bold)entire$(tput sgr0) log printed by the latest $(tput bold)neocities-push-all.sh$(tput sgr0) call.\n  $(tput bold)2.$(tput sgr0) Paste it into $(tput bold)neocities-push-errorlog.out$(tput sgr0)\n  $(tput bold)3. $(tput sgr0)$(tput setaf 1)Only then$(tput sgr0) you may run this script."
echo -e "\n"

echo -e "$(tput setaf 2)neoaux-commit-add.out$(tput sgr0) and $(tput setaf 1)neoaux-commit-DEL.out$(tput sgr0): Each line names a file to be $(tput setaf 2)added$(tput sgr0) or $(tput setaf 1)deleted$(tput sgr0) from your neocities repository the next time $(tput bold)neo-commit$(tput sgr0) is called.\n  If a file to be added already exists in your repository, it'll be updated instead."
echo -e "$(tput setaf 2)neo-commit$(tput sgr0): Selectively deletes, then uploads files on your neocities repository. You may call it after $(tput bold)Git$(tput sgr0) commits.\n  $(tput setaf 1)Subject to neoaux-exclude.out$(tput sgr0)"
}

# Records and saves your neocities credentials.
function neo-login(){
read -p "Type out your username: $(tput setaf 2)" user
echo "$(tput sgr0)Type out your $(tput setaf 1)password. It will be stored in plain text:$(tput sgr0)" 
read -r -s pass

export NEOCITIES_LOGIN_DATA="$user:$pass"

# Creates a '#' array to display instead of the password.
pass2=""
pass_size=$(echo "$pass" | wc -m)
i=1
while [ $i -le $pass_size ]; do
pass2="$pass2#"
((i++))
done

# Show credentials onscreen and attempt login.
echo -e "$(tput setaf 1)Credentials saved.$(tput sgr0)\n$(tput bold)USER:$(tput sgr0) $user\n$(tput bold)PASSWORD:$(tput sgr0) $pass2"
curl -u "$NEOCITIES_LOGIN_DATA" "https://neocities.org/api/info"

# From the developer's API: getting an SSH key.
#curl -u "USER:PASS" "https://neocities.org/api/key"
}

# Uploads single file from your current directory into your neocities repo.
function neo-push(){
echo "$(tput bold)attempting$(tput sgr0): uploading file $(tput setaf 1)$1$(tput sgr0) ..."

# -F "neocities-name=@local-name"
curl -u "$NEOCITIES_LOGIN_DATA" -F "$1=@$1" "https://neocities.org/api/upload"
}

# Mass uploads all the files in your current directory into your neocities repo.
function neo-push-all(){
directory=$( find . -type f | _exclude )
directory_size=$( echo "$directory" | wc -l )

i=1
while [ $i -le $directory_size ]; do 

current_file=$( echo "$directory" | head -n $i | tail -n 1 )
echo "$(tput bold)attempt $i$(tput sgr0): uploading file $(tput setaf 1)$current_file$(tput sgr0) ...";

# -F "neocities-name=@local-name"
curl -u "$NEOCITIES_LOGIN_DATA" -F "$current_file=@$current_file" "https://neocities.org/api/upload"

((i++))
done
}

# Extracts failed attempts from previous neocities-push-all call.
function neo-push-errorlog(){
grep -i -B 2 -A 2 -e "error" -e "fail" ./neoaux-push-errorlog.out
}
