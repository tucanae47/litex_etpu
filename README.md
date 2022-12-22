# Replicate etpu on radiona ULX3S 

VexriscV using Litex to test skywater 130 etpu from https://github.com/tucanae47/etpu

# Setup
```
pyenv virtualenv litex_env
pyenv activate litex_env
wget https://raw.githubusercontent.com/enjoy-digital/litex/master/litex_setup.py
chmod +x litex_setup.py
./litex_setup.py --init --install
pip3 install meson ninja
./litex_setup.py --gcc=riscv
```


# Serial access to the softcore 
litex_term --speed 9600 /dev/ttyUSB0



# Important links:
Most of the work is based on projects listed here
https://github.com/betrusted-io
https://github.com/semify-eda/waveform-generator
https://github.com/BrunoLevy/learn-fpga
https://github.com/efabless/caravel_mgmt_soc_litex
