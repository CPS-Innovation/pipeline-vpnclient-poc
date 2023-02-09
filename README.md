# Demo of azure vnet and VPN client that can be used by humans and also devops pipelines


## Initial terraform apply
```bash
terraform apply --auto-approve
```
The vnet gateway takes about 40mins to start up, so go make some coffee.

It will fail eventually because you're not connected to the vpn with routing or access to the storage account (thats a good thing, proves it works)

## Get the VPN client config, and connect to the VPN
```bash
curl -o client.zip $(az network vnet-gateway vpn-client generate -n gateway -g example-resources | tr -d '"')
unzip client.zip -d client
CLIENTCERTIFICATE=$(cat cnsCert.pem) PRIVATEKEY=$(cat cnsKey.pem) envsubst < client/OpenVPN/vpnconfig.ovpn > vpnconfig.ovpn
rm -r client.zip client
sudo openvpn vpnconfig.ovpn&
```

## Terraform apply again
```bash
terraform apply --auto-approve
```
This should succeed now

## Prove everything works:

```bash
# these should all return 10.0.2.x addresses when on vpn
nslookup cns-examplekeyvault.vault.azure.net
nslookup cnsdemoapp.azurewebsites.net
nslookup cnsstorageaccounttest.blob.core.windows.net
```

```bash
# should fail without being connected to vpn
az keyvault secret list --vault-name cns-examplekeyvault
curl https://cnsdemoapp.azurewebsites.net/
az storage blob download --container-name content --account-name cnsstorageaccounttest --name helloworld
```

Disconnect from the VPN, try the above again.