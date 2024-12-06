`include "pkg_line.sv"
//`include"Func.sv"
import line::*;

module tb;

set_st cache_mem[12];
int VictimeWay = 0;
initial begin
cache_mem[0].plru_bits = '0;  // Set all bits to 0 initially

/*Test Case 
First access W0 to W15 continuously
Access W0 to W11
Access W13 to W15
So, Least Recently will be W12, but as we are using PLRU it will come W0

for(int i = 0; i <16;i++)
begin
UpdatePLRU(cache_mem[0].plru_bits, i);
#2;
end
for( int i = 0; i <12;i++)
begin
UpdatePLRU(cache_mem[0].plru_bits, i);
#2;
end

for(int i = 13; i <16;i++)
begin
UpdatePLRU(cache_mem[0].plru_bits, i);
#2;
end
*/

for( int i = 0; i <8;i++)
begin
automatic int a = $urandom_range(0,14); 
UpdatePLRU(cache_mem[0].plru_bits, a);
end

for(int i = 0; i<16; i++)
begin
$display("PLRUbits[%d] = %d", i ,cache_mem[0].plru_bits[i]);
end

VictimeWay = VictimPLRU(cache_mem[0].plru_bits);

$display("\n Way to be Evicted is = %d",VictimeWay);
end
endmodule


function automatic void UpdatePLRU(ref logic [N_WAY-2:0] plru_bits, int way);

bit [3:0]w = way;
int PLRU_Tree;  // Start at the root of the PLRU tree
int i;

$display("Updating for Way: %d \n\n",way); 

// Check for validity of `way`
if (way < 0 || way >= N_WAY) begin
  $fatal("Error: Invalid `way` value (%0d). `way` must be in the range [0, %0d).", way, N_WAY);
        return; // Exit the function if `way` is invalid
end

// Traverse the tree and update PLRU bits
for (i = $clog2(N_WAY)-1; i >= 0; i--) 
begin
   // Update the current PLRU bit based on the `w` value
   plru_bits[PLRU_Tree] = (way & (1 << i)) ? 1'b1 : 1'b0;
   $display("PLRU BitUpdated PLRU[%d] = %b \n", PLRU_Tree, plru_bits[PLRU_Tree]);
   // Calculate the next index in the PLRU tree
   PLRU_Tree = (PLRU_Tree << 1) + ((way & (1 << i)) ? 2'b10 : 2'b01);
   //$display("Next PLRU Tree bit will be %d \n",PLRU_Tree); 
end
/*
for(int i = 0; i <16;i++)
begin
//$display("The array is PLRU[%d] = %d ", i, plru_bits[i] );
$display("PLRU BitUpdated PLRU[%d] = %b \n", i, plru_bits[i]);
end
*/
endfunction

//Input needed is PLRU bits (It is just a copy not a REF)
//Returns int Way to be Evicted
function automatic int VictimPLRU(input logic [N_WAY-2:0] plru_bits);

   int b = 0;  // Index for the PLRU 
   bit [3:0] Victim_Way = 0;  // Victim way
   int i;

    // Traverse the PLRU tree to find the victim way
    for (i = 0; i < $clog2(N_WAY); i++) begin
        // Update the victim way based on the current PLRU bit
        Victim_Way = (Victim_Way << 1) |  bit'(~plru_bits[b]);
	$display("VictimWay = %b \n",Victim_Way);
        // Compute the next node in the PLRU tree
        b = (b << 1) + (1 << bit'(~plru_bits[b]));
        $display("Next Bit = %b \n", b);
    end

    return Victim_Way;  // Return the victim way

endfunction


