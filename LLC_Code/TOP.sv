`timescale 1ns / 1ps
`include "pkg_line.sv"
`include "pkg_bus.sv"
`include "pkg_plru.sv"

import pkg_plru::*;
import pkg_line::*;
import pkg_bus::*;

module LLC_Cache;
  // Define the default trace file name
  string trace_filename = "rwims.din"; 	// changed path
  int file;
  string line;
//Initializing
  set_st cache_mem[NUM_SETS];
  mesi_e fsm_state;

  snoop_result_e snoop_result;

  initial begin
	int n;
        bit [31:0] address;
	bit[TAG_SIZE-1 :0] tag;
	bit[INDEX_SIZE-1 :0] index;
//	automatic bit match_found = 0;
	int way_idx; 
	int victim_idx; // Declare way_idx at the top
//        logic victim_idx;                    // Declare victim_idx at the top

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

      file = $fopen(trace_filename, "r");    	// Added else condition 
      if (file) begin
        `ifdef DEBUG
          $display("File opened successfully: %s \n", trace_filename);
        `endif
      end else begin
        $fatal("Error opening file: %s \n", trace_filename);
      end 
	// Set all bits to 0 and MESI to Invalid
      	initialize_cache();
      // Read and parse the file line-by-line
      while (!$feof(file)) begin

	automatic bit match_found = 0;

//        int n;
//        bit [31:0] address;
//	bit[TAG_SIZE-1 :0] tag;
//	bit[INDEX_SIZE-1 :0] index;
//	automatic bit match_found = 0;

        // Read a line from the file
        if ($fgets(line, file)) begin
          // Parse the line format "n address" where n is a number and address is a hex
          if ($sscanf(line, "%d %h %h", n, address) == 2) begin
          //  address1 = decode_address(address);
            `ifdef DEBUG
              $display("Parsed: n = %0d, \nAddress: Tag[31:20] = %h, Index[19:6] = %h , Offset[5:0] = %h",
               		n, address[31:20], address[19:6], address[5:0] );
            `endif
	//Address Read from trace file and segregated in tag and index bit
	//tag = address[31:20];
	logic[$clog2(N_WAY)-1:0 ] way_idx; //will return the way
	index = address[19:6];



           // Process each trace event based on `n` value
 // Process each trace event based on `n` value

	
//	case(n)
//	3: begin //Snooped Read Request
//	
//	if(addr_check(cache_mem,address,way_idx))begin 
//	//hit
//	end
//	else begin
//	//Cache Miss
//
//	end
//	end

	if(cache_mem[index].ways[way_idx].mesi == I )begin
		$display("Cache line in Invalid State, so No action taken.");

	end
	UpdatePLRU(cache_mem[index].plru_bits, victim_idx);
	end 

  end





            // Process each trace event based on `n` value
            case (n)
0: begin
    $display("Read request from L1 data cache, Address: %h \n", address);


    if (addrcheck(cache_mem, address, way_idx)) begin
        // Cache hit
        $display("Cache hit for address %h", address);
        UpdatePLRU(cache_mem[index].plru_bits, way_idx); // Update PLRU for cache hit
	  MessageToCache(SENDLINE,address);
    end else begin
        // Cache miss
        $display("Cache miss for address %h", address);

        victim_idx = VictimPLRU(cache_mem[index].plru_bits); // Find victim way
        if (cache_mem[index].ways[way_idx].mesi == M) begin
            $display("Victim is in Modified state. Performing BusWrite.");
            BusOperation(WRITE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0}, NormalMode);

        end 

        // Perform BusRead operation
        BusOperation(READ, address, NormalMode);

        // Update cache with new data
        cache_mem[index].ways[way_idx].tag = address[31:20];

        UpdatePLRU(cache_mem[index].plru_bits, victim_idx); // Update the PLRU tree

        // Get snoop result for the new address
        snoop_result = GetSnoopResult(address); 
        if (snoop_result == HIT || snoop_result == HITM) begin
            $display("Snoop response HIT or HITM. Transitioning to Shared state.");
            cache_mem[index].ways[way_idx].mesi = S;
        end else begin
            $display("No snoop hit. Transitioning to Exclusive state.");
            cache_mem[index].ways[way_idx].mesi = E;
        end

        // Notify L1
        MessageToCache(SENDLINE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0});
    end
end


1: begin
    $display("Write request from L1 data cache, Address: %h\n", address);

    if (addrcheck(cache_mem, address, way_idx)) begin
        // Cache hit
        $display("Cache hit for address %h", address);
        UpdatePLRU(cache_mem[index].plru_bits, way_idx); // Update PLRU for cache hit

        if (cache_mem[index].ways[way_idx].mesi == S) begin
            $display("Victim is in Modified state. Performing BusWrite.");
            BusOperation(INVALIDATE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0}, NormalMode);
            cache_mem[index].ways[way_idx].mesi = M;
        end else begin
            cache_mem[index].ways[way_idx].mesi = M;
        end

    end else begin
        $display("Cache miss for address %h", address);

        victim_idx = VictimPLRU(cache_mem[index].plru_bits);

        if (cache_mem[index].ways[way_idx].mesi == M) begin
            $display("Victim is in Modified state. Performing BusWrite.");
            BusOperation(WRITE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0}, NormalMode);
        end

        BusOperation(RWIM, address, NormalMode);
        cache_mem[index].ways[way_idx].tag = address[31:20];
        MessageToCache(SENDLINE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0});
    end
end


              2: begin $display("Read request from L1 instruction cache, Address: %h\n", address); 
	if (addr_check(cache_mem, address, way_idx)) begin 
	//Cache Hit
	    if (cache_mem[index].ways[way_idx].mesi == S) begin
                MessageToCache(SENDLINE, address); 
            end 
	else if (cache_mem[index].ways[way_idx].mesi == E) begin
                MessageToCache(SENDLINE, address);
            end
	end
	 else begin 
	//Cache Miss
	victim_idx = VictimPLRU(cache_mem[index].plru_bits); // Find victim way
	BusOperation(READ, address, 1);
	if (HIT == GetSnoopResult(address)) begin
	cache_mem[index].ways[way_idx].mesi = S;
	cache_mem[index].ways[way_idx].tag = address[31:20];
	MessageToCache(SENDLINE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0});
	end
	else if(NOHIT == GetSnoopResult(address))begin
	cache_mem[index].ways[way_idx].mesi = E;
	cache_mem[index].ways[way_idx].tag = address[31:20];
	MessageToCache(SENDLINE, {cache_mem[index].ways[victim_idx].tag, index, 6'b0});	
    
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
                PutSnoopResult(address, HIT);
                MessageToCache(INVALIDATELINE, address);
                cache_mem[index].ways[way_idx].mesi = I;
            end else if (cache_mem[index].ways[way_idx].mesi == M) begin
                PutSnoopResult(address, HITM);
                MessageToCache(GETLINE, address);
                MessageToCache(INVALIDATELINE, address);
                BusOperation(WRITE, address, 1);
                cache_mem[index].ways[way_idx].mesi = I;
		$display("BUG ALERT: There will be NO Modified state ");
            end else if (cache_mem[index].ways[way_idx].mesi == E) begin
                PutSnoopResult(address, HIT);
		//MessageToCache(INVALIDATELINE, address);
		$display("BUG ALERT: There will be NO Exclusive state ");
                cache_mem[index].ways[way_idx].mesi = I;
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
                PutSnoopResult(address, HIT);
                MessageToCache(INVALIDATELINE, address);
                cache_mem[index].ways[way_idx].mesi = I;
            end else if (cache_mem[index].ways[way_idx].mesi == M) begin
                PutSnoopResult(address, HITM);
                MessageToCache(GETLINE, address);
                MessageToCache(INVALIDATELINE, address);
                BusOperation(WRITE, address, 1);
                cache_mem[index].ways[way_idx].mesi = I;
            end else if (cache_mem[index].ways[way_idx].mesi == E) begin
                PutSnoopResult(address, HIT);
                cache_mem[index].ways[way_idx].mesi = I;
            end
        end else begin
            // Cache Miss
            PutSnoopResult(address, NOHIT);
        end
    end

              
6: begin
    $display("Snooped invalidate command, Address: %h\n", address);

	if(addr_check(cache_mem,address,way_idx))begin
	//Cache Hit
		if((cache_mem[index].ways[way_idx].mesi == S))begin
		PutSnoopResult(address, HIT);
		cache_mem[index].ways[way_idx].mesi = I;
		end

	else if ((cache_mem[index].ways[way_idx].mesi == M))begin
	//PutSnoopResult(address, HITM);
	//MessageToCache(GETLINE,address);
	//MessageToCache(INVALIDATELINE,address);
	//BusOperation(WRITE, address,1 );
	$display("BUG ALERT: For BUS Invalidate CMD(BusUpgr) it is going in M state");
	cache_mem[index].ways[way_idx].mesi = I;
	end

	else if ((cache_mem[index].ways[way_idx].mesi == E)) begin
	//PutSnoopResult(address, HIT);
	$display("BUG ALERT: For BUS Invalidate CMD(BusUpgr) it is going in E state");
	cache_mem[index].ways[way_idx].mesi = I;
	end
	end

	else begin
	//Cache Miss
	//PutSnoopResult(address, NOHIT);
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


              default: $display("Unknown trace event: %d\n", n);
            endcase

          end else begin
            $display("Invalid line format: %s", line);
          end
        end
      end

      // Close the file after reading
      $fclose(file);
      `ifdef DEBUG
        $display("Finished reading from %s.", trace_filename);
      `endif
    
  end

endmodule
