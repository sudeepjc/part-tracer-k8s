# part-tracer-k8s

Hyperledger Fabric 2.0.1 based part tracer project to track parts runs in the minikube's kubernetes setup

Capabitities:

1. Two Organization network and the Orderer
2. Chaincode can add a part, query a part and sell a part to another organization
3. Unit Test for the same (broken due to new changes)
4. Added a few query related chanincode to query range of keys, with and without pagination, getting history of an asset and support for rich queries
5. With Fabric CA
6. With nodejs sdk and REST apis related to chaincode transactional queires and invokes
7. With nodejs sdk and REST apis related to chaincode query, peer queries
8. With nodejs sdk scripts related to channel creation, joining peer and updating the anchor peer
9. Added ingress for routing apis
10. Added logspec, operations, metrics apis and enabled them on the peers and orderers
11. Added prometheus.yaml file for getting metrics from hyperledger network

Instructions:

1. Add the bin folder to the path
2. cd generalOrgApp
3. run command: npm install
4. cd airbusOrgApp
5. run command: npm install
6. import the 'part-tracer-apis.postman_collection.json' file into postman for running queries. The ip address in the saved collection need to be updated to your corresponding minikube ip address
7. The folder inside k8s has the commands to start the network as a minikube project

