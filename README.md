# JTSDRAM

Checks the sanity of the SDRAM module on MiST and MiSTer systems

# Compilation

Add the **JTFRAME** git submodule following the standard procedure. Read the
README file in it to learn about how to compile JTFRAME projects in general.

In summary, you will need to be doing this from a linux workstation and from
the project root folder type:

```
. setprj.sh
jtcore sdram
```

That is all

# Usage

The FPGA will constantly fill the first 8MB of each memory bank with pseudorandom
data at a fast pace, but without bank interleaving. Then it will read it back
at full speed; that means 96MB/s at 48MHz operation. It will stop during vertical
blanking to issue autorefresh commands. Each memory filling is checked four times.
Then a new round begins.

If a problem occurs, the screen will turn red, the LED will blink and a high
pitch tone will replace the normal one. If only part of the screen turns red,
it means that the problem only occured in one bank.

# Simulation

Use the macro **ONEBANK** to simulate only with a single bank. This speeds up
simulation.

# Phase Invertion

Phase inversion of the SDRAM clock is done in MiSTer by using the altddio_out primitive.
This method does not seem to be so different from using phase shifting at the PLL.

SDRAM clock path delay examples:

Clock | DDIO/PLL | Min | Max  | Delta
------|----------|-----|------|-------
48    |  DDIO    | 6.2 | 11.6 |  5.4
48    |  PLL     | 6.8 | 12.9 |  6.1
96    |  DDIO    | 4.2 |  8.5 |  4.3

Clock in MHz, time values in ns.

I don't think instantiating a DDIO cell changes the clock path delay. Quartus seems
to promote the PLL output to a global clock net anyway, so there is no reason why
the delay should be different.

On top of the delay, the PLL will add a given precise phase shift, and the DDIO
will add a fixed 180º shift. In practice, it is not possible to control the phase
of the SDRAM clock using either method. Feeding back the delay to the PLL is the
only way of doing it and that seems to require an extra pin of the FPGA. The pin
must be left unconnected to the PCB as well so it doesn't get loaded.

At the end, it is the synthesis tool that checks that SDRAM I/O constraints are
met. Sometimes the extra 180º provided by DDIO may provide better STA results,
on other occasions, it will a given phase shift produced at the PLL.

# Support

The *jotego* nickname had already been used by other people so on some networks
you will find me as *topapate*.

Contact via:
* https://twitter.com/topapate
* https://github.com/discord

You can show your appreciation through
* Patreon: https://patreon.com/topapate
* Paypal: https://paypal.me/topapate

