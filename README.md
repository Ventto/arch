Arch Setup
==========

*"Install the Arch Linux distribution on a computer in UEFI mode and
encrypt the entire system (LUKS upper LVM)"*

# Requirements

* Arch Linux ISO
* Internet connection
* *bash* and *unzip* packages

# Run

* Boot the Arch Linux's live CD

* Run the script:

```
$ ./setup.sh
```

* Reboot and log in

* Run the script as user:

```
$ ./user-setup.sh && exit
```

# See Also

* [PavelKogan's blog](https://www.pavelkogan.com/2014/05/23/luks-full-disk-encryption/)
* Github Arch setups, [#1](https://github.com/jmutai/dotfiles/blob/6245636d31f1e4999006815c809053fa23cdcb9e/arch-installation-cheatsheet.md),
[#2](https://github.com/grez911/grez911.github.io/blob/9bddef1dd083c15b4ab7923ad9b1a4cf3e835f91/cryptoarch.html)
