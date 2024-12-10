`timescale 1ns / 1ps
`include "pkg_line.sv"
`include "pkg_bus.sv"
`include "pkg_plru.sv"

import pkg_plru::*;
import pkg_line::*;
import pkg_bus::*;

module LLC_Cache;
    // Define the default trace file name
    string trace_filename = "rwims.din";  // Changed path
    int file;
    string line;

    // Initializing
    set_st cache_mem[NUM_SETS];
    mesi_e fsm_state;

    snoop_result_e snoop_result;

    initial begin
        int n;
        bit [31:0] address;
        bit[TAG_SIZE-1:0] tag;
        bit[INDEX_SIZE-1:0] index;
        int way_idx; 
        int victim_idx; // Declare way_idx at the top

	`ifdef DEBUG
	    $display("A working code snippet to read and parse an input trace file, using a default file if the user does not specify a filename.");
	`endif
	
	// Check if a custom filename was provided
	if (!$value$plusargs("trace_file=%s", trace_filename)) begin
	    `ifdef DEBUG
	        $display("No input trace file specified. Using default: %s", trace_filename);
	    `endif
	end else begin
	    `ifdef DEBUG
	        $display("Using input trace file: %s", trace_filename);
	    `endif
	end
	
	// Open the trace file
	file = $fopen(trace_filename, "r"); // Added else condition
	if (file) begin
	    `ifdef DEBUG
	        $display("File opened successfully: %s \n", trace_filename);
	    `endif
	end else begin
	    $fatal("Error opening file: %s \n", trace_filename);
	end
	
	// Set all bits to 0 and MESI to Invalid
	`ifdef DEBUG
	    $display("############### Initializing Cache ###############");
	`endif
	initialize_cache();
	
	// Read and parse the file line-by-line
	while (!$feof(file)) begin
	    automatic bit match_found = 0;
	
	    // Read a line from the file
	    if ($fgets(line, file)) begin
	        // Parse the line format "n address" where n is a number and address is a hex
	        if ($sscanf(line, "%d %h", n, address) == 2) begin
	            `ifdef DEBUG
	                $display("Parsed: n = %0d, \nAddress: Tag[31:20] = %h, Index[19:6] = %h, Offset[5:0] = %h",
	                         n, address[31:20], address[19:6], address[5:0]);
	            `endif
	
	            // Address Read from trace file and segregated into tag and index bits
	            // tag = address[31:20];
	            index = address[19:6];



            // Process each trace event based on `n` value
            case (n)

0: begin

    increment_read();
    $display("\n-> Read request from L1 data cache, Address: %h ", address);

    if (addr_check(cache_mem, address, way_idx)) begin
        // Cache hit
        `ifdef DEBUG
        $display("Cache hit for address %h", address);
        `endif

        increment_hit();
        
        UpdatePLRU(cache_mem[index].plru_bits, way_idx); // Update PLRU for cache hit

        MessageToCache(SENDLINE, address);
    end else begin
        // Cache miss
        `ifdef DEBUG
        $display("Cache miss for address %h", address);
        `endif

        increment_miss();
     
        victim_idx = VictimPLRU(cache_mem[index].plru_bits, cache_mem[index].ways); // Find victim way
	cache_mem[index].ways[victim_idx].tag = address[31:20];
        `ifdef DEBUG
            $display("Victim is in state : %0h", cache_mem[index].ways[victim_idx].mesi.name());
        `endif
        if (cache_mem[index].ways[victim_idx].mesi == M) begin
        
//            MessageToCache(GETLINE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0});
            MessageToCache(EVICTLINE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0});
            BusOperation(WRITE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0}, NormalMode);
        end 

        // Perform BusRead operation
        BusOperation(READ, address, NormalMode);

        // Update cache with new data
        UpdatePLRU(cache_mem[index].plru_bits, victim_idx); // Update the PLRU tree

        // Get snoop result for the new address
        snoop_result = GetSnoopResult(address);
	`ifdef DEBUG
            $display("Snoop result is : %0h ", snoop_result.name());
         `endif

        if (cache_mem[index].ways[victim_idx].mesi == I && (snoop_result == HIT || snoop_result == HITM)) begin

            cache_mem[index].ways[victim_idx].mesi = S

        end else if (cache_mem[index].ways[victim_idx].mesi == I && (snoop_result == NOHIT)) begin

 
            cache_mem[index].ways[victim_idx].mesi = E;

        end
	     `ifdef DEBUG
            $display("Updated MESI state is %0h", cache_mem[index].ways[victim_idx].mesi.name());
            `endif
        // Notify L1
        MessageToCache(SENDLINE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0});
    end
end



1: begin
    $display("\n-> Write request from L1 data cache, Address: %h", address);
    increment_write();

    if (addr_check(cache_mem, address, way_idx)) begin
        // Cache hit
        `ifdef DEBUG
        $display("Cache hit for address %h", address);
        `endif

        increment_hit();
        UpdatePLRU(cache_mem[index].plru_bits, way_idx); // Update PLRU for cache hit

        if (cache_mem[index].ways[way_idx].mesi == S || cache_mem[index].ways[way_idx].mesi == E) begin
            `ifdef DEBUG
            $display("Victim is in MODIFIED state. Performing BusWrite.");
            `endif

            BusOperation(INVALIDATE, {cache_mem[index].ways[way_idx].tag, index, 6'b0}, NormalMode);
            cache_mem[index].ways[way_idx].mesi = M;
        end else begin
            cache_mem[index].ways[way_idx].mesi = M;
        end

    end else begin // Cache miss
        `ifdef DEBUG
        $display("Cache miss for address %h", address);
        `endif

        increment_miss();

        victim_idx = VictimPLRU(cache_mem[index].plru_bits, cache_mem[index].ways);

        `ifdef DEBUG
        $display("The victim way found is = %0h", victim_idx);
        `endif

        if (cache_mem[index].ways[victim_idx].mesi == M) begin

            `ifdef DEBUG
            $display("Victim is in MODIFIED state. Performing BusWrite.");
            `endif

//            MessageToCache(GETLINE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0});
            MessageToCache(EVICTLINE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0});
            BusOperation(WRITE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0}, NormalMode);
        end else if (cache_mem[index].ways[victim_idx].mesi == S || cache_mem[index].ways[victim_idx].mesi == E) begin
		MessageToCache(EVICTLINE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0});
	end

        UpdatePLRU(cache_mem[index].plru_bits, victim_idx);
        BusOperation(RWIM, address, NormalMode);
        cache_mem[index].ways[victim_idx].tag = address[31:20];
        cache_mem[index].ways[victim_idx].mesi = M;
        MessageToCache(SENDLINE, {cache_mem[index].ways[way_idx].tag, index, 6'b0});
    end
end



2: begin
    increment_read();

    $display("\n-> Read request from L1 instruction cache, Address: %h", address);
    

    if (addr_check(cache_mem, address, way_idx)) begin
        `ifdef DEBUG
        $display("Cache hit for address %h", address); // Cache Hit
        `endif

        increment_hit();

        UpdatePLRU(cache_mem[index].plru_bits, way_idx);

        if (cache_mem[index].ways[way_idx].mesi == S || cache_mem[index].ways[way_idx].mesi == E) begin
            MessageToCache(SENDLINE, address);
        end
    end else begin

        `ifdef DEBUG
        $display("Cache miss for address %h", address); // Cache Miss
        `endif

        increment_miss();

        victim_idx = VictimPLRU(cache_mem[index].plru_bits, cache_mem[index].ways); // Find victim way
        UpdatePLRU(cache_mem[index].plru_bits, victim_idx);

	MessageToCache(EVICTLINE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0});
        BusOperation(READ, address, NormalMode);

        if (NOHIT == GetSnoopResult(address)) begin
            cache_mem[index].ways[victim_idx].mesi = E;
        end else begin
            cache_mem[index].ways[victim_idx].mesi = S;
        end
	cache_mem[index].ways[victim_idx].tag = address[31:20];
        MessageToCache(SENDLINE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0});
    end
end


3: begin // Snooped Read Request

    $display("\n-> Snooped read request, Address: %h", address);
  

    if (addr_check(cache_mem, address, way_idx)) begin
        // Cache hit
        if (cache_mem[index].ways[way_idx].mesi == S || cache_mem[index].ways[way_idx].mesi == E) begin
            PutSnoopResult(address, HIT);
	    cache_mem[index].ways[way_idx].mesi = S;
        end else if (cache_mem[index].ways[way_idx].mesi == M) begin
            PutSnoopResult(address, HITM);
            MessageToCache(GETLINE, address);
            BusOperation(WRITE, address, NormalMode);
            cache_mem[index].ways[way_idx].mesi = S;
        end 
    end else begin
        // Cache Miss
        PutSnoopResult(address, NOHIT);
    end
end


4: begin // Snooped Write Request

    $display("\n-> Snooped write request, Address: %h", address);
    
    if (addr_check(cache_mem, address, way_idx)) begin
        // Cache hit
        if (cache_mem[index].ways[way_idx].mesi == S || cache_mem[index].ways[way_idx].mesi == E) begin
//              PutSnoopResult(address, HIT);
//              MessageToCache(INVALIDATELINE, address);
		`ifdef DEBUG
            	$display("BUG ALERT: There will be NO Shared/Exclusive state ");
            	`endif
        //    cache_mem[index].ways[way_idx].mesi = I;
        end else if (cache_mem[index].ways[way_idx].mesi == M) begin
            `ifdef DEBUG
            $display("BUG ALERT: There will be NO Modified state ");
            `endif
        end
    end else begin
        // Cache Miss
        PutSnoopResult(address, NOHIT);
    end
end


5: begin // Snooped Read with Intent to Modify
 
    $display("\n-> Snooped read with intent to modify request, Address: %h", address);
    

    if (addr_check(cache_mem, address, way_idx)) begin
        // Cache hit
	        if (cache_mem[index].ways[way_idx].mesi == S || cache_mem[index].ways[way_idx].mesi == E) begin
	            PutSnoopResult(address, HIT); // Is it necessary?
	            MessageToCache(INVALIDATELINE, {cache_mem[index].ways[way_idx].tag, index, 6'b0});
	            cache_mem[index].ways[way_idx].mesi = I;
	        end else if (cache_mem[index].ways[way_idx].mesi == M) begin
	            PutSnoopResult(address, HITM);
	            MessageToCache(GETLINE, {cache_mem[index].ways[way_idx].tag, index, 6'b0});
	            MessageToCache(INVALIDATELINE, {cache_mem[index].ways[way_idx].tag, index, 6'b0});
	            BusOperation(WRITE, {cache_mem[index].ways[way_idx].tag, index, 6'b0}, NormalMode);
	            cache_mem[index].ways[way_idx].mesi = I;
	        end 
		
    end else begin 
	PutSnoopResult(address, NOHIT);
	end
end

              
6: begin
    $display("\n-> Snooped invalidate command, Address: %h", address);
    
    if (addr_check(cache_mem, address, way_idx)) begin
        // Cache Hit
        `ifdef DEBUG
        $display("Cache Hit, address present");
        `endif

	        if (cache_mem[index].ways[way_idx].mesi == S || cache_mem[index].ways[way_idx].mesi == E) begin
	            PutSnoopResult(address, HIT); // Is it necessary?
	            `ifdef DEBUG
	//            $display("Current St: S, Next St: I");
	            `endif
		    MessageToCache(INVALIDATELINE, address);
	            cache_mem[index].ways[way_idx].mesi = I;
	
	        end else if ((cache_mem[index].ways[way_idx].mesi == M)) begin
	
	            `ifdef DEBUG
	 //           $display("BUG ALERT: For BUS Invalidate CMD(BusUpgr) it is going in M state");
	            `endif
			MessageToCache(GETLINE, {cache_mem[index].ways[way_idx].tag, index, 6'b0});
		        MessageToCache(INVALIDATELINE, {cache_mem[index].ways[way_idx].tag, index, 6'b0});
		        BusOperation(WRITE, {cache_mem[index].ways[way_idx].tag, index, 6'b0}, NormalMode);
		            
	        end
    end else begin
	PutSnoopResult(address, NOHIT);
    end
end

                         

8: begin
    $display("\n-> Clearing the cache and resetting all state.");
    initialize_cache(); // Clear the cache

    `ifdef DEBUG
        $display("\n Cache cleared and all states reset.");
    `endif
end

9: begin // Print contents and state of each valid cache line
        $display("\n-> Printing contents and state of each valid cache line.");

    for (int i = 0; i < NUM_SETS; i++) begin
        for (int j = 0; j < N_WAY; j++) begin
            if (cache_mem[i].ways[j].mesi != I) begin
                $display("Set: %0d, Way: %0d, MESI: %s, Tag: %h", 
                         i, j, cache_mem[i].ways[j].mesi, cache_mem[i].ways[j].tag);
            end
        end
    end
end


default: begin 
    $display("Unknown trace event: %d\n", n);
end

endcase

end else begin
    $display("Invalid line format: %s", line);
end
end
end

$display("\nNo. of cache hits = %0d", cache_hits);
$display("No. of cache misses = %0d", cache_misses);
$display("No. of cache writes = %0d", cache_write);
$display("No. of cache reads = %0d \n", cache_reads);


// Close the file after reading
$fclose(file);
`ifdef DEBUG
    $display("Finished reading from %s.", trace_filename);
`endif


$display("=======================================\nANKARA MESSI ANKARA MESSI MESSI MESSI ANKARA MESSI GOAAAAAAAAAAAAAAAL ======================================!");
hit_ratio();
end

endmodule

