//Input needed is PLRU bits (It is passed by REF) AND int way
//Returns NOTHING
// Call the function like this UpdatePLRU(cache_mem[0].plru_bits, way);
`include "pkg_line.sv"
import line::*;

function automatic void UpdatePLRU(ref logic [N_WAY-2:0] plru_bits, int way);

automatic int PLRU_Tree = 0;  // Start at the root of the PLRU tree
automatic int i;

// Traverse the tree and update PLRU bits
for (i = $clog2(N_WAY)-1; i >= 0; i--) 
begin
   // Update the current PLRU bit based on the `w` value
   plru_bits[PLRU_Tree] = (way & (1 << i)) ? 1'b1 : 1'b0;
   // Calculate the next index in the PLRU tree
   PLRU_Tree = (PLRU_Tree << 1) + (1 << (way & (1 << i)));
end

endfunction

//Input needed is PLRU bits (It is just a copy not a REF)
//Returns int Way to be Evicted
function automatic int VictimPLRU(input logic [N_WAY-2:0] plru_bits);

   automatic int b = 0;  // Index for the PLRU 
   automatic int Victim_Way = 0;  // Victim way
   automatic int i;

    // Traverse the PLRU tree to find the victim way
    for (i = 0; i < $clog2(N_WAY); i++) begin
        // Update the victim way based on the current PLRU bit
        Victim_Way = (Victim_Way << 1) | ~plru_bits[b];

        // Compute the next node in the PLRU tree
        b = (b << 1) + (1 << ~plru_bits[b]);
    end

    return Victim_Way;  // Return the victim way

endfunction


