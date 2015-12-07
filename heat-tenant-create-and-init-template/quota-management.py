from neutronclient.neutron import client as neutronc
from novaclient import client as novac
from cinderclient import client as cinderc
import os,sys
import ConfigParser

NOVA_CLIENT_VERSION="2"
NEUTRON_CLIENT_VERSION="2.0"
CINDER_CLIENT_VERSION="1"

class Client():

    """ init params """
    def __init__(self,auth_url,tenant_name,username,password,region_name=""):
        self.OS_AUTH_URL = auth_url
        self.OS_TENANT_NAME = tenant_name
        self.OS_USERNAME = username
        self.OS_PASSWORD = password
        self.OS_REGION_NAME = region_name
        self.Nova_client = None
        self.Neutron_client = None
        self.Cinder_client = None

    """ init clients """
    def init_client(self,admin_projectId):
        admin_project_id=admin_projectId
        if None == self.Nova_client:
           self.Nova_client = novac.Client(NOVA_CLIENT_VERSION,
                                           username=self.OS_USERNAME,
                                           api_key=self.OS_PASSWORD,
                                           tenant_id=admin_project_id,
                                           auth_url=self.OS_AUTH_URL,
                                           region_name=self.OS_REGION_NAME)
        if None == self.Neutron_client:
           self.Neutron_client = neutronc.Client(NEUTRON_CLIENT_VERSION,
                                                 auth_url=self.OS_AUTH_URL,
                                                 tenant_name=self.OS_TENANT_NAME,
                                                 username=self.OS_USERNAME,
                                                 password=self.OS_PASSWORD
                                                 ) 
        if None == self.Cinder_client:
           self.Cinder_client = cinderc.Client(CINDER_CLIENT_VERSION,
                                               self.OS_USERNAME,
                                               self.OS_PASSWORD,
                                               self.OS_TENANT_NAME,
                                               self.OS_AUTH_URL
                                               )
    """ get nova quota 
        :param project_id : the tenant id or the project id.
    """
    def get_nova_quota(self,project_id):
        print "\nGet nova quota of project : " + project_id
        nova_qs = self.Nova_client.quotas.get(project_id)
        return nova_qs.to_dict()
    
    """ update nova quota
        :param project_id : the tenant id or the project id.
        :param num_instances : the number of instance. 
        :param num_cores : the number of cpu cores
        :param size_ram : the size of RAM , unit: MB
     """
    def update_nova_quota(self,project_id,num_instances,num_cores,size_ram):
        print "update nova quota."
        nova_q_info = { u'instances': num_instances, u'cores': num_cores, u'ram': size_ram}
        nova_qs = self.Nova_client.quotas.update(project_id,instances=nova_q_info['instances'],cores=nova_q_info['cores'],ram=nova_q_info['ram'])
        return nova_qs.to_dict()

    """ get neutron quota 
        :param project_id : the tenant id or the project id.
    """    
    def get_neutron_quota(self,project_id):
        print "\nGet neutron quota of project : " + project_id
        return self.Neutron_client.show_quota(project_id)

    """ update neutron quota
        :param project_id : the tenant id or the project id.
        :param num_security_group : the number of security_group 
        :param num_net : the number of network
        :param num_subnet : the number of subnetwork
        :param num_router :  the number of router
        :param num_floatingip : the number of floatingip
    """
    def update_neutron_quota(self,project_id,num_security_group,num_net,num_subnet,num_router,num_floatingip):
        print "update neutron quota."
        neutron_q_info = {u'quota': { u'security_group': num_security_group, u'network': num_net, u'subnet': num_subnet, u'router': num_router, u'floatingip':num_floatingip }}
        neutron_qs = self.Neutron_client.update_quota(project_id, {'quota':{
                                                            'security_group':neutron_q_info['quota']['security_group'],
                                                            'network':neutron_q_info['quota']['network'],
                                                            'subnet':neutron_q_info['quota']['subnet'],
                                                            'router':neutron_q_info['quota']['router'],
                                                            'floatingip':neutron_q_info['quota']['floatingip']}})
        return neutron_qs     

    """ get cinder quota 
        :param project_id : the tenant id or the project id.
    """   
    def get_cinder_quota(self,project_id):
        print "\nGet cinder quota of project : " + project_id
        return self.Cinder_client.quotas.get(project_id)

    """ update cinder quota
        :param project_id : the tenant id or the project id.
        :param storage_size : the disk storage size.
        :param num_volumes : the number of volumes.
        :param num_snapshots : the number of snapshots.
    """     
    def update_cinder_quota(self,project_id,storage_size,num_volumes,num_snapshots):
        print "update cinder quota."
        cinder_q_info = { u'gigabytes': storage_size, u'volumes': num_volumes, u'snapshots': num_snapshots }
        return self.Cinder_client.quotas.update(project_id,gigabytes=cinder_q_info['gigabytes'],volumes=cinder_q_info['volumes'],snapshots=cinder_q_info['snapshots'])

    """ get project quotas,include nova quota,neutron quota and cinder quota
        :param project_id : the tenant id or the project id.
    """     
    def get_project_quotas(self,project_id):
        nova_quotas = client.get_nova_quota(project_id)
        print "nova Quota:\n" + str(nova_quotas)
#       print '\nNova quota for project '+ project_id 
#       for k in nova_quotas.keys():
#           print ' '+k+': '+ str(nova_quotas[k])       
        neutron_qs = client.get_neutron_quota(project_id) 
        print "neutron quota:\n" + str(neutron_qs)
        cinder_qs = client.get_cinder_quota(project_id)
        print "cinder Quota:\n" + str(cinder_qs._info)

    """
        update project quotas
        :param *args :
        :param *kwargs : keys include project_id,q_info 
    """
    def update_project_quotas(self,*args,**kwargs):
        print "start update project quotas..."
       # print "\nargs:", args
       # print "kwargs:", kwargs
        if not kwargs['project_id'] or None == kwargs['project_id' ]:
            print "Error: params project_id is null or not exits."
        q_info = kwargs['q_info']
        if None == q_info :
            print "Error:quota params q_info is null."
            return 
        if not q_info['instances']:
            q_info['instances'] = 10
        if not q_info['cores']:
            q_info['cores'] = 160
        if not q_info['ram']:
            q_info['ram'] = 327680
        if not q_info['volumes']:
            q_info['volumes'] = 10
        if not q_info['snapshots']:
            q_info['snapshots'] = 10
        if not q_info['gigabytes']:
            q_info['gigabytes'] = 1024
        if not q_info['security_group']:
            q_info['security_group'] = -1 
        if not q_info['floatingip']:
            q_info['floatingip'] = 250
        if not q_info['network']:
            q_info['network'] = 3
        if not q_info['subnet']:
            q_info['subnet'] = 3
        if not q_info['router']:
            q_info['router'] = 2
        self.update_nova_quota(kwargs['project_id'],q_info['instances'],q_info['cores'],q_info['ram'])
        self.update_neutron_quota(kwargs['project_id'],q_info['security_group'],q_info['network'],q_info['subnet'],q_info['router'],q_info['floatingip'])       
        self.update_cinder_quota(kwargs['project_id'],q_info['gigabytes'],q_info['volumes'],q_info['snapshots'])

    def get_config_file_info(self,config_file_dir):
        cf = ConfigParser.ConfigParser()
        cf.read(config_file_dir)
        q_info = {}
        q_info['admin_project_id'] = cf.get("project","admin_project_id")
        #read config file params
        q_info['instances'] = cf.getint("quotas", "instances")
        q_info['cores'] = cf.getint("quotas", "cores")
        q_info['ram'] = cf.getint("quotas","ram")
        q_info['security_group'] = cf.getint("quotas","security_group")
        q_info['network'] = cf.getint("quotas","network")
        q_info['subnet'] = cf.getint("quotas","subnet")
        q_info['router'] = cf.getint("quotas","router")
        q_info['floatingip'] = cf.getint("quotas","floatingip")
        q_info['gigabytes'] = cf.getint("quotas","disk_size")
        q_info['volumes'] = cf.getint("quotas","volumes")
        q_info['snapshots'] = cf.getint("quotas","snapshots")
        return q_info

def main():
    project_id = None
#    config_info = {}
    global client
    try:
        argv =  sys.argv[1:]
        if len(argv) < 1 :
            print "No parameters input, please use --help for help info."
            sys.exit(1)
        if argv[0].startswith('--'):
            option = argv[0][2:]
            if "project-id" == option:
                if len(argv) == 2 :
#                    print "project-id:" + argv[1]
                    project_id = argv[1]
                else:
                    print "the value of project-id is error."
                    sys.exit(1)
            elif "help" == option:
                print """
                    quota-management.py options include:
                    --help : get the help info.
                    --project-id : get the project id or tenant id.
                """
                sys.exit(1)
            else:
                print "Unknown option."
                sys.exit(1)    
        else:
            print "params error."
            sys.exit(1)
        if None == project_id:
            print "param project id is null."
            sys.exit(1)
        auth_url=os.environ['OS_AUTH_URL']
        tenant_name=os.environ['OS_TENANT_NAME']
        username=os.environ['OS_USERNAME']
        password=os.environ['OS_PASSWORD']
        client = Client(auth_url,tenant_name,username,password)
        # read config file 
        current_dir = os.path.abspath(os.path.curdir)
        config_file_name = 'quota-management.config'
        config_file_dir = current_dir + '/' + config_file_name
        config_info = client.get_config_file_info(config_file_dir)
        print "config info is :" + str(config_info)
        client.init_client(config_info['admin_project_id'])
#        client.get_project_quotas(project_id)
        client.update_project_quotas(project_id=project_id,q_info=config_info)

    except Exception as e:
        print("ERROR in main function.details: %s\n" %( e.message,))
        sys.exit(1)
    except KeyboardInterrupt as e:
        print("Shutting down quota management")
        sys.exit(1)
    
if __name__ == "__main__":
    main()
   


