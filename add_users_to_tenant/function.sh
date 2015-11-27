#!/bin/sh 

keystoneclient=""

set_echo_compat() {
    case `echo "testing\c"`,`echo -n testing` in
        *c*,-n*) echo_n=   echo_c=     ;;
        *c*,*)   echo_n=-n echo_c=     ;;
        *)       echo_n=   echo_c='\c' ;;
    esac
}

get_tenant_info(){
    #stty -echo
    echo $echo_n "please input tenant name: $echo_c "
    read tenant_name1
    echo 
    #stty echo
    # input tenant description
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
    if [ "$username" = "" ]; then
        echo "Sorry, you can't input an empty user name here."
        echo
        return 1
    fi
    user_name=$username
#    echo $user_name
    return 0
}

get_role_info(){
    echo $echo_n "please input role name: $echo_c"
    read rolename
    echo
    if [ "$rolename" = "" ]; then
        echo "Sorry, you can't input an empty role name here."
        echo
        return 1
    fi
    role_name=$rolename
#    stty -echo
#    stty echo
#    echo $role_name
    return 0
}

# find keystone client
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

# query tenant ,input tenant name params 
query_tenent_id_by_name(){
  echo "query tenant id ,the tenant name is: $1"
  echo
  tenant_id=`$keystoneclient tenant-list | grep "$1" | awk -F '|' '{print $2}' | awk 'gsub(/^ *| *$/,"")'`
  if [ x$tenant_id == x"" ];then
     echo "Can't find the tenant: $1"
     exit 1
  fi
  echo "tenant_name: $1; tenant_id: $echo_c"
  echo "$tenant_id"
}
 
#query user id , unput user name param
query_user_id_by_name(){
  echo "query user id ,the user name is: $1"
  echo
  user_id=`$keystoneclient user-list | grep "$1" | awk -F '|' '{print $2}' | awk 'gsub(/^ *| *$/,"")'`
  if [ x$user_id == x"" ];then
     echo "Can't find the user: $1"
     exit 1
  fi
  echo "user_name: $1; user_id: $echo_c"
  echo "$user_id"
}
 
# query role id ,input role name param
query_role_id_by_name(){
  echo "query role id ,the role name is: $1"
  echo
  role_id=`$keystoneclient role-list | grep "$1" | awk -F '|' '{print $2}' | awk 'gsub(/^ *| *$/,"")'`
  if [ x$role_id == x"" ];then
     echo "Can't find the role: $1"
     exit 1
  fi
  echo "role_name: $1; role_id: $echo_c"
  echo "$role_id"
}
 
# add user to tenant , input userid,tenantid and roleid params
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
