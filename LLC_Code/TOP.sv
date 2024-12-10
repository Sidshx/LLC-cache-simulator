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
        // automatic bit match_found = 0;
        // logic[$clog2(N_WAY)-1:0] way_idx; // Will return the way
        int way_idx; 
        int victim_idx; // Declare way_idx at the top
        // logic victim_idx; // Declare victim_idx at the top

	`ifdef DEBUG
	    $display("Working code to read and parse an input trace file (the name of which is specified by the user) with correct default if none specified");
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
	    $display("Initializing Cache");
	`endif
	initialize_cache();
	
	// Read and parse the file line-by-line
	while (!$feof(file)) begin
	    automatic bit match_found = 0;
	
	    // Read a line from the file
	    if ($fgets(line, file)) begin
	        // Parse the line format "n address" where n is a number and address is a hex
	        if ($sscanf(line, "%d %h", n, address) == 2) begin
	            // address1 = decode_address(address);
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
    $display("Read request from L1 data cache, Address: %h \n", address);
    increment_read();

    if (addr_check(cache_mem, address, way_idx)) begin
        // Cache hit
        $display("Cache hit for address %h", address);
        increment_hit();
        $display("Cache hit is = %0h, cache_misses is = %0h, way_idx = %0d", cache_hits, cache_misses, way_idx);
        
        UpdatePLRU(cache_mem[index].plru_bits, way_idx); // Update PLRU for cache hit
        MessageToCache(SENDLINE, address);
    end else begin
        // Cache miss
        $display("Cache miss for address %h", address);
        increment_miss();
        $display("Cache hit is = %0h, cache_misses is = %0h, way_idx = %0d", cache_hits, cache_misses, way_idx);
        $display("MESI state before entering function is = %0h", cache_mem[index].ways[1].mesi);
        
        victim_idx = VictimPLRU(cache_mem[index].plru_bits, cache_mem[index].ways); // Find victim way
        cache_mem[index].ways[victim_idx].tag = address[31:20];
        
        if (cache_mem[index].ways[victim_idx].mesi == M) begin
            $display("Victim is in Modified state. Performing BusWrite.");
            MessageToCache(GETLINE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0});
            MessageToCache(INVALIDATELINE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0});
            BusOperation(WRITE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0}, NormalMode);
        end 

        // Perform BusRead operation
        BusOperation(READ, address, NormalMode);

        // Update cache with new data
        $display("Index = %0h, way = %0h, tag = %0h", index, way_idx, cache_mem[index].ways[way_idx].tag);
        UpdatePLRU(cache_mem[index].plru_bits, victim_idx); // Update the PLRU tree

        // Get snoop result for the new address
        snoop_result = GetSnoopResult(address);
        if (snoop_result == HIT || snoop_result == HITM) begin
            $display("Snoop response HIT or HITM. Transitioning to Shared state.");
            cache_mem[index].ways[victim_idx].mesi = S;
            $display("Current state %0d", cache_mem[index].ways[victim_idx].mesi);
        end else begin
            $display("No snoop hit. Transitioning to Exclusive state.");
            cache_mem[index].ways[victim_idx].mesi = E;
            $display("Current state %0d", cache_mem[index].ways[victim_idx].mesi);
        end

        // Notify L1
        MessageToCache(SENDLINE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0});
    end
end



1: begin
    $display("Write request from L1 data cache, Address: %h\n", address);
    increment_write();

    if (addr_check(cache_mem, address, way_idx)) begin
        // Cache hit
        $display("Cache hit for address %h", address);
        increment_hit();

        UpdatePLRU(cache_mem[index].plru_bits, way_idx); // Update PLRU for cache hit

        if (cache_mem[index].ways[way_idx].mesi == S) begin
            $display("Victim is in Modified state. Performing BusWrite.");
            BusOperation(INVALIDATE, {cache_mem[index].ways[way_idx].tag, index, 6'b0}, NormalMode);
            cache_mem[index].ways[way_idx].mesi = M;
        end else begin
            cache_mem[index].ways[way_idx].mesi = M;
        end

    end else begin // Cache miss
        $display("Cache miss for address %h", address);
        increment_miss();

        victim_idx = VictimPLRU(cache_mem[index].plru_bits, cache_mem[index].ways);
        $display("The victim way found is = %0h", victim_idx);

        if (cache_mem[index].ways[victim_idx].mesi == M) begin
            $display("Victim is in Modified state. Performing BusWrite.");
            MessageToCache(GETLINE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0});
            MessageToCache(INVALIDATELINE, {cache_mem[index].ways[way_idx].tag, index, 6'b0});
            BusOperation(WRITE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0}, NormalMode);
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
    $display("Read request from L1 instruction cache, Address: %h\n", address);

    if (addr_check(cache_mem, address, way_idx)) begin
        $display("Cache hit for address %h", address); // Cache Hit
        increment_hit();
        UpdatePLRU(cache_mem[index].plru_bits, way_idx);

        if (cache_mem[index].ways[way_idx].mesi == S || cache_mem[index].ways[way_idx].mesi == E) begin
            MessageToCache(SENDLINE, address);
        end
    end else begin
        $display("Cache miss for address %h", address); // Cache Miss
        increment_miss();

        victim_idx = VictimPLRU(cache_mem[index].plru_bits, cache_mem[index].ways); // Find victim way
        cache_mem[index].ways[victim_idx].tag = address[31:20];
        UpdatePLRU(cache_mem[index].plru_bits, victim_idx);

        BusOperation(READ, address, NormalMode);

        if (NOHIT == GetSnoopResult(address)) begin
            cache_mem[index].ways[victim_idx].mesi = E;
        end else begin
            cache_mem[index].ways[victim_idx].mesi = S;
        end

        MessageToCache(SENDLINE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0});
    end
end


3: begin // Snooped Read Request
    $display("Snooped read request, Address: %h\n", address);

    if (addr_check(cache_mem, address, way_idx)) begin
        // Cache hit
        if (cache_mem[index].ways[way_idx].mesi == S) begin
            PutSnoopResult(address, HIT);
        end else if (cache_mem[index].ways[way_idx].mesi == M) begin
            PutSnoopResult(address, HITM);
            MessageToCache(GETLINE, address);
            BusOperation(WRITE, address, 1);
            cache_mem[index].ways[way_idx].mesi = S;
        end else if (cache_mem[index].ways[way_idx].mesi == E) begin
            PutSnoopResult(address, HIT);
            cache_mem[index].ways[way_idx].mesi = S;
        end
    end else begin
        // Cache Miss
        PutSnoopResult(address, NOHIT);
    end
end


4: begin // Snooped Write Request
    $display("Snooped write request, Address: %h\n", address);

    if (addr_check(cache_mem, address, way_idx)) begin
        // Cache hit
        if (cache_mem[index].ways[way_idx].mesi == S) begin
        //    PutSnoopResult(address, HIT);
        //    MessageToCache(INVALIDATELINE, address);
        //    cache_mem[index].ways[way_idx].mesi = I;
        end else if (cache_mem[index].ways[way_idx].mesi == M) begin
        //    $display("BUG ALERT: There will be NO Modified state ");
        end else if (cache_mem[index].ways[way_idx].mesi == E) begin
        //    $display("BUG ALERT: There will be NO Exclusive state ");
        end
    end else begin
        // Cache Miss
        PutSnoopResult(address, NOHIT);
    end
end


5: begin // Snooped Read with Intent to Modify
    $display("Snooped read with intent to modify request, Address: %h\n", address);

    if (addr_check(cache_mem, address, way_idx)) begin
        // Cache hit
        if (cache_mem[index].ways[way_idx].mesi == S) begin
            PutSnoopResult(address, HIT); // Is it necessary?
            MessageToCache(INVALIDATELINE, {cache_mem[index].ways[way_idx].tag, index, 6'b0});
            cache_mem[index].ways[way_idx].mesi = I;
        end else if (cache_mem[index].ways[way_idx].mesi == M) begin
            PutSnoopResult({cache_mem[index].ways[way_idx].tag, index, 6'b0}, HITM);
            MessageToCache(GETLINE, {cache_mem[index].ways[way_idx].tag, index, 6'b0});
            MessageToCache(INVALIDATELINE, {cache_mem[index].ways[way_idx].tag, index, 6'b0});
            BusOperation(WRITE, {cache_mem[index].ways[way_idx].tag, index, 6'b0}, 1);
            cache_mem[index].ways[way_idx].mesi = I;
        end else if (cache_mem[index].ways[way_idx].mesi == E) begin
            PutSnoopResult({cache_mem[index].ways[way_idx].tag, index, 6'b0}, HIT);
            cache_mem[index].ways[way_idx].mesi = I;
        end
    end
end

              
6: begin
    $display("Snooped invalidate command, Address: %h\n", address);

    if (addr_check(cache_mem, address, way_idx)) begin
        // Cache Hit
        $display("Cache Hit, address present");

        if ((cache_mem[index].ways[way_idx].mesi == S)) begin
            PutSnoopResult({cache_mem[index].ways[way_idx].tag, index, 6'b0}, HIT); // Is it necessary?
            $display("Current St: S, Next St: I");
            cache_mem[index].ways[way_idx].mesi = I;
        end else if ((cache_mem[index].ways[way_idx].mesi == M)) begin
            $display("BUG ALERT: For BUS Invalidate CMD(BusUpgr) it is going in M state");
        end else if ((cache_mem[index].ways[way_idx].mesi == E)) begin
            $display("BUG ALERT: For BUS Invalidate CMD(BusUpgr) it is going in E state");
        end
    end else begin
        $display("Cache MISS");
    end
end

                         

8: begin
    $display("Clear the cache and reset all state.");
    initialize_cache(); // Clear the cache
    `ifdef DEBUG
        $display("Cache cleared and all states reset.");
    `endif
end

9: begin // Print contents and state of each valid cache line
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

$display("No. of cache hits = %0d", cache_hits);
$display("No. of cache misses = %0d", cache_misses);
$display("No. of cache writes = %0d", cache_write);
$display("No. of cache reads = %0d", cache_reads);
$display("======================================= \n ANKARA MESSI ANKARA MESSI MESSI MESSI ANKARA MESSI GOAAAAAAAAAAAAAAAL!");





// Close the file after reading
$fclose(file);
`ifdef DEBUG
    $display("Finished reading from %s.", trace_filename);
`endif

hit_ratio();
end

endmodule

