dbPass = "swimming3";
try {

   shell.connect('root@node01:3306', dbPass);
   cluster = dba.createCluster("otuscluster");
   cluster.addInstance({user: "root", host: "node02", password: dbPass});
   cluster.addInstance({user: "root", host: "node03", password: dbPass});

} catch(e) {
   print('\nThe InnoDB cluster could not be created.\n\nError: ' + e.message + '\n');
}