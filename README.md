macopen
=======

Open and edit Linux files on your Mac via SSH/OSXFuse/sshfs and OS X 'open' command

To get this to work, install OSXFuse and SSHFS, both available for download from http://osxfuse.github.com/.  Then enable remote login on your Mac and configure your Mac and the remote machines for password-less SSH using ssh-keygen as described at http://www.linuxproblem.org/art_9.html.  Then download the macopen script, install it on the remote machine, and run it from there with the remote filename as a parameter.  There are some options that you can see by running the script with no arguments.

Note that the machines have to be able to route to one another, so no NAT support right now.  I read a little about SSH tunneling/reverse SSH, which might be able to help when your Mac is behind NAT.

There's a little more detail in this [blog post](http://andrewscode.blogspot.com/2012/10/macopen-bash-script-to-open-and-edit.html).
