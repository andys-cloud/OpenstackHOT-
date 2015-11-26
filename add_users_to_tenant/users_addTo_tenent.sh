#!/bin/sh


tenant_name=""
add_users=()
role_name=""

set_echo_compat
currentdir=$(cd `dirname $0`;pwd)
functionFile="$currentdir/function.sh"
if [ -e $functionFile ];then
       . $functionFile
       echo ""
   else
       echo "the base function file: function.sh is not exits.please check the derectory: $currentdir"
       exit 1
fi
configfileName="$currentdir/users_addTo_tenent_config.sh"
if [ -e $configfileName ];then
       . $configfileName
       echo ""
   else
       echo "the config file: users_addTo_tenent_config.sh is not exits.please check the derectory: $currentdir; Or input relative infomation?[y/n]"
       read is_input
       if [ x$is_input = x"y" -o x$is_input = x"Y" ];then
              get_tenant_info
              if [ $? -eq 1 ];then
                  exit 1
              fi
              get_user_info
              if [ $? -eq 1 ];then
                  exit 1
              fi
              get_role_info
              if [ $? -eq 1 ];then
                  exit 1
              fi
              add_users[${#add_users[@]}]=$user_name
          else
              echo "Not get right params,exit..."
              exit 1
       fi
fi
echo "tenant: $tenant_name ; role: $role_name"

#add_users=()
#echo "---${#add_users[@]}"
#echo "---${!add_users[@]}"
array_length=${#add_users[@]}
if [ x"$array_lengh" = x"0" ];then
       echo "the user array is null"
   else
       echo "array is not null"
#       for var in ${!add_users[@]};do
#          echo "${add_users[$var]}"
#       done
fi

find_keystone_client
for var in "${!add_users[@]}";do
#    echo ${add_users[$var]}
    tenant_id=""
    query_tenent_id_by_name $tenant_name
    user_id=""
    query_user_id_by_name ${add_users[$var]}
    role_id=""
    query_role_id_by_name $role_name
    echo "tenant id : $tenant_id; user id:$user_id; role id=$role_id;"
    add_user_to_tenant $user_id $tenant_id $role_id
    if [ $? -ne 0 ] ;then 
       echo "Add user to tenant failed.whitch user id is $user_id ; tenant id is : $tenant_id ."
    fi
done


