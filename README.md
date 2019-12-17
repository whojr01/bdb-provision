# bdb-provision
Provisions virtual machines based on the description entered in the VM_Machine.json file.

The current initial version supports CentOS/7 as the provisioned OS.

The provisioned machine includes a service that updates the ip-address for all virutal machines as a systemD service.

The disk provisioning script AddDockerDisk.sh is still under development.

Below is the Youtube episodes recorded for the development of the provisioning system.

## Boston Devops Bill Episodes

<dl>
    <dt><a href="https://youtu.be/XN5QoDrZJok">Episode 1</a></dt>
    <dd>
        This channel builds a hybrid development/operations framework within a virtual environment with targeted deployments to AWS.
    </dd>
</dl>

<dl>
    <dt><a href="https://youtu.be/GvkckRCHWN8">Episode 2</a></dt>
    <dd>
        In this episode of Boston DevOps Bill we begin our journey to create the provisioning utility using Vagrant and VirtualBox.<br><br>I provide a brief install instructions as well as URL's to each component. Once you have completed the installs we'll create a test Vagrantfile and spin up a Virtual environment.
    </dd>
</dl>

<dl>
    <dt><a href="https://youtu.be/FKQeD2JUqE8">Episode 3</a></dt>
    <dd>
        The work continues on the provisioning utility and in this installment we create the JSON file that we will use to describe each node.<br><br>Of course I let you with a real cliff hanger [sorry no spoiler alerts], but I can assure you that nobody got hurt while filming this episode.
    </dd>
</dl>

<dl>
    <dt><a href="https://youtu.be/sjV4JdAw-Vs">Episode 4</a></dt>
    <dd>
        The saga of provisioning continues as we forge ahead into uncharted JSON keys to join our Vagrantfile with our VM_Machine.json file.<br><br>We'll learn about loops as we build loops to traverse through our defined machines and build loops within loops to handle shares and ports. All in all this is a pound the keys episode!<br><br>Of course I will leave you (not yet) with a real clif hanger [sorry no spoiler alerts], but I can assure you that I was not hurt by the Supervisor today (Yes, I fed her before I started recording).
    </dd>
</dl>

<dl>
    <dt><a href="https://youtu.be/X8iC5Q5lKLg">Episode 5</a></dt>
    <dd>
        This episode focuses on testing our Vagrantfile & JSON file together to define VM's as described in the JSON file.<br><br>Today we embark on a journey to create a mechanism to sync IP Addresses across all VM Machines regardless of whether they are defined or not. Please note this is not for the faint of heart as there will be nashing of teeth, lots of rum, and a yo ho ho!<br><br>Another words we're gonna bang some keys and have lots of fun! As usual I will leave you with a cliff hanger!
    </dd>
<dl>

<dl>
    <dt><a href="https://youtu.be/Ay2uxX-PlLg">Episode 6</a></dt>
    <dd>
        Today we embark on a journey to create a mechanism to sync IP Addresses across all VM Machines regardless of whether they are defined or not. Please note this is not for the faint of heart as there will be nashing of teeth, lots of rum, and a yo ho ho!<br><br>Another words we're gonna bang some keys and have lots of fun! As usual I will leave you with a cliff hanger!
    </dd>
</dl>

<dl>
    <dt><a href="https://youtu.be/olOagT1yua4">Episode 7</a></dt>
    <dd>In our last session we ended with the discovery of a severity 1 defect. In this episode we'll take an in depth look at this issue.<br><br>Well, that's great. No contact with the Vagrantfile, a xenomorph may be involved!<br><br>What do you mean *they* cut the power? How could they cut the power, man?<br><br>A xenomorph can do anything if left unchecked.<br><br>That's it, man. Game over, man. Game over!<br><br>Only the brave should continue as we dip into the primordial bits in an attempt resolve the issue. Be warned, Ripply couldn't make it. Only the shadow knows if we can get past this.
    </dd>
</dl>

<dl>
    <dt><a href="https://youtu.be/liwdI4zCsHo">Episode 8</a></dt>
    <dd>
        After barely surviving the encounter with the xenomorph we forged on to face new challenges, as we enter the monsters territory of SystemD, with support from Timer and Service Unit who graciously agreed to help.<br><br>The arduous climb up took longer than anticipated, but even with noticiable degradation of visuals towards the end, we pressed on!<br><br>Kindly please be advised, due to recent budget custs, we're unable to provide snacks, during this exciting episode.
    </dd>	
</dl>

<dl>
    <dt><a href="https://youtu.be/7xYD9h8kIUI">Episode 9</a></dt>
    <dd>
        Well we're forced by the cleaning crew to make this episode a bit shorter so there is no reason to bring snacks. Thank you to those who cleaned up after themselves.<br><br> In this episode we'll be deploying to parts known as we complete the IP Sync component of our provisioning system. Unfortunately due to the large amount of trash left over from the last episode, future (next) episode, will be creating defining storage facilities.
    </dd>
</dl>

<dl>
    <dt><a href="https://youtu.be/uvGcZstc1Ag">Episode 10</a></dt>
    <dd>
        This episode we begin creating the provisioning storage script that will create the three types of drives (Standard storage, Logical Volumes, and Thin Provisioned disks) by the Storage system.<br><br>We will clean up the code to our IP Sync system removing the tempfile we created, log entry, and adding ourselves to the VirtualBox group so we don't need to be root to access the admin share.
    </dd>	
</dl>

<dl>
    <dt><a href="https://youtu.be/BWY7RyBt7tE">Episode 11</a></dt>
        <dd>
            In this episode I highlight Zenoss, Zenoss provides infrasructure management, at any scale as software as a service. Take a look its really cool stuff!<br><br>Afterwards we continue to build out our storage script by developing a better test for drives not in use, adding additional checks for our tuple, and adding the skeleton functions to create the storage drives.
        </dd>
</dl>

<dl>
    <dt><a href="https://youtu.be/CD2wDDe2S4Y">Episode 12</a></dt>
        <dd>
            This episode we define the functions drive (For partitioning and formating) a standard drive and lv (For creating a logcial volume). We saved the creation of the thin volume drive routine for the next episode.
        </dd>
</dl>
