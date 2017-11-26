# Slurm Cluster in aws
Inspired by [Automating AWS infrastructure with Terraform](https://simonfredsted.com/1459).

## TODO

- [ ] Autoconfigure cluster, so that terraform informs `/etc/slurm-llnl/slurm.conf` about the nodes available. Maybe an ansible script afterwards.

## Build images

For this to work, you need to build the images from [qnib/packer-files](https://github.com/qnib/packer-files).

```bash
$ cd aws-u16-docker/
aws-u16-docker $ packer build packer.json
*snip*
```
Whatever `ami-name` came out from that goes into the next two.

```bash
$ cd aws-u16-gpu/
aws-u16-gpu $ packer build -var 'ami_name=aws-docker-nvidia' -var 'source_ami=ami-<id>' packer.json
*snip*
$ cd ../aws-u16-slurm/
aws-u16-slurm $ packer build -var 'ami_name=aws-docker-slurm' -var 'source_ami=ami-<id>' packer.json
```

And use the output of `aws-docker-nvidia` to build `aws-docker-nvidia-slurm`.

*TODO*: [ ] Build `nvidia` from `slurm` to skip one step.

```bash
$ cd aws-u16-slurm/
aws-u16-slurm $ packer build -var 'ami_name=aws-docker-nvidia-slurm' -var 'source_ami=ami-<id>' packer.json
*snip*
```

## Deploy

First, generate a keypair on your workstation.

```bash
$ ssh-keygen -f ${HOME}/.ssh/terraform_aws  -P ""
Generating public/private rsa key pair.
```

Afterwards plan the terraform script.

```bash
$ terraform plan
*snip*
Plan: 1 to add, 1 to change, 1 to destroy.
$
```

If that does not show an error, go ahead and start the cluster.

```bash
$ terraform apply
```


## Submit jobs

```bash
$ ssh -i ~/.ssh/terraform_aws -l ubuntu ec2-xx.compute-1.amazonaws.com
ubuntu@ip-xx:~$ sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
all          up   infinite      2   idle ip-xx,ip-yy
gpu*         up   infinite      1   idle ip-yy
ubuntu@ip-xx:~$ for x in {1..3};do sbatch --partition=gpu job-gpu.sh;done
Submitted batch job 2
Submitted batch job 3
Submitted batch job 4
ubuntu@ip-xx:~$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                 4       gpu nvidia-s   ubuntu PD       0:00      1 (Resources)
                 3       gpu nvidia-s   ubuntu PD       0:00      1 (Priority)
                 2       gpu nvidia-s   ubuntu  R       0:03      1 ip-yy
ubuntu@ip-xx:~$ squeue
JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
ubuntu@ip-xx:~$ cat slurm-2.out
> Pull container image: docker pull nvidia/cuda
>> Create container: docker create nvidia/cuda nvidia-smi -L
>> Start container
8622d09f7b0c2a23d478a8cfc68e7ee8f050bc47f900cae7a33f17cd365ef2ba
>> Wait for container to exit
0
>> Show log of container
GPU 0: Tesla K80 (UUID: GPU-62d1dccb-8f6d-4a54-6522-1fe1f293596a)
```
