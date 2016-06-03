`timescale 1ns / 1ps

module filter
 #(parameter DWIDTH = 16,
   parameter DDWIDTH = 2*DWIDTH,
	parameter L = 160,
	parameter L_LOG = 8,
	parameter M = 147,
	parameter M_LOG = 8,
	parameter CWIDTH = 4*L,
	parameter NR_STREAMS = 16,
    parameter NR_STREAMS_LOG = 4)
  (input clk,
   input rst,
	output req_in,
	input ack_in,
	input [0:DWIDTH-1] data_in,
	output req_out,
	input ack_out,
	output [0:DWIDTH-1] data_out);

    // Output request register
    reg req_out_buf;
    assign req_out = req_out_buf;
    integer d;
    // Input request register
    reg req_in_buf;
    assign req_in = req_in_buf;
	 
	 reg signed [0:DWIDTH-1] h_in_array [0:CWIDTH];
	 // Check whether nr_stream is required or not
	/* reg signed [0:DWIDTH-1] data_in_array0 [0:NR_STREAMS - 1];
	 reg signed [0:DWIDTH-1] data_in_array1 [0:NR_STREAMS - 1];
	 reg signed [0:DWIDTH-1] data_in_array2 [0:NR_STREAMS - 1];
	 reg signed [0:DWIDTH-1] data_in_array3 [0:NR_STREAMS - 1];*/
	 
	 reg signed [0:DWIDTH-1] data_in_array0;
	 reg signed [0:DWIDTH-1] data_in_array1;
	 reg signed [0:DWIDTH-1] data_in_array2;
	 reg signed [0:DWIDTH-1] data_in_array3;
	 
	 reg signed [0:DWIDTH-1] h0;
	 reg signed [0:DWIDTH-1] h1;
	 reg signed [0:DWIDTH-1] h2;
	 reg signed [0:DWIDTH-1] h3;
	
	
	initial $readmemh ("coeffs.txt", h_in_array);
	 reg enter;
	 reg [0:9] index;
	 reg signed [0:DDWIDTH-1] mul1;
	 reg signed [0:DDWIDTH-1] mul2;
	 reg signed [0:DDWIDTH-1] mul3;
	 reg signed [0:DDWIDTH-1] mul4;
	 reg unsigned [0:15] stream_id;
	 reg unsigned compute;
    // Accumulator (assigned to output directly)
    reg signed [0:DDWIDTH-1] sum [0:NR_STREAMS - 1];
	 reg signed [0:DDWIDTH-1] out;
    assign data_out = out[0:15];
	 
  
    always @(posedge clk) begin
        // Reset => initialize
        if (rst) begin
            req_in_buf <= 1;
            req_out_buf <= 0;
				 mul1 <= 0;
				 mul2 <= 0;
				 mul3 <= 0;
				 mul4 <= 0;
				 stream_id <= 0;
				 enter <=1;
             out <= 0;
             index <= 0;
              h0 <= 0;
              h1 <= 160;
              h2 <= 320;
              h3 <= 480;	
             compute <= 0;				  
        end
        // !Reset => run
        else begin
		  
            // Read handshake complete
            if (req_in && ack_in) begin
				     // Shift samples
					/*  data_in_array3[stream_id] <= data_in_array2[stream_id];
					  data_in_array2[stream_id] <= data_in_array1[stream_id];
					  data_in_array1[stream_id] <= data_in_array0[stream_id];
			        // Take new samples at data_in_array0[]
				     data_in_array0[stream_id] <= data_in;*/
					  data_in_array3 <= data_in_array2;
					  data_in_array2 <= data_in_array1;
					  data_in_array1 <= data_in_array0;
			        // Take new samples at data_in_array0[]
				     data_in_array0 <= data_in;
					  compute <= 1;
					  req_in_buf <= 0;
                				              					                					  
            end			   				
				
			   //Read handshake is pending then stop producing output
			  if (req_in && !ack_in) begin  
                req_out_buf <= 0;
            end 
								
            // Write handshake complete
            if (req_out && ack_out) begin
                if (	stream_id == 0) begin			
                  
						  h0 <= h_in_array[index];
						  h1 <= h_in_array[index + 160];	
                    h2 <= h_in_array[index + 320];	 
					     h3 <= h_in_array[index + 480];
					 end
                 				
                if (	!enter) begin
                     req_in_buf <= 0;	
							compute <= 1;
                end
                else begin					 
				         req_in_buf <= 1; 
					 end
				    req_out_buf <= 0;
            end 
				//if(compute )  begin
               
         // end				  
            //Write handshake is pending then stop acquiring output.
            if (req_out && !ack_out) begin                			                  
				   req_in_buf <= 0;
            end 			            			  
				
            // Idle state
            if (!req_in && !ack_in && !req_out && !ack_out) begin 
				     mul1 <= h0 * data_in_array0;	
               mul2 <= h1 * data_in_array1;	
               mul3 <= h2 * data_in_array2;	
               mul4 <= h3 * data_in_array3;	
               sum[0] <=  mul1 + mul2 + mul3 + mul4;
               for(d=0; d < NR_STREAMS-2; d=d+1) begin
                 sum[d+1] <= sum[d];
               end					
					out <=  sum[NR_STREAMS-2];
				   req_out_buf <= 1;	
					req_in_buf <= 0;
				   
					if(stream_id == NR_STREAMS -1 ) begin				 
				         if(index >=L-M) begin  
						       enter <= 1;	
                         index <= index - 13;	
                         							 
					      end		
			            else begin
							    enter <= 0;	
					          index <= index + 147;
					      end 
                   // index_new <= index;								
                    stream_id <= 0; 							
                    				
              end
				  else begin
				        stream_id <= stream_id + 1;
				  end	
				  compute <= 0;
				 //  req_in_buf <= 1;
              
        
          end
		end
	end

endmodule
