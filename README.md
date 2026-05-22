# GWO-FOPSS
GWO-FOPSS: A Robust Fractional-Order Power System Stabilizer  Controller Optimized via Grey Wolf Optimizer 



1. [Amal Ibrahim Nasser] - (Lead Developer & Corresponding Author).
2. Wafaa Saeed2-             co-Author
3. Layth AL-Bahrani    -     co-Author
4. NoorAldeen.R.Hamza  -     co-Author

**Description:**
This package implements and compares three Power System Stabilizer (PSS) designs for a Single-Machine Infinite-Bus (SMIB) system with a salient-pole hydroelectric generator (32 poles):

•	NOPSS— the system without pss
•	CPSS — Conventional PSS with fixed integer-order lead-lag structure
•	GWO-PSS — Integer-order PSS with parameters tuned by the Grey Wolf Optimizer
•	GWO-FOPSS — Fractional-Order PSS with parameters tuned by the Grey Wolf Optimizer (proposed method)

The optimizer minimizes the Integral of Time-weighted Absolute Error (ITAE) of the rotor speed deviation following a transient disturbance, ensuring robust damping of low-frequency oscillations.



