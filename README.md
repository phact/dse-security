# dse-security

Make the file executable:
`sudo chmod +x client-to-node.sh`

Run `client-to-node.sh` to set up client to node encryption. This will guide you through setting up local keystore and truststores, editing config, and testing cqlsh --ssl.

###TODO:
`node-to-node.sh` should configure truststores to include all the node's public keys and enable node to node encryption in cassandra.yaml.

`spark-node-to-node.sh` should configure truststores to include all the node's public keys and enable spark ssl both in dse.yaml and in spark-defaults.conf.
