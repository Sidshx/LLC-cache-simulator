`timescale 1ns / 1ps
`include "pkg_line.sv"
`include "pkg_bus.sv"
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

  initial begin
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
        int n;
        bit [31:0] address;
	bit[TAG_SIZE-1 :0] tag;
	// bit[INDEX_SIZE-1 :0] index;
	automatic bit match_found = 0;
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
	//index = address[19:6];

	
	case(n)
	3: begin //Snooped Read Request
	
	if(addr_check(cache_mem,address,way_idx))begin 
	//hit
	end
	else begin
	//Cache Miss

	end
	end
/*
	if(cache_mem[index].ways[way_idx].mesi == I )begin
		$display("Cache line in Invalid State, so No action taken.");
	end
	else begin
		$display ("No hit");
	if (cache_mem[index].ways[way_idx].mesi == M) begin
            $display("Snooped Read Request: Cache Hit in Modified State."); // BUS WRITE AND HITM 
            // Provide data to the requester
            $display("Providing data from Modified state to the requester.");
            // Transition to Shared (S) state
            cache_mem[index].ways[way_idx].mesi = S;
        end else if (cache_mem[index].ways[way_idx].mesi == E) begin
            $display("Snooped Read Request: Cache Hit in Exclusive State.");
            // Provide data to the requester
            $display("Providing data from Exclusive state to the requester.");
            // Transition to Shared (S) state
            cache_mem[index].ways[way_idx].mesi = S;
        end else if (cache_mem[index].ways[way_idx].mesi == S) begin
            $display("Snooped Read Request: Cache Hit in Shared State.");
            // Data is already shared, no state change needed
            $display("Providing data from Shared state to the requester.");
        end
    end
*/
endcase 


            // Process each trace event based on `n` value
            case (n)
              0: $display("Read request from L1 data cache, Address: %h \n", address);
              1: $display("Write request from L1 data cache, Address: %h\n", address);
              2: $display("Read request from L1 instruction cache, Address: %h\n", address);
              3: $display("Snooped read request, Address: %h\n", address);
              4: $display("Snooped write request, Address: %h\n", address);
              5: $display("Snooped read with intent to modify request, Address: %h\n", address);
		
		6: begin // Snoop Invalidate Command
		    $display("Processing Snoop Invalidate Command using pkg_bus...");
		
		    for (int i = 0; i < NUM_SETS; i++) begin
		        for (int j = 0; j < N_WAY; j++) begin
		            // Check if the cache line is valid (not Invalid)
		            if (cache_mem[i].ways[j].mesi != I) begin
		                case (cache_mem[i].ways[j].mesi)
		                    M: begin
		                        // Use pkg_bus function to handle invalidate
		                        pkg_bus::invalidate_line(i, j, M);
		                        cache_mem[i].ways[j].mesi = I; // Update state
		                    end
		                    E: begin
		                        pkg_bus::invalidate_line(i, j, E);
		                        cache_mem[i].ways[j].mesi = I; // Update state
		                    end
		                    S: begin
		                        pkg_bus::invalidate_line(i, j, S);
		                        cache_mem[i].ways[j].mesi = I; // Update state
		                    end
		                endcase
		            end
		        end
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
