#!/bin/sh

echo_n=
echo_c=
tenant_name=""
tenant_desc=""
tenant_enabled=True
tenant_id=""

user_name=""
user_pass=""
user_email=""
user_enabled=True
user_id=""

keystoneclient=""
append_user_name=""
append_user_role=""
append_user_pass=""

# heat params
heat_template_name=""
external_network_name=""
external_network_id=""

# keystone params
#os_auth_url=""

set_echo_compat() {
    case `echo "testing\c"`,`echo -n testing` in
        *c*,-n*) echo_n=   echo_c=     ;;
        *c*,*)   echo_n=-n echo_c=     ;;
        *)       echo_n=   echo_c='\c' ;;
    esac
}
set_echo_compat

get_tenant_info(){
    #stty -echo
    echo $echo_n "please input tenant name: $echo_c "
    read tenant_name1
    echo 
#    echo $echo_n "Re-enter tenant name: $echo_c "
#    read tenant_name2
#    echo 
    #stty echo
    # input tenant description
    echo $echo_n "please input tenant description: $echo_c "
    read tenant_description
    echo
    tenant_desc=$tenant_description
 
#    if [ "$tenant_name1" != "$tenant_name2" ]; then
#        echo "Sorry, tenant_name do not match."
#        echo
#        return 1
#    fi
    if [ "$tenant_name1" = "" ]; then
        echo "Sorry, you can't use an empty tenant_name here."
        echo
        return 1
    fi
    tenant_name=$tenant_name1
    return 0
 }

get_user_info(){
    
    echo $echo_n "please input user name: $echo_c"
    read username
    echo
    user_name=$username
    stty -echo
    echo $echo_n "please input user password: $echo_c"
    read userpassword1
    echo
    echo $echo_n "Re-enter  user password: $echo_c"
    read userpassword2
    echo 
    stty echo
    echo
    echo $echo_n "please input user email: $echo_c"
    read useremail
    echo
    user_email=$useremail

    if [ "$userpassword1" != "$userpassword2" ]; then
        echo "Sorry, userpassword do not match."
        echo
        return 1
    fi
    if [ "$userpassword1" = "" ]; then
        echo "Sorry, you can't use an empty user password here."
        echo
        return 1
    fi
    user_pass=$userpassword1
}

find_keystone_client(){
    for n in /usr/bin/keystone keystone
    do
        $n --no-defaults --help > /dev/null 2>&1
        status=$?
        if test $status -eq 0 
        then
            keystoneclient=$n
            return
        fi
    done
    echo "Can't find a $keystoneclient client in PATH or /usr/bin"
    exit 1
}

create_tenant_by_keystone(){
  echo "start creating tenant."
  $keystoneclient tenant-create --name=$tenant_name --description=$tenant_desc --enabled=$tenant_enabled 
  return $?
}

create_user_by_keystone(){
  echo "start creating user for tenant."
  if [ x$1 == "x" ];then
     echo "the tenant-id param isn't exits."
     exit 1
  fi
  $keystoneclient user-create --name=$user_name --pass=$user_pass --email=$user_email --tenant="$1" --enabled=$user_enabled
  return $?
}

query_tenent_id_by_name(){
  echo "query tenant id ,the tenant name is: $1"
  echo
  tenant_id=`$keystoneclient tenant-list | grep "$1" | awk -F '|' '{print $2}' | awk 'gsub(/^ *| *$/,"")'`
  echo "tenant_name: $1; tenant_id: $echo_c"
  echo "$tenant_id"
}

query_user_id_by_name(){
  echo "query user id ,the user name is: $1"
  echo
  user_id=`$keystoneclient user-list | grep "$1" | awk -F '|' '{print $2}' | awk 'gsub(/^ *| *$/,"")'`
  echo "user_name: $1; user_id: $echo_c"
  echo "$user_id"
}

role_id=""
query_role_id_by_name(){
  echo "query role id ,the role name is: $1"
  echo
  role_id=`$keystoneclient role-list | grep "$1" | awk -F '|' '{print $2}' | awk 'gsub(/^ *| *$/,"")'`
  echo "role_name: $1; role_id: $echo_c"
  echo "$role_id"
}

add_user_to_tenant(){
  userID=$1
  tenantID=$2
  roleID=$3
  echo "starting to add user to a tenant"
  if [ x$userID == "x" -o x$tenantID == "x" -o x$roleID == "x" ];then
     echo "Add user to tenant failed. parameters error."
     exit 1
  fi
  $keystoneclient user-role-add  --user_id="$userID" --tenant_id="$tenantID"  --role="$roleID"
  return $?
}

heat_stack_create_exec(){
  template_file=$1
  params=$2
  stack_name=$3
  echo "start to create stack..."
  if [ x$template_file == "x" -a x$stack_name == "x" ];then
     echo "heat stack create parameters error."
     exit 1
  fi
  echo "/usr/bin/heat stack-create -f $template_file -P $params $stack_name"
  sleep 2
  #/usr/bin/heat stack-create -f $template_file -P $params $stack_name
  nohup  /usr/bin/heat stack-create -f $template_file -P $params $stack_name > /dev/null 2>&1 &
  return $?
}

query_net_id_by_external_name(){
  echo "query external network id ,the external network name is: $1"
  echo
  external_network_id=`/usr/bin/neutron net-external-list | grep "$1" | awk -F '|' '{print $2}' | awk 'gsub(/^ *| *$/,"")'`
  if [ $? -ne 0 ];then
     echo "query external network id failed."
     exit 1
  fi
  echo "$external_network_id"
}

# build openrc file ,params : tenant_name user_name passwd
build_openrc_file(){
    os_tenant_name=$1
    os_user_name=$2
    os_passwd=$3
    openrc_str="
    #!/bin/sh
    \nexport OS_NO_CACHE='true'
    \nexport OS_TENANT_NAME='$os_tenant_name'
    \nexport OS_USERNAME='$os_user_name'
    \nexport OS_PASSWORD='$os_passwd'
    \nexport OS_AUTH_URL='http://192.168.0.2:5000/v2.0/'
    \nexport OS_AUTH_STRATEGY='keystone'
    \nexport OS_REGION_NAME='RegionOne'
    \nexport CINDER_ENDPOINT_TYPE='publicURL'
    \nexport GLANCE_ENDPOINT_TYPE='publicURL'
    \nexport KEYSTONE_ENDPOINT_TYPE='publicURL'
    \nexport NOVA_ENDPOINT_TYPE='publicURL'
    \nexport NEUTRON_ENDPOINT_TYPE='publicURL'
    "
    echo $openrc_str 
}

# write a str to file, params: str and filedir
write_str_to_file(){
   str=$1
   file_str=$2
   if [ -e "$file_str" ]; then
       echo "the file: $file_str exist. remove it."
       rm -rf $file_str
       /bin/touch $file_str
   else
       echo "the file: $file_str is not exits. create it."
       /bin/touch $file_str
   fi
   echo -e "$str" > $file_str
 
}


#get_tenant_info and user info
current_dir=$(cd `dirname $0`;pwd)
tenant_config_fileName="tenant_create_config.txt"
echo "$current_dir/$tenant_config_fileName"
if test -e "$current_dir/$tenant_config_fileName" ; then 
        source $current_dir/$tenant_config_fileName
#		if [ x$os_auth_url != "x" ];then
#           export OS_AUTH_URL=$os_auth_url
#        fi
        echo "user:$user_name ; pass:$user_pass ; user_email:$user_email"   
    else
        echo "Sorry,Tenant config file isn't exist.Please input your tenant and user information:" 
        get_tenant_info
        if [ $? -eq 1 ];then
           exit 1
        fi
        get_user_info
        if [ $? -eq 1 ];then
           exit 1
        fi
        echo "user:$user_name ; pass:$user_pass ; user_email:$user_email; tenant:$tenant_name;tenant_desc:$tenant_desc"
fi

#create tenant and user
find_keystone_client
create_tenant_by_keystone
if [ $? -ne 0 ];then
   echo "create tenant failed."
   exit 1
fi

# add user to tenant
query_tenent_id_by_name "$tenant_name"
query_user_id_by_name "$append_user_name"
if [ $? -ne 0 ];then
   echo "query user failed."
   exit 1
fi
query_role_id_by_name "$append_user_role"
if [ $? -ne 0 ];then
   echo "query role failed."
   exit 1
fi
add_user_to_tenant $user_id $tenant_id $role_id
if [ $? -ne 0 ];then
   echo "add user to tenant failed."
   exit 1
fi
#create_user_by_keystone "$tenant_id"

# unset heat exec context
heat_openrc_unsetfile_name="heat-openrc-unset"
heat_openrc_setfile_name="heat-openrc"
if [ -e $current_dir/$heat_openrc_unsetfile_name -a -e $current_dir/$heat_openrc_setfile_name ];then
       echo "start to set heat init context."
       source $current_dir/$heat_openrc_unsetfile_name
       source $current_dir/$heat_openrc_setfile_name
       export OS_TENANT_NAME=$tenant_name
       export OS_USERNAME=$append_user_name
       export OS_PASSWORD=$append_user_pass
	   openrc_str=$(build_openrc_file $tenant_name $append_user_name $append_user_pass)
       openrc_file="openrc_$tenant_name"
       write_str_to_file "$openrc_str" $current_dir/$openrc_file
#	   if [ x$os_auth_url != "x" ];then
#           export OS_AUTH_URL=$os_auth_url
#       fi
   else
       echo "Sorry, heat executing context file isn't exist."
       exit 1
fi

# heat create stack 
if [ -e $current_dir/$heat_template_name ]; then
     random_num=`/bin/date +%s`
     stack_name_str="heat-stack-$random_num"
     query_net_id_by_external_name $external_network_name
     if [ $? -ne 0 ];then
        echo "Sorry, Get external network id error."
        exit 1
     fi
     params="public_net=$external_network_id"
     echo "params: $params"
     heat_stack_create_exec $heat_template_name $params $stack_name_str 
     if test $? -ne 0 
     then
        echo " heat stack create failed."
        echo 
        exit 1
     fi
   else
      echo "heat template file isn't exits."
      exit 1
fi






