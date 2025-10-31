hosts


```bash
# bootstrap host keys
step ca certificate host.domain.com host.crt host.key
step ssh certificate --insecure --no-password --host --x5c-cert host.crt --x5c-key host.key host.domain.com internal_key

# imperative sshd config
step ssh config --host --set Key=ssh_host_step_key --set Certificate=ssh_host_step_key-cert.pub
```


clients

```bash
# imperative bootstrap
step ca bootstrap --ca-url="https://certs.nortonweb.org" --fingerprint=8dabe6ef46619bbc1c34b70ba2cbdd79e8f8e15c48aa68dfc6a5e109920db49f

# imperative trust CA signed hosts
step ssh config

# admin request arbitrary provisioners oauth\
step ssh login --principal caleb --principal root --principal chnorton --provisioner CalebWeb
```