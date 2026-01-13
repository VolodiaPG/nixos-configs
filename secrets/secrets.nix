let
  publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH7eU7+cUxzOuU3lfwKODvOvCVa6PM635CwP66Qv05RT volodia.parol-guarino@proton.mey";
in
{
  "pythong5k.age".publicKeys = [ publicKey ];
  "envvars.age".publicKeys = [ publicKey ];
  "tailscale-authkey.age".publicKeys = [ publicKey ];
  "mail.inria.password.age".publicKeys = [ publicKey ];
  "ssh-remote-builder.age".publicKeys = [ publicKey ];
  "ssh-remote-builder-pub.age".publicKeys = [ publicKey ];
  "rss-password.age".publicKeys = [ publicKey ];
  "samba-user-password.age".publicKeys = [ publicKey ];
  "cachix-token.age".publicKeys = [ publicKey ];
  "fizzy-env.age".publicKeys = [ publicKey ];
}
