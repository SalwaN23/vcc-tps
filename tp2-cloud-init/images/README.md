# images/

Les templates de VM (`ubuntu-template-v1.qcow2`) se trouvent dans
`/var/lib/libvirt/images/` et ne sont pas versionnes : ils pesent environ 5 Go chacun.
`scripts/deploy.sh` les copie vers un disque propre a chaque VM.
