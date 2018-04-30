DST OS Rsync Project
====================

This project provides the Jenkins job framework for updating the OS stored
in the DST local Artifacts repository with rpm packages from the OS Distro
download websites.

CentOS 
------

The current OS release for CentOS is 7.4 but will need to be tracked as
new releases are made available

EPEL
----

The EPEL (Extra Packages for Enterprise Linux) is also expected to be updated
by this synchronization job.

SuSE
----

The SuSE Linux distro is expected to be added for Shasta by 2018 Q3. It is
expected to have the kernel source patched, so we will need to insure that
kernel source rpms are also synchronized when the job expands. SLES 15 or
SLES 12 SP3 are the baselines we can expect to use.
