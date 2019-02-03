Arch Setup
==========

*"Install the Arch Linux distribution on a computer in UEFI mode and
encrypt the entire system"*

# Requirements

* Arch Linux ISO (+ bash)
* Internet connection

# Run

* Boot the livecd

* Download setup scripts:

```
$ pacman -Sy unzip
$ wget https://codeload.github.com/Ventto/arch/zip/master -O setup.zip
$ unzip -j setup.zip
$ chmod +x *.sh
```

* Run the script:

```
$ ./setup.sh
```

# See Also

* [PavelKogan's blog](https://www.pavelkogan.com/2014/05/23/luks-full-disk-encryption/)
* Github Arch setups, [#1](https://github.com/jmutai/dotfiles/blob/6245636d31f1e4999006815c809053fa23cdcb9e/arch-installation-cheatsheet.md),
[#2](https://github.com/grez911/grez911.github.io/blob/9bddef1dd083c15b4ab7923ad9b1a4cf3e835f91/cryptoarch.html)
