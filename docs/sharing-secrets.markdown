# Secure sharing of secrets

Each environment directory has a subdirectory `secret-files`, to hold files that have secret information.
For example, you can place SSH private keys, SSL private keys, and Docker credentials in the `secret-files` directory.
The `secret-files` directory is mentioned in the `.gitignore` file, so your secret files will never be included in a git commit or pushed to a remote git repository such as GitHub.

So, how do you share secret files among team members? If you create new secret files, and you want another team member to work with them, 
you have to make them available by some means outside of the Git repository. This interrupts your Git workflow and adds a path for mistakes.

This repository supports encrypting your secret files, committing and pushing the encrypted files via Git, and decrypting them back into their original form.
The only secret that needs to be shared is a single "vault password" per environment.

To use this feature, the original creator of the environment follows these steps:

1. Create your environment as described in the README. This will automatically add a new SSH keypair to your environment, and create a random encryption password saved in `vault-password`.
2. Add additional secret files to the `secret-files` directory, as appropriate. These can be binary or text, but should be relatively small files.
3. Run `ansible-playbook ../encrypt-secret-files.yaml`.
4. Commit the changes using Git, and push the changes to a shared repository such as Github. 

The team member who wishes to use the environment follows these steps:

1. Ask the creator for the environment's `vault-password` file contents. It will be a random string of 20 or so letters. Create your own `vault-password` file in the environment directory. 
2. Clone and/or pull the shared repository locally, so that it's up-to-date.
3. `cd <env>` where `<env>` is the name of your environment.
4. `ansible-playbook ../decrypt-secret-files.yaml`.
5. You may wish to copy the SSH keys for your environment to your `~/.ssh` directory.

If you need to add or change secret files, make your changes in your `secret-files` directory, then run the `encrypt-secret-files.yaml` playbook and commit/push.
 
Then, other team members can pull your changes and run the `decrypt-secret-files` playbook to update their local secret files.