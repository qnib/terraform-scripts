# Slurmn Cluster in aws
Inspired by [Automating AWS infrastructure with Terraform](https://simonfredsted.com/1459).

## TODO

- [ ] Autoconfigure cluster, so that terraform informs `/etc/slurm-llnl/slurm.conf` about the nodes available. Maybe an ansible script afterwards.

```bash
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
