#!/bin/bash

cat <<EOF >> ~/.ssh/config
Host ${hostname}
    HostName ${hostname}
    User ${user}
    IdentityFile ${identity_file}
    ForwardAgent yes
EOF

chmod 600 ~/.ssh/config
