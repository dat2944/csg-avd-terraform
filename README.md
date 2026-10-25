# CSG AVD Terraform

Automation for the Contractor Secure Gateway (Entra DS + Azure Files + FSLogix + pooled AVD).
Follow the "CSG AVD Configuration Guide: Terraform + Azure DevOps" phase by phase.

| Stage | Folder | Build guide sections | Guide phase |
|---|---|---|---|
| 1 | `stage1-foundation` | 3, 4, 5: RG, VNet, NSGs, groups, Entra DS, VNet DNS | 6 |
| 2 | `stage2-storage-avd` | 6, 8, 9: storage, Entra DS auth, share RBAC, private endpoint, host pool, app group, workspace | 8 |
| 3 | `stage3-hosts` | 6, 7, 13: session hosts, CSG-MGMT-0, domain join, AVD agent, RSAT | 9 |
| 4 | `stage4-config` | 10, 14-17: NTFS ACLs, OUs, GPOs (run on CSG-MGMT-0) | 10 |

- `clients/<client>/client.tfvars`: every value for one client. `backend.hcl`: where its state lives.
- `pipelines/csg-deploy.yml`: run manually with client, stage, and plan or apply.
- Each stage has its own state (`<client>/<stage>.tfstate`) and reads earlier stages via `terraform_remote_state`.

## Running a stage locally (optional)

```bash
az login --tenant <tenant-id>
cd stage1-foundation
terraform init -backend-config=../clients/lab/backend.hcl -backend-config="key=lab/stage1-foundation.tfstate"
terraform plan -var-file=../clients/lab/client.tfvars
# Stages 3-4 also need: export TF_VAR_domain_join_password='...'
```

Status: syntax-checked only; not yet run against Azure. See the guide's Appendix C.
