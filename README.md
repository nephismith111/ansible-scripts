
# Ansible Scripts - for home lab use

---

My goal with this project is to learn how to use ansible. The first few commits do indeed have secrets committed; however, I know how to rotate these and my goal was to start without complete knowledge of how to use ansible while I learn how to use this tool. I recently learned how to use ansible vault, so I will continue to improve this project as I encode the deployment of the tools I like to use.

I have two environments in this project: home, and ansible-lab. 
The idea is to test my setups in the ansible-lab and then to deploy to my home after I've set it up as I like it.


Goals:

- [x] Setup working Elasticsearch cluster (with kibana)
- [ ] Elasticsearch Fleet
- [ ] Setup envoy
- [x] Setup Working Vault Cluster
- [x] Setup working consul Cluster
- [x] Setup Working nomad cluster
- [ ] Setup Backstage
- [ ] Setup working Kafka Cluster
- [ ] Get experience with auto rotating certificates with vault and consul so I can set short timeouts
- [ ] Setup Kong
- [ ] Setup HA Postgres (perhaps with patroni)
- [ ] PKI - setup a nested certificate system and rotate the root ca without breaking everything.
- [ ] Setup blob storage of some kind (maybe minio)

## Frequent Commands
```bash
ansible-playbook -i inventory/ansible-lab/ elasticsearch.yml --limit "ns-elastic-01" --step --ask-become --ask-vault-password
ansible-playbook -i inventory/ansible-lab/ elasticsearch.yml --limit "ns-elastic-01" --ask-become --ask-vault-password
```

