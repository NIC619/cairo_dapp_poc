## StarkWare Cairo lang practice

### Setup Cairo
Ref: [Cairo doc - Setting up the environment](https://www.cairo-lang.org/docs/quickstart.html)

- install python3.7 (using virtual env or not)
- install prerequesite libraries: `sudo apt install -y libgmp3-dev`(ubuntu) or `brew install gmp`(mac)
- install python packages: `pip3 install ecdsa fastecdsa sympy`
    - **NOTE**: Cairo was tested with python3.7. To make it work with python3.6, you will have to install contextvars: `pip3 install contextvars`
- download [Cairo python package](https://github.com/starkware-libs/cairo-lang/releases/tag/v0.2.0) and install via `pip3 install cairo-lang-0.2.0.zip`

### Setup Hardhat
Ref: [Install Hardhat](https://hardhat.org/getting-started/#installation)

### Compile Cairo and run
See [compile and run](compile_and_run.md)