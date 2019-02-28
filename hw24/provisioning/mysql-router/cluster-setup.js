print('MySQL InnoDB cluster set up\n');
print('==================================\n');
print('Setting up a MySQL InnoDB cluster with 3 MySQL Server instances.\n');
print('The instances will be installed on nodes: node01, node02, node03.\n');

var dbPass = "convoy-Punk0";
print(dbPass);

try {
   print('Setting up InnoDB cluster...\n');
   shell.connect('cadmin@node01:3306', dbPass);
   var cluster = dba.createCluster("otuscluster");
   print('Adding instances to the cluster.');
   cluster.addInstance({user: "cadmin", host: "node02", port: 3306, password: dbPass});
   print('.');
   cluster.addInstance({user: "cadmin", host: "node03", port: 3306, password: dbPass});
   print('.\nInstances successfully added to the cluster.');

   print('\nInnoDB cluster deployed successfully.\n');
} catch(e) {
   print('\nThe InnoDB cluster could not be created.\n\nError: ' +
   + e.message + '\n');
}