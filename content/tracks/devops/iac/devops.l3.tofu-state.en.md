---
id: devops.l3.tofu-state
lang: en
track: devops
level: 3
stage: 3
module: iac
main_path: true
title: "The state file is how OpenTofu knows which real object is which"
duration_min: 14
skills: [devops.iac.state]
prereqs: [devops.l3.plan-and-apply, k8s.l1.kubectl-and-the-api-server, devops.l1.secrets-vs-config]
related: [k8s.l1.manifests-and-kubectl-apply, k8s.l1.secrets]
vocab: [tofu-state]
example_tag: stage-3
versions_used: [opentofu, opentofu_provider_kind, kind, kubernetes, git]
content_version: 1
status: approved
approved_by: auto
reviewed_at: "2026-10-08T11:41:16+07:00"
---

## Before you start

- [[devops.l3.plan-and-apply]] — you saw a plan compare `main.tf` with "the objects OpenTofu created earlier"; this lesson is the record that comparison reads.
- [[k8s.l1.kubectl-and-the-api-server]] — you saw kubectl reach the API server with credentials from its kubeconfig; OpenTofu keeps the same kind of credential for `donhang-iac`.
- [[devops.l1.secrets-vs-config]] — you saw that `.gitignore` keeps `.env` out of Git because whoever reads a secret gains its power; this lesson adds one more file of that kind.

## The situation

`donhang-iac` has been running since you applied `deploy/tofu/lessons/first-cluster`. A teammate tidying that folder finds a file next to `main.tf` that `git status` never lists: `terraform.tfstate`. It looks like generated output, so they want to delete it. They also want to delete the `resource` block, so that OpenTofu stops managing the cluster while the cluster keeps running for their tests. `main.tf` names the cluster `donhang-iac`, they say, so OpenTofu can always find it again by that name. Is that file really a leftover, and what does OpenTofu use it for?

## Core concepts

- **state (OpenTofu)** — the record OpenTofu writes after each apply, linking every resource address in the configuration to the real object a provider created for it, with the attributes read back from that object; in `first-cluster` it is a plain-text file.
- Attribute — one named value of a resource, such as its `name`, either written in the block or read back from the real object.
- Resource address — the name a plan and the state use for one resource; for a resource in the configuration's own folder, its type and local name joined by a dot, such as `kind_cluster.this`.
- Sensitive value — a value OpenTofu hides in what plan and apply print, showing `(sensitive value)` in its place; a value becomes one when the configuration marks it with `sensitive = true`.
- Stale saved plan — a plan saved with `-out` whose state has changed since it was made, which `tofu apply` therefore refuses.

## How it works

```mermaid
flowchart LR
  F["main.tf: kind_cluster.this"] --> P["tofu plan"]
  S["terraform.tfstate: kind_cluster.this is donhang-iac"] --> P
  P -->|"reads current values"| C["cluster donhang-iac"]
  P --> L["actions: create, update, replace, destroy"]
  L --> A["tofu apply"]
  A -->|"writes after acting"| S
```

In the situation above, `terraform.tfstate` is the state. After each apply, OpenTofu writes it, by default under that name in the configuration's folder; `terraform.tfstate` is simply the default file name OpenTofu uses. For the address `kind_cluster.this` it records which real object the provider created, the kind cluster `donhang-iac`, and the attributes read back from it, such as `client_key`.

A plan starts from the state. It reads the current values of each object recorded there, then compares the result with the files, address by address. An address in both is compared attribute by attribute, which gives an update, a replacement or nothing. An address only in the files is planned for creation. An address only in the state, with nothing in the files about it any more, is planned for destruction: the files no longer want that object, and the state says it exists.

`kubectl apply -f`, as Đơn Hàng uses it, keeps no such record. It sends the objects in the manifests you pass and knows nothing of the ones you no longer pass, so an object whose manifest you delete keeps running.

The name `donhang-iac` in `main.tf` is only an attribute value to OpenTofu; it never searches for an existing object by name. Without the state, every address is only in the files, so the plan creates everything again.

A saved plan holds actions worked out from the state at that moment. If the state has changed since, `tofu apply` refuses the file instead of taking those actions.

## In the Đơn Hàng system

`scripts/devops/tofu-state.sh` runs after `tofu-plan-apply.sh`, in the `first-cluster` folder where `donhang-iac` was applied. It puts every file back when it ends.

```bash file=scripts/devops/tofu-state.sh tag=stage-3 lines=8-28
# lesson: devops.l3.tofu-state
# After apply, the state maps each resource address to the real object and
# the attributes read back from it, in terraform.tfstate next to main.tf.
show tofu state list
echo
# The client key that administers the cluster sits in it as plain text
# (only its first line is printed here).
echo '$ grep -o '"'"'"client_key": *"-----BEGIN [A-Z ]*-----'"'"' terraform.tfstate'
grep -o '"client_key": *"-----BEGIN [A-Z ]*-----' terraform.tfstate
echo

# lesson: devops.l3.tofu-state
# A block removed from the files, still in the state: planned for destruction.
echo "== main.tf without its resource block"
cp main.tf main.tf.orig
trap 'mv main.tf.orig main.tf' EXIT
perl -0pi -e 's/\n# lesson: devops\.l3\.plan-and-apply\n.*//s' main.tf
tofu plan -no-color | grep -e '^  # ' -e '^Plan:'
mv main.tf.orig main.tf
trap - EXIT
echo
```

```text output=true
$ tofu state list
kind_cluster.this

$ grep -o '"client_key": *"-----BEGIN [A-Z ]*-----' terraform.tfstate
"client_key":"-----BEGIN RSA PRIVATE KEY-----

== main.tf without its resource block
  # kind_cluster.this will be destroyed
  # (because kind_cluster.this is not in configuration)
Plan: 0 to add, 0 to change, 1 to destroy.
...
```

`show` prints the command after `$`, then runs it. `tofu state list` prints the addresses the state holds: one, `kind_cluster.this`. The `grep` finds `client_key` written out in the file: the private key of the credential in the cluster's kubeconfig, the one kubectl uses to reach `donhang-iac`. The script prints only its first line on purpose. Anyone who can read `terraform.tfstate` can take that key. No plan line for `client_key` is printed here, so the script does not show whether a plan hides it; the state holds it either way.

`perl` then cuts `main.tf` from the `plan-and-apply` comment to the end, which removes the `resource` block. The plan answers the teammate's second idea: `will be destroyed`, `because kind_cluster.this is not in configuration`.

```bash file=scripts/devops/tofu-state.sh tag=stage-3 lines=30-45
# lesson: devops.l3.tofu-state
# Without its state OpenTofu knows of no cluster: it plans to create one,
# and creating it fails, because a cluster with that name already runs.
echo "== terraform.tfstate moved away"
mv terraform.tfstate state.saved
trap 'mv state.saved terraform.tfstate' EXIT
tofu plan -out=stale.tfplan -no-color | grep -e '^  # ' -e '^Plan:'
tofu apply -auto-approve -no-color 2>&1 | grep -e '^Error' || true
mv state.saved terraform.tfstate
trap - EXIT
echo

# The plan saved without the state no longer fits the state now in place.
echo "== the state is back; apply the plan saved without it"
show tofu apply -no-color stale.tfplan || echo "(exit $?)"
rm -f stale.tfplan
```

```text output=true
...
== terraform.tfstate moved away
  # kind_cluster.this will be created
Plan: 1 to add, 0 to change, 0 to destroy.
Error: node(s) already exist for a cluster with the name "donhang-iac"

== the state is back; apply the plan saved without it
$ tofu apply -no-color stale.tfplan

Error: Saved plan is stale

The given plan file can no longer be applied because the state was changed by
another operation after the plan was created.
(exit 1)
```

With the state moved away, the plan wants to create `kind_cluster.this`, although `donhang-iac` is running. `-auto-approve` makes `tofu apply` act without asking for `yes`, and `2>&1` sends its error text into `grep`, so the `Error` line appears. The creation fails because kind refuses a second cluster with the same name. With the state back, `tofu apply` refuses the plan saved without it: `Saved plan is stale`.

Đơn Hàng's `.gitignore` lists `*.tfstate` and `*.tfstate.*`, with a comment saying state files hold credentials in plain text. The state must not go into Git: anyone who can read the repository could use the credentials in it.

## Seniors often assume…

- **"The state file is just a cache; if I delete it, OpenTofu will find my resources again."** → Actually the state is the only link between `kind_cluster.this` and `donhang-iac`; OpenTofu does not look for existing objects by name, so without the state it plans to create everything again. You notice this when a plan says `will be created` for a cluster that `kind get clusters` already lists, and the apply fails with `node(s) already exist`.
- **"Marking a value as sensitive keeps it out of the state file."** → Actually `sensitive` only changes what plan and apply print; the state still records the value; `first-cluster`'s state, the only one this lesson opens, shows it plainly. You notice this when a value you marked `sensitive` shows as `(sensitive value)` in a plan, yet `grep` finds its value in the state file.
- **"Removing a block from the files only makes OpenTofu stop managing that object; the object itself stays."** → Actually the address stays in the state, so the next plan destroys the object, and `tofu apply` then deletes it. Removing the block is not the way to keep the object running; this lesson only shows what not to do. When you mean to keep an object, read the plan for `will be destroyed` before typing `yes`. You notice this when a clean-up commit's plan ends with `1 to destroy`.

## Try it (3 minutes)

`donhang-iac` must exist: if `kind get clusters` does not list it, run `scripts/devops/tofu-first-cluster.sh` first.

1. Run `scripts/devops/tofu-state.sh` from the repository root; it moves into `first-cluster` by itself.
2. Run `git check-ignore -v deploy/tofu/lessons/first-cluster/terraform.tfstate` from the repository root.
3. Run `kind get clusters`.

Expected result: the script prints the lines shown above and ends with `(exit 1)`. `git check-ignore -v` prints `.gitignore:27:*.tfstate` followed by the file's path: line 27 of `.gitignore` is the pattern that keeps the state out of Git. `kind get clusters` still lists `donhang-iac`, because the destroy was only planned, the creation failed and the stale plan was refused.

## Connections

- [[k8s.l1.manifests-and-kubectl-apply]] — the opposite way to declare objects: `kubectl apply`, as Đơn Hàng uses it (without `--prune`), keeps no record of what it created, so deleting a manifest deletes nothing, while removing a block from `main.tf` plans a destroy.
- [[k8s.l1.secrets]] — the same weakness one layer down: a Secret is readable by whoever can read it, and the state is readable by whoever can read the file.
- [[devops.l3.remote-state-and-locking]] — the problem this lesson leaves open: a state on one laptop cannot be shared, and that lesson shows where Đơn Hàng keeps its environments' state.
- [[devops.l3.tofu-modules]] — the next lesson, where a resource's address changes and the state must follow it.

## Five-line summary

1. The state file is OpenTofu's only record of which real object each resource address, such as `kind_cluster.this`, stands for.
2. A plan proposes destroying addresses found only in the state and creating addresses found only in the files.
3. Without its state, OpenTofu plans to create everything again; it never finds existing objects by name.
4. `first-cluster`'s state holds attributes in plain text, `client_key` included, so `.gitignore` keeps `*.tfstate` out of Git.
5. `tofu apply` refuses a saved plan once the state has changed since the plan was made.
