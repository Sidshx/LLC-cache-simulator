`include "pkg_line.sv"

package pkg_plru;
import pkg_line::*;

	function automatic void UpdatePLRU(ref logic [N_WAY-2:0] plru_bits, input int way);
	
	bit [$clog2(N_WAY):0]w = way;
	int PLRU_Tree;  // Start at the root of the PLRU tree
	int i;
	`ifdef  DEBUG
	$display("Updating for Way: %d ",way); 
	`endif
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
`ifdef DEBUG  
$display("PLRU BitUpdated PLRU[%d] = %b", PLRU_Tree, plru_bits[PLRU_Tree]);
`endif	
   // Calculate the next index in the PLRU tree
	   PLRU_Tree = (PLRU_Tree << 1) + ((way & (1 << i)) ? 2'b10 : 2'b01);
	   //$display("Next PLRU Tree bit will be %d \n",PLRU_Tree); 
	end
	endfunction

	function automatic int VictimPLRU(
	    input bit [N_WAY-2:0] plru_bits, 
	    ref line_st ways[N_WAY]
	);
	
	    int b = 0;  // Index for the PLRU 
	    bit [3:0] Victim_Way = 0;  // Victim way
	    int i;
	    
	    for (i = 0; i < N_WAY; i++) begin
	        if (ways[i].mesi == I) begin
		`ifdef DEBUG
	            $display("Found Invalid MESI state in Way: %0d", i);
		`endif
	            Victim_Way = i;
	            return Victim_Way; // Return the index of the invalid line
	        end
	    end

	    // Traverse the PLRU tree to find the victim way
	    for (i = 0; i < $clog2(N_WAY); i++) begin
	        // Update the victim way based on the current PLRU bit
	        Victim_Way = (Victim_Way << 1) | bit'(~plru_bits[b]);
	
	        // $display("VictimWay = %b \n", Victim_Way);
	
	        // Compute the next node in the PLRU tree
	        b = (b << 1) + (1 << bit'(~plru_bits[b]));
	        // $display("Next Bit = %b \n", b);
	    end
	
	`ifdef DEBUG
	$display("NO invalid MESI state found. Returning PLRU-selected victim: way %0d ",Victim_Way);
	`endif

    return Victim_Way;  // Return the victim way
endfunction

endpackage : pkg_plru
