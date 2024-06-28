# This is a script for backup and restore Omni etcd

## Generate GPG Keypair

```bash
# Generate GPG Keypair
gpg --gen-key
# Real name: OmniBackup
# Email address: info@djls.io
# Passphrase: Generate it from 1Password and keep it safe.

# Export the public key and private key
gpg --armor --export OmniBackup > bk.pub
gpg --export-secret-keys --armor OmniBackup > bk.key

# Remove the keys from the keyring
gpg --delete-secret-and-public-keys OmniBackup

# Remove the private key from the backup machine and only keep the public one.
```
