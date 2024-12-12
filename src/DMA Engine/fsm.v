module fsm #(parameter DATA_WIDTH = 32, BUFFER_DEPTH = 16, ADDR_WIDTH = 32 )(

//////////////////////////BUFF SIGNALS//////////////////////////////////////////////////////////////////
input    wire                        clk,
input    wire                        rst,
input    wire    [DATA_WIDTH-1:0]    i_data_buff,
input    wire                        i_valid_buff,
output   reg                         o_rd0_wr1_buff,
output   reg                         o_valid_buff,
output   reg     [DATA_WIDTH-1:0]    o_data_buff,
//////////////////////////REG_FILE SIGNALS//////////////////////////////////////////////////////////////////
input    wire                        i_sw_en_config,
input    wire    [7:0]               i_hw_en_config,
input    wire    [DATA_WIDTH-1:0]    i_src_addr_config,
input    wire    [DATA_WIDTH-1:0]    i_dist_addr_config,
input    wire    [DATA_WIDTH-1:0]    i_src_addr_type_config,
input    wire    [DATA_WIDTH-1:0]    i_dist_addr_type_config,
input    wire    [DATA_WIDTH-1:0]    i_src_data_width_config,
input    wire    [DATA_WIDTH-1:0]    i_dist_data_width_config,
input    wire    [DATA_WIDTH-1:0]    i_total_trans_config,
//////////////////////////AHB SIGNALS//////////////////////////////////////////////////////////////////
input    wire   [DATA_WIDTH-1:0]     i_rd_data_ahb,
input    wire                        i_ready_ahb,
input    wire                        i_rd_valid_ahb,
output   reg    [DATA_WIDTH-1:0]     o_wr_data_ahb,
output   reg    [ADDR_WIDTH-1:0]     o_addr_ahb,
output   reg                         o_valid_ahb, 
output   reg                         o_rd0_wr1_ahb,

output   reg                         o_trig_end
); 
//////////////////////////internal SIGNALS//////////////////////////////////////////////////////////////////
reg    [DATA_WIDTH-1:0]    i_src_addr_reg;
reg    [DATA_WIDTH-1:0]    i_dist_addr_reg;
reg    [DATA_WIDTH-1:0]    i_src_data_width_reg;
reg    [DATA_WIDTH-1:0]    i_dist_data_width_reg;
reg    [DATA_WIDTH-1:0]    i_total_trans_reg;
reg    [3:0]               data_width_differ;
reg    [3:0]               chunk_reg;
reg    [3:0]               chunk_indecate;
reg    [3:0]               less_indecate;
reg    [4:0]               next_state,current_state;
reg    [7:0]               counter_main;
reg    [7:0]               counter_chunck;
reg    [7:0]               counter_internal;
reg    [7:0]               counter_internal_reg;
reg    [7:0]               reminder;
reg    [7:0]               counter_2;
reg    [7:0]               counter_reg;
reg    [DATA_WIDTH-1:0]    source_greater_reg;
reg                        differ_width_flag ;
reg                        last_flag ;


parameter  idle      = 'b0000,
           state_1   = 'b0001,
           state_2   = 'b0010,
		   state_2_2 = 'b0011,
		   state_2_3 = 'b0100,
		   state_3   = 'b0101,
		   state_3_2 = 'b0110,
		   state_3_3 = 'b0111,
		   state_4   = 'b1000,
		   state_4_2 = 'b1001,
		   state_4_3 = 'b1010,
		   state_5   = 'b1011,
		   state_5_2 = 'b1100,
		   state_5_3 = 'b1101,
		   finish    = 'b1110,
		   state_6   = 'b1111;

		   
		   
		   
always @ (posedge clk , negedge rst) begin
    if (!rst) begin
       current_state <= idle;
    end else begin 
       current_state <= next_state;
	end
end	  		  



always @ (*) begin
    case (current_state)
	idle: begin
          i_src_addr_reg = 'b0;
          i_dist_addr_reg= 'b0;
          i_src_data_width_reg= 'b0;
          i_dist_data_width_reg= 'b0;
          i_total_trans_reg= 'b0;
          data_width_differ= 'b0;
          chunk_reg= 'b0;
          chunk_indecate= 'b0;
		  counter_main= 'b0;
          counter_chunck= 'b0;
          counter_internal= 'b0;
		  counter_2= 'b0;
          counter_reg= 'b0;
          source_greater_reg= 'b0;
          differ_width_flag= 'b0 ;
		  o_rd0_wr1_buff= 'b0;
          o_valid_buff= 'b0;
          o_data_buff= 'b0;
          o_wr_data_ahb= 'b0;
          o_addr_ahb= 'b0;
          o_valid_ahb= 'b0;
          o_rd0_wr1_ahb= 'b0;
          o_trig_end= 'b0;
		  
		   if (i_sw_en_config && (i_hw_en_config != 8'b0) && ((i_hw_en_config & (i_hw_en_config - 8'b1)) == 8'b0)) begin
	        next_state = state_1 ;
		 end else begin
         	next_state = idle ;	
         end	
		
	end
	state_1: begin

          i_src_data_width_reg= i_src_data_width_config;
          i_dist_data_width_reg= i_dist_data_width_config;
		  i_total_trans_reg= i_total_trans_config / i_src_data_width_config ; 
		  data_width_differ = i_src_data_width_reg / i_dist_data_width_reg;
		  if (i_total_trans_reg > BUFFER_DEPTH) begin
		       if ((i_total_trans_reg % 16 ) == 0 ) begin
		          chunk_reg =( i_total_trans_reg / BUFFER_DEPTH ) ;  
                  chunk_indecate = 1;
		        end else begin 
		          chunk_reg =( i_total_trans_reg / BUFFER_DEPTH )+1 ;   
                  chunk_indecate = 1;
		        end
		         reminder = i_total_trans_reg % BUFFER_DEPTH ;
             end else begin 
		         chunk_indecate = 0;
		         if (i_total_trans_reg < BUFFER_DEPTH) begin
		             less_indecate = 1;
		       	end else begin 
			         less_indecate = 0;
			    end
		    end
		  
		   if (data_width_differ>1)begin 
				 last_flag =1;
			end else begin 
			     last_flag =0;
			end
		  
		   if (!counter_chunck)begin 
				  i_dist_addr_reg= i_dist_addr_config;
				  i_src_addr_reg = i_src_addr_config;
			end
		  
		  if (i_src_addr_type_config && i_dist_addr_type_config && i_ready_ahb) begin
	         next_state = state_2 ;
		 end else if (i_src_addr_type_config && !i_dist_addr_type_config && i_ready_ahb) begin
		     next_state = state_3 ;
		 end else if (!i_src_addr_type_config && i_dist_addr_type_config && i_ready_ahb) begin
		     next_state = state_4 ;
	     end else if (!i_src_addr_type_config && !i_dist_addr_type_config && i_ready_ahb) begin
		     next_state = state_5 ;
		 end else begin
         	next_state = state_1 ;	
         end	
		 
	end
	state_2: begin
	      
		if (i_ready_ahb) begin
		    if (!i_rd_valid_ahb) begin
			  o_addr_ahb = i_src_addr_reg;
		      o_rd0_wr1_ahb =0;
              o_valid_ahb = 1;
			 end else if (i_rd_valid_ahb) begin
			  o_rd0_wr1_buff = 1;
              o_valid_buff = 1;
              o_data_buff = i_rd_data_ahb ;
			  o_addr_ahb = i_src_addr_reg;
		      o_rd0_wr1_ahb =0;
              o_valid_ahb = 1;
			 end else begin 
		      o_valid_buff = 0;
		     end	 
	     end else begin
		      o_valid_ahb = 0;
			  o_valid_buff = 0;
		 end
		
		
		if (!i_ready_ahb) begin  
		     next_state = state_2 ;
			 
         end else if (!i_rd_valid_ahb && counter_main < i_total_trans_reg && !chunk_indecate ) begin
	        next_state = state_2_2 ;
	    
         end else if (i_rd_valid_ahb && counter_main < i_total_trans_reg && !chunk_indecate ) begin
	        next_state = state_2_2 ;
			
	     end else if (counter_main > i_total_trans_reg && i_rd_valid_ahb && !chunk_indecate) begin
		     next_state = state_2_3 ;
			 counter_main = 0;			 

		 end else if (!i_rd_valid_ahb && counter_main < i_total_trans_reg && chunk_indecate ) begin 
	         next_state = state_2_2 ;
			 
	     end else if ( (((counter_chunck * BUFFER_DEPTH) + counter_main) == i_total_trans_reg) && chunk_indecate ) begin 
	         next_state = state_2_3 ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;
			 
		 end else if (i_rd_valid_ahb && counter_main < BUFFER_DEPTH && chunk_indecate) begin
		     next_state = state_2_2 ;
			 
		 end else if (counter_main > BUFFER_DEPTH && i_rd_valid_ahb && chunk_indecate) begin
		     next_state = state_2_3 ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;	
	 
		 end else begin
         	next_state = state_2_3 ;	
			 counter_main = 0;	
		    counter_chunck = counter_chunck +1;		 
         end	
		 
	end
	state_2_2: begin
	      
		   if (i_ready_ahb) begin
			  if (i_rd_valid_ahb) begin
		         o_rd0_wr1_buff = 1;
                 o_valid_buff = 1;
                 o_data_buff = i_rd_data_ahb ;
			     counter_main = counter_main + 1;
	
			     o_addr_ahb = i_src_addr_reg;
		         o_rd0_wr1_ahb =0;
                 o_valid_ahb = 1;
			 end else begin 
		         o_valid_buff = 0;
		     end	  
           end else begin
		         o_valid_ahb = 0;
			     o_valid_buff = 0;
		   end
		   
	     if (!i_ready_ahb) begin  
		     next_state = state_2_2 ;
			
         end else if (i_rd_valid_ahb && counter_main < i_total_trans_reg && !chunk_indecate ) begin
	         next_state = state_2;
			
	     end else if (counter_main > i_total_trans_reg && i_rd_valid_ahb && !chunk_indecate) begin
		     next_state = state_2_3 ;
			 counter_main = 0;	
	
		 end else if (i_rd_valid_ahb && counter_main < BUFFER_DEPTH && chunk_indecate) begin
		     next_state = state_2 ;
			 
	     end else if ( (((counter_chunck-1) * BUFFER_DEPTH) + counter_main) == i_total_trans_reg && chunk_indecate ) begin
	         next_state = state_2_3 ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;
			 	 
	   	end else if (counter_main > BUFFER_DEPTH && i_rd_valid_ahb && chunk_indecate) begin
		     next_state = state_2_3 ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;		 
		 end else begin
         	 next_state = state_2_3 ;	
			 if (less_indecate) begin 
			     counter_main = 0;	
			 end
         end	
	end
	state_2_3: begin
	
	     if (i_ready_ahb) begin
	         o_rd0_wr1_buff =0;
			 o_valid_buff=1;
	    	 if (data_width_differ==4 && counter_2)begin
			     o_valid_buff=0;
			 end 
      
			 if (i_valid_buff || (!i_valid_buff&&counter_2)) begin
			     if(!last_flag)
			         o_addr_ahb = i_dist_addr_reg ;
					 
                 o_valid_ahb =1;
                 o_rd0_wr1_ahb =1;
			////////////////////////////////////////////////////////////
			 if (i_src_data_width_reg > i_dist_data_width_reg) begin
				    if (i_src_data_width_reg == 'd32 && i_dist_data_width_reg == 'd16 )begin
				    case (counter_2)
                       0: o_wr_data_ahb = source_greater_reg[15:0];
                       1: o_wr_data_ahb = source_greater_reg[31:16];
                       default: o_wr_data_ahb = 0;
                    endcase
					end else if (i_src_data_width_reg == 'd32 && i_dist_data_width_reg == 'd8)begin
		
					if (counter_main>0) begin
					 case (counter_2)
					   0: o_wr_data_ahb = source_greater_reg[7:0];
                       1: o_wr_data_ahb = source_greater_reg[15:8];
					   2: o_wr_data_ahb = source_greater_reg[23:16];
					   3: o_wr_data_ahb = source_greater_reg[31:24];
					     default: o_wr_data_ahb = 0;
                    endcase
					end else begin
					 case (counter_2)
                       0: o_wr_data_ahb = source_greater_reg[7:0];
                       2: o_wr_data_ahb = source_greater_reg[15:8];
					   3: o_wr_data_ahb = source_greater_reg[23:16];
					   4: o_wr_data_ahb = source_greater_reg[31:24];
                       default: o_wr_data_ahb = 0;
                    endcase
					end
					end else if (i_src_data_width_reg == 'd16 && i_dist_data_width_reg == 'd8 )begin
				    case (counter_2)
                       0: o_wr_data_ahb = source_greater_reg[7:0];
                       1: o_wr_data_ahb = source_greater_reg[15:8];
                       default: o_wr_data_ahb = 0;
                    endcase
					end else begin
					  o_wr_data_ahb = 0;
					end
			        
					 counter_2 = counter_2 + 1;
					 counter_reg = counter_main ; 
				      if ((counter_2 == data_width_differ) || (data_width_differ==4 && counter_2==5))begin
					     counter_main = counter_main +1;
						 counter_2 = 0;
	                     o_valid_buff=1;
					 end else begin
					     counter_main = counter_reg ; 
                     end					
					 
			 end else begin 
				 o_wr_data_ahb = i_data_buff;
			     counter_main = counter_main +1;
				 end
			end else begin 
                 o_valid_ahb =0;
				 if( counter_main  && last_flag) 
				     o_valid_ahb =1;  
            end
	    end else begin
		     o_valid_ahb = 0;
			 o_valid_buff = 0;
		 end
		/////////////////////////////////////////////////////////////////////////////////////////
         if (!i_ready_ahb) begin  
		     next_state = state_2_3 ;
         end else if( counter_main < i_total_trans_reg && !chunk_indecate && last_flag) begin	
		     next_state = state_6  ;
		 
		 end else if (counter_main == i_total_trans_reg  && !chunk_indecate && last_flag) begin
		     next_state = finish ;
			 o_valid_buff=0;
			 counter_main = 0;	
			 
		 end else if ( (((counter_chunck-1) * BUFFER_DEPTH) + counter_main) > i_total_trans_reg && chunk_indecate && last_flag) begin
	         next_state = finish ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;

		 end else if ( counter_main < BUFFER_DEPTH && chunk_indecate && last_flag) begin
		     next_state = state_6 ;
			 
		 end else if (counter_main == BUFFER_DEPTH && chunk_indecate && last_flag) begin
		     next_state = finish ;
			  o_valid_buff=0;
			 counter_main = 0;	

             
         end else if (i_valid_buff && counter_main < i_total_trans_reg && !chunk_indecate ) begin
	        next_state = state_2_3  ;

		 end else if (counter_main > i_total_trans_reg  && !chunk_indecate) begin
		    next_state = finish ;
			 o_valid_buff=0;
			 counter_main = 0;	
			 
		 end else if ( (((counter_chunck-1) * BUFFER_DEPTH) + counter_main) > i_total_trans_reg && chunk_indecate ) begin 
	          next_state = finish ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;

		 end else if (i_valid_buff && counter_main < BUFFER_DEPTH && chunk_indecate) begin
		     next_state = state_2_3 ;
			 
		 end else if (counter_main > BUFFER_DEPTH && i_valid_buff && chunk_indecate) begin
		     next_state = finish ;
			  o_valid_buff=0;
			 counter_main = 0;	 
	
		 end else begin
         	next_state = state_2_3 ;	
         end	
		 
	end
	///////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////
	state_6: begin
              o_valid_buff=0;
			 if (i_valid_buff || (data_width_differ==4)) begin
			     o_addr_ahb = i_dist_addr_reg ;
                 o_valid_ahb =1;
                 o_rd0_wr1_ahb =1;
				 
				  if (!data_width_differ==4 || !counter_2) begin
				  source_greater_reg = i_data_buff ;
				  end
			
				    if (i_src_data_width_reg == 'd32 && i_dist_data_width_reg == 'd16 )begin
				    case (counter_2)
                       0: o_wr_data_ahb = source_greater_reg[15:0];
                       1: o_wr_data_ahb = source_greater_reg[31:16];
                       default: o_wr_data_ahb = 0;
                    endcase
					end else if (i_src_data_width_reg == 'd32 && i_dist_data_width_reg == 'd8)begin
					if (counter_main>0) begin
					 case (counter_2)
					   0: o_wr_data_ahb = source_greater_reg[7:0];
                       1: o_wr_data_ahb = source_greater_reg[15:8];
					   2: o_wr_data_ahb = source_greater_reg[23:16];
					   3: o_wr_data_ahb = source_greater_reg[31:24];
					     default: o_wr_data_ahb = 0;
                    endcase
					end else begin
					 case (counter_2)
                       0: o_wr_data_ahb = source_greater_reg[7:0];
                       2: o_wr_data_ahb = source_greater_reg[15:8];
					   3: o_wr_data_ahb = source_greater_reg[23:16];
					   4: o_wr_data_ahb = source_greater_reg[31:24];
                       default: o_wr_data_ahb = 0;
                    endcase
					end
					end else if (i_src_data_width_reg == 'd16 && i_dist_data_width_reg == 'd8 )begin
				    case (counter_2)
                       0: o_wr_data_ahb = source_greater_reg[7:0];
                       1: o_wr_data_ahb = source_greater_reg[15:8];
					  
                       default: o_wr_data_ahb = 0;
                    endcase
					end else begin
					  o_wr_data_ahb = 0;
					end
				
					 counter_2 = counter_2 + 1;
					 end else begin 
                      o_valid_ahb =0;

                      end					 
	 
		if (i_src_addr_type_config && i_dist_addr_type_config) begin
	         next_state = state_2_3 ;
		 end else if (i_src_addr_type_config && !i_dist_addr_type_config ) begin
		     next_state = state_3_3 ;
		 end else if (!i_src_addr_type_config && i_dist_addr_type_config) begin
		     next_state = state_4_3 ;
	     end else if (!i_src_addr_type_config && !i_dist_addr_type_config) begin
		     next_state = state_5_3 ;	
		 end
		
		end
	///////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////
	state_3: begin
	
	 if (i_ready_ahb) begin
	    if (!i_rd_valid_ahb) begin
			  o_addr_ahb = i_src_addr_reg;
		      o_rd0_wr1_ahb =0;
              o_valid_ahb = 1;
		 end else if (i_rd_valid_ahb) begin
			  o_rd0_wr1_buff = 1;
              o_valid_buff = 1;
              o_data_buff = i_rd_data_ahb ;
			  o_addr_ahb = i_src_addr_reg;
		      o_rd0_wr1_ahb =0;
              o_valid_ahb = 1;
		 end else begin 
		      o_valid_buff = 0;
		 end	 
	end else begin
		  o_valid_ahb = 0;
	      o_valid_buff = 0;
    end	   
		   
         if (!i_ready_ahb) begin  
		     next_state = state_3 ;
         end else if (!i_rd_valid_ahb && counter_main < i_total_trans_reg && !chunk_indecate ) begin
	         next_state = state_3_2 ;
	    
         end else if (i_rd_valid_ahb && counter_main < i_total_trans_reg && !chunk_indecate ) begin
	        next_state = state_3_2 ;
			
	     end else if (counter_main > i_total_trans_reg && i_rd_valid_ahb && !chunk_indecate) begin
		     next_state = state_3_3 ;
			 counter_main = 0;	
			 
	     end else if (!i_rd_valid_ahb && counter_main < i_total_trans_reg && chunk_indecate ) begin 
	         next_state = state_3_2 ;
			 
	     end else if ( (((counter_chunck * BUFFER_DEPTH) + counter_main) == i_total_trans_reg) && chunk_indecate ) begin 
	          next_state = state_3_3 ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;
		
		 end else if (i_rd_valid_ahb && counter_main < BUFFER_DEPTH && chunk_indecate) begin
		     next_state = state_3_2 ;
			 
		 end else if (counter_main > BUFFER_DEPTH && i_rd_valid_ahb && chunk_indecate) begin
		     next_state = state_3_3 ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;		 
		 end else begin
         	next_state = state_3_3 ;	
			 counter_main = 0;	
		    counter_chunck = counter_chunck +1;		 
         end	
	end
	state_3_2: begin
	     if (i_ready_ahb) begin    
			  if (i_rd_valid_ahb) begin
		      o_rd0_wr1_buff = 1;
              o_valid_buff = 1;
              o_data_buff = i_rd_data_ahb ;
			  counter_main = counter_main + 1;
			  
			  o_addr_ahb = i_src_addr_reg;
		      o_rd0_wr1_ahb =0;
              o_valid_ahb = 1;
			 end else begin 
		      o_valid_buff = 0;
		     end	
		end else begin
		    o_valid_ahb = 0;
			o_valid_buff = 0;
		end	 	 
		 
	     if (!i_ready_ahb) begin  
		     next_state = state_3_2 ;
			 
         end else if (i_rd_valid_ahb && counter_main < i_total_trans_reg && !chunk_indecate ) begin
	         next_state = state_3;
			 
	     end else if (counter_main > i_total_trans_reg && i_rd_valid_ahb && !chunk_indecate) begin
		     next_state = state_3_3 ;
			 counter_main = 0;	
			 
		 end else if (i_rd_valid_ahb && counter_main < BUFFER_DEPTH && chunk_indecate) begin
		     next_state = state_3 ;
			 
		 end else if ( (((counter_chunck-1) * BUFFER_DEPTH) + counter_main) == i_total_trans_reg && chunk_indecate ) begin 
	          next_state = state_3_3 ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;
			 
		end else if (counter_main > BUFFER_DEPTH && i_rd_valid_ahb && chunk_indecate) begin
		     next_state = state_3_3 ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;		 
		 end else begin
         	next_state = state_3_3 ;	
			if (less_indecate) begin
			 counter_main = 0;	
			 end
         end	
	end
    state_3_3: begin
	  if (i_ready_ahb) begin 
	         o_rd0_wr1_buff =0;
          	 o_valid_buff=1;
		 if (data_width_differ==4 && counter_2)begin
			o_valid_buff=0;
			end 
			
			 if (i_valid_buff || (!i_valid_buff&&counter_2)) begin
			    if(!last_flag)
			     o_addr_ahb = i_dist_addr_reg ;
              
                 o_valid_ahb =1;
                 o_rd0_wr1_ahb =1;
				  if (i_src_data_width_reg > i_dist_data_width_reg) begin
				    if (i_src_data_width_reg == 'd32 && i_dist_data_width_reg == 'd16 )begin
				    case (counter_2)
                       0: o_wr_data_ahb = source_greater_reg[15:0];
                       1: o_wr_data_ahb = source_greater_reg[31:16];
                       default: o_wr_data_ahb = 0;
                    endcase
					end else if (i_src_data_width_reg == 'd32 && i_dist_data_width_reg == 'd8)begin
					
					 if (counter_main>0) begin
					 case (counter_2)
					   0: o_wr_data_ahb = source_greater_reg[7:0];
                       1: o_wr_data_ahb = source_greater_reg[15:8];
					   2: o_wr_data_ahb = source_greater_reg[23:16];
					   3: o_wr_data_ahb = source_greater_reg[31:24];
					     default: o_wr_data_ahb = 0;
                    endcase
					end else begin
					 case (counter_2)
                       0: o_wr_data_ahb = source_greater_reg[7:0];
                       2: o_wr_data_ahb = source_greater_reg[15:8];
					   3: o_wr_data_ahb = source_greater_reg[23:16];/////////
					   4: o_wr_data_ahb = source_greater_reg[31:24];
                       default: o_wr_data_ahb = 0;
                    endcase
					end
			
					end else if (i_src_data_width_reg == 'd16 && i_dist_data_width_reg == 'd8 )begin
				    case (counter_2)
                       0: o_wr_data_ahb = source_greater_reg[7:0];
                       1: o_wr_data_ahb = source_greater_reg[15:8];
                       default: o_wr_data_ahb = 0;
                    endcase
					end else begin
					  o_wr_data_ahb = 0;
					end

					 counter_2 = counter_2 + 1;
					 counter_reg = counter_main ; 
					 if ((counter_2 == data_width_differ) || (data_width_differ==4 && counter_2==5))begin 
					     i_dist_addr_reg = i_dist_addr_reg + 4;
					     counter_main = counter_main +1;
						 counter_2 = 0;
						 o_valid_buff=1;
					 end else begin
					     counter_main = counter_reg ; 
                        end					
						 
				 end else begin
				     i_dist_addr_reg = i_dist_addr_reg + 4;
				     o_wr_data_ahb = i_data_buff;
					 counter_main = counter_main +1;
					 if (counter_main == 'd2) begin
					     i_dist_addr_reg = i_dist_addr_reg - 4;
						  
						 end
				 end
			 end else begin 
                   o_valid_ahb =0;
				    if( counter_main  && last_flag) 
				    o_valid_ahb =1;
             end

		end else begin
		    o_valid_ahb = 0;
			o_valid_buff = 0;
		 end	 		 
	
	/////////////////////////////////////////////////////////////////////////////////////////	
		 if (!i_ready_ahb) begin  
		     next_state = state_3_3 ;
         end else if( counter_main < i_total_trans_reg && !chunk_indecate && last_flag) begin	
		     next_state = state_6  ;
		 
		end else if (counter_main == i_total_trans_reg  && !chunk_indecate && last_flag) begin
		    next_state = finish ;
			 o_valid_buff=0;
			 counter_main = 0;	
			 
		 end else if ( (((counter_chunck-1) * BUFFER_DEPTH) + counter_main) > i_total_trans_reg && chunk_indecate && last_flag) begin 
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;

		 end else if ( counter_main < BUFFER_DEPTH && chunk_indecate && last_flag) begin
		     next_state = state_6 ;
			 
		end else if (counter_main == BUFFER_DEPTH && chunk_indecate && last_flag) begin
		     next_state = finish ;
			  o_valid_buff=0;
			 counter_main = 0;	
	
	     end else if (i_valid_buff && counter_main < i_total_trans_reg && !chunk_indecate ) begin
	         next_state = state_3_3  ;
		  end else if (counter_main > i_total_trans_reg && i_valid_buff && !chunk_indecate) begin
		     next_state = finish ;
			  o_valid_buff=0;
			 counter_main = 0;	
 
		 end else if ( (((counter_chunck-1) * BUFFER_DEPTH) + counter_main) > i_total_trans_reg && chunk_indecate ) begin 
	          next_state = finish ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;
			 
		 end else if (i_valid_buff && counter_main < BUFFER_DEPTH && chunk_indecate) begin
		     next_state = state_3_3 ;
			 
		end else if (counter_main > BUFFER_DEPTH && i_valid_buff && chunk_indecate) begin
		     next_state = finish ;
			  o_valid_buff=0;
			 counter_main = 0;	 

		 end else begin
         	next_state = state_3_3 ;	
         end	
		 
	end
	state_4: begin
	 if (i_ready_ahb) begin 
	          if (!i_rd_valid_ahb) begin
			  
			  o_addr_ahb = i_src_addr_reg;
			  i_src_addr_reg = i_src_addr_reg + 4 ;
		      o_rd0_wr1_ahb =0;
              o_valid_ahb = 1;
			 end else if (i_rd_valid_ahb) begin
			   o_rd0_wr1_buff = 1;
              o_valid_buff = 1;
              o_data_buff = i_rd_data_ahb ;
			  if (counter_main == BUFFER_DEPTH  && chunk_indecate ) begin 
			    i_src_addr_reg = i_src_addr_reg - 4 ;
				end
			 end else begin 
		      o_valid_buff = 0;
		     end
     end else begin
		    o_valid_ahb = 0;
		    o_valid_buff = 0;
	 end	 				 
			 
         if (!i_ready_ahb) begin  
		     next_state = state_4 ;
         end else if (!i_rd_valid_ahb && counter_main < i_total_trans_reg && !chunk_indecate ) begin
	         next_state = state_4_2 ;
	    
         end else if (i_rd_valid_ahb && counter_main < i_total_trans_reg && !chunk_indecate ) begin
	        next_state = state_4_2 ;
			
	     end else if (counter_main > i_total_trans_reg && i_rd_valid_ahb && !chunk_indecate) begin
		     next_state = state_4_3 ;
			 counter_main = 0;	
			 
		 end else if (!i_rd_valid_ahb && counter_main < i_total_trans_reg && chunk_indecate ) begin 
	         next_state = state_4_2 ;
			 
	     end else if ( (((counter_chunck * BUFFER_DEPTH) + counter_main) == i_total_trans_reg) && chunk_indecate ) begin 
	          next_state = state_4_3 ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;	 
		
		 end else if (i_rd_valid_ahb && counter_main < BUFFER_DEPTH && chunk_indecate) begin
		     next_state = state_4_2 ;
			 
		 end else if (counter_main > BUFFER_DEPTH && i_rd_valid_ahb && chunk_indecate) begin
		     next_state = state_4_3 ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;		 
		 end else begin
         	next_state = state_4_3 ;	
			 counter_main = 0;	
            counter_chunck = counter_chunck +1;		 
         end	
		 
	end
	state_4_2: begin
	 if (i_ready_ahb) begin 
	         if (i_rd_valid_ahb) begin
		      o_rd0_wr1_buff = 1;
              o_valid_buff = 1;
              o_data_buff = i_rd_data_ahb ;
			  counter_main = counter_main + 1;
			  
			  o_addr_ahb = i_src_addr_reg;
			  i_src_addr_reg = i_src_addr_reg + 4 ;
		      o_rd0_wr1_ahb =0;
              o_valid_ahb = 1;
			 end else begin 
		      o_valid_buff = 0;
		     end	
     end else begin
		    o_valid_ahb = 0;
			o_valid_buff = 0;
	 end	 				 
			 
		 if (!i_ready_ahb) begin  
		     next_state = state_4_2 ;
			 
         end else if (i_rd_valid_ahb && counter_main < i_total_trans_reg && !chunk_indecate ) begin
	         next_state = state_4 ;
			
	     end else if (counter_main > i_total_trans_reg && i_rd_valid_ahb && !chunk_indecate) begin
		     next_state = state_4_3 ;
			 counter_main = 0;	
		
		 end else if (i_rd_valid_ahb && counter_main < BUFFER_DEPTH && chunk_indecate) begin
		     next_state = state_4 ;
		
	 
		 end else if ( (((counter_chunck-1) * BUFFER_DEPTH) + counter_main) == i_total_trans_reg && chunk_indecate ) begin 
	          next_state = state_4_3 ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;
			 
		 end else if (counter_main > BUFFER_DEPTH && i_rd_valid_ahb && chunk_indecate) begin
		     next_state = state_4_3 ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;		 
		 end else begin
         	next_state = state_4_3 ;	
			if (less_indecate) begin
			 counter_main = 0;	
			 end

         end	
	end
	state_4_3: begin
	 if (i_ready_ahb) begin 
	        o_rd0_wr1_buff =0;
            	 o_valid_buff=1;
		 if (data_width_differ==4 && counter_2)begin
			o_valid_buff=0;
			end 

			if (i_valid_buff || (!i_valid_buff && counter_2) ) begin
			    if(!last_flag)
			     o_addr_ahb = i_dist_addr_reg ;
				 
                 o_valid_ahb =1;
                 o_rd0_wr1_ahb =1;
				 
				 if (i_src_data_width_reg > i_dist_data_width_reg) begin
				    if (i_src_data_width_reg == 'd32 && i_dist_data_width_reg == 'd16 )begin
				    case (counter_2)
                       0: o_wr_data_ahb = source_greater_reg[15:0];
                       1: o_wr_data_ahb = source_greater_reg[31:16];
                       default: o_wr_data_ahb = 0;
                    endcase
					end else if (i_src_data_width_reg == 'd32 && i_dist_data_width_reg == 'd8)begin
					
					if (counter_main>0) begin
					 case (counter_2)
					   0: o_wr_data_ahb = source_greater_reg[7:0];
                       1: o_wr_data_ahb = source_greater_reg[15:8];
					   2: o_wr_data_ahb = source_greater_reg[23:16];
					   3: o_wr_data_ahb = source_greater_reg[31:24];
					     default: o_wr_data_ahb = 0;
                    endcase
					end else begin
					 case (counter_2)
                       0: o_wr_data_ahb = source_greater_reg[7:0];
                       2: o_wr_data_ahb = source_greater_reg[15:8];
					   3: o_wr_data_ahb = source_greater_reg[23:16];/////////
					   4: o_wr_data_ahb = source_greater_reg[31:24];
                       default: o_wr_data_ahb = 0;
                    endcase
					end
					end else if (i_src_data_width_reg == 'd16 && i_dist_data_width_reg == 'd8 )begin
				    case (counter_2)
                       0: o_wr_data_ahb = source_greater_reg[7:0];
                       1: o_wr_data_ahb = source_greater_reg[15:8];
                       default: o_wr_data_ahb = 0;
                    endcase
					end else begin
					  o_wr_data_ahb = 0;
					end
			
					 counter_2 = counter_2 + 1;
					 counter_reg = counter_main ; 

					  if ((counter_2 == data_width_differ) || (data_width_differ==4 && counter_2==5))begin 
					     counter_main = counter_main +1;
						 counter_2 = 0;
	                     o_valid_buff=1;
					 end else begin
					     counter_main = counter_reg ; 
                        end					
						 
				 end else begin
				     o_wr_data_ahb = i_data_buff;
					 counter_main = counter_main +1;
				 
				 end
			end else begin 
                   o_valid_ahb =0;
				   if( counter_main  && last_flag) 
				    o_valid_ahb =1;
             end			  
		end else begin
		    o_valid_ahb = 0;
			o_valid_buff = 0;
	     end	 	
		  
		  
		  /////////////////////////////////////////////////////////////////////////////////////////	
		if (!i_ready_ahb) begin  
		     next_state = state_4_3 ;
         end else if( counter_main < i_total_trans_reg && !chunk_indecate && last_flag) begin	
		     next_state = state_6  ;
		 
		end else if (counter_main == i_total_trans_reg  && !chunk_indecate && last_flag) begin
		    next_state = finish ;
			 o_valid_buff=0;
			 counter_main = 0;	
			 
		 end else if ( (((counter_chunck-1) * BUFFER_DEPTH) + counter_main) > i_total_trans_reg && chunk_indecate && last_flag) begin
	          next_state = finish ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;

		 end else if ( counter_main < BUFFER_DEPTH && chunk_indecate && last_flag) begin
		     next_state = state_6 ;
			 
		end else if (counter_main == BUFFER_DEPTH && chunk_indecate && last_flag) begin
		     next_state = finish ;
			  o_valid_buff=0;
			 counter_main = 0;	
		
		 end else if (i_valid_buff && counter_main < i_total_trans_reg && !chunk_indecate ) begin
	         next_state = state_4_3  ; 
			 
		  end else if (counter_main > i_total_trans_reg && i_valid_buff && !chunk_indecate) begin
		     next_state = finish ;
			 o_valid_buff=0;
			 counter_main = 0;	

		 end else if ( (((counter_chunck-1) * BUFFER_DEPTH) + counter_main) > i_total_trans_reg && chunk_indecate ) begin 
	          next_state = finish ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;
			 
		 end else if (i_valid_buff && counter_main < BUFFER_DEPTH && chunk_indecate) begin
		     next_state = state_4_3 ;
			 
		end else if (counter_main > BUFFER_DEPTH && i_valid_buff && chunk_indecate) begin
		     next_state = finish ;
			 o_valid_buff=0;
			 counter_main = 0;	 

		 end else begin
         	next_state = state_4_3 ;	
         end	
		  
	end
	
    state_5: begin
	
	 if (i_ready_ahb) begin 
	          if (!i_rd_valid_ahb) begin
			  
			  o_addr_ahb = i_src_addr_reg;
			  i_src_addr_reg = i_src_addr_reg + 4 ;
			 
		      o_rd0_wr1_ahb =0;
              o_valid_ahb = 1;
			 end else if (i_rd_valid_ahb) begin
			   o_rd0_wr1_buff = 1;
              o_valid_buff = 1;
              o_data_buff = i_rd_data_ahb ;
            if (counter_main == BUFFER_DEPTH  && chunk_indecate ) begin
			    i_src_addr_reg = i_src_addr_reg - 4 ;
				end
			 end else begin 
		      o_valid_buff = 0;
		     end	 
			 
	end else begin
		    o_valid_ahb = 0;
			o_valid_buff = 0;
	end	 	
		   
         if (!i_ready_ahb) begin  
		     next_state = state_5;
         end else if (!i_rd_valid_ahb && counter_main < i_total_trans_reg && !chunk_indecate ) begin
	         next_state = state_5_2 ;
	     
         end else if (i_rd_valid_ahb && counter_main < i_total_trans_reg && !chunk_indecate ) begin
	        next_state = state_5_2 ;
	     end else if (counter_main > i_total_trans_reg && i_rd_valid_ahb && !chunk_indecate) begin
		     next_state = state_5_3 ;
			 counter_main = 0;	

         end else if (!i_rd_valid_ahb && counter_main < i_total_trans_reg && chunk_indecate ) begin 
	         next_state = state_5_2 ;
			 
	     end else if ( (((counter_chunck * BUFFER_DEPTH) + counter_main) == i_total_trans_reg) && chunk_indecate ) begin 
	          next_state = state_5_3 ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;	 
	
		 end else if (i_rd_valid_ahb && counter_main < BUFFER_DEPTH && chunk_indecate) begin
		     next_state = state_5_2 ;
			 
	   	 end else if (counter_main > BUFFER_DEPTH && i_rd_valid_ahb && chunk_indecate) begin
	 	     next_state = state_5_3 ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;		 
		 end else begin
         	next_state = state_5_3 ;	
			 counter_main = 0;	
            counter_chunck = counter_chunck +1;		 
         end	
	end
	state_5_2: begin
	 if (i_ready_ahb) begin 
	          if (i_rd_valid_ahb) begin
		      o_rd0_wr1_buff = 1;
              o_valid_buff = 1;
              o_data_buff = i_rd_data_ahb ;
			  counter_main = counter_main + 1;
			  
			  o_addr_ahb = i_src_addr_reg;
			  i_src_addr_reg = i_src_addr_reg + 4 ;
		      o_rd0_wr1_ahb =0;
              o_valid_ahb = 1;
			 end else begin 
		      o_valid_buff = 0;
		     end	  
	 end else begin
		    o_valid_ahb = 0;
			o_valid_buff = 0;
      end	 	

         if (!i_ready_ahb) begin  
		     next_state = state_5_2 ;
         end else if (i_rd_valid_ahb && counter_main < i_total_trans_reg && !chunk_indecate ) begin
	         next_state = state_5 ;
	     end else if (counter_main > i_total_trans_reg && i_rd_valid_ahb && !chunk_indecate) begin
		     next_state = state_5_3 ;
			 counter_main = 0;	
		
		 end else if (i_rd_valid_ahb && counter_main < BUFFER_DEPTH && chunk_indecate) begin
		     next_state = state_5 ;
			 
		end else if ( (((counter_chunck-1) * BUFFER_DEPTH) + counter_main) == i_total_trans_reg && chunk_indecate ) begin
	          next_state = state_5_3 ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;
			 
		end else if (counter_main > BUFFER_DEPTH && i_rd_valid_ahb && chunk_indecate) begin
		     next_state = state_5_3 ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;		 
		 end else begin
         	next_state = state_5_3 ;	
            if (less_indecate) begin 
			 counter_main = 0;	
			 end
         end	
	end
	state_5_3: begin
	
	 if (i_ready_ahb) begin 
	         o_rd0_wr1_buff =0;
			 o_valid_buff=1;
		 if (data_width_differ==4 && counter_2)begin
			o_valid_buff=0;
			end 
			
			 if (i_valid_buff || (!i_valid_buff&&counter_2)) begin
			    if(!last_flag)
			     o_addr_ahb = i_dist_addr_reg ;
				 
                 o_valid_ahb =1;
                 o_rd0_wr1_ahb =1;
				  if (i_src_data_width_reg > i_dist_data_width_reg) begin
				    if (i_src_data_width_reg == 'd32 && i_dist_data_width_reg == 'd16 )begin
				    case (counter_2)
                       0: o_wr_data_ahb = source_greater_reg[15:0];
                       1: o_wr_data_ahb = source_greater_reg[31:16];
                       default: o_wr_data_ahb = 0;
                    endcase
					end else if (i_src_data_width_reg == 'd32 && i_dist_data_width_reg == 'd8)begin
					if (counter_main>0) begin 
					 case (counter_2)
					   0: o_wr_data_ahb = source_greater_reg[7:0];
                       1: o_wr_data_ahb = source_greater_reg[15:8];
					   2: o_wr_data_ahb = source_greater_reg[23:16];
					   3: o_wr_data_ahb = source_greater_reg[31:24];
					     default: o_wr_data_ahb = 0;
                    endcase
					end else begin
					 case (counter_2) 
                       0: o_wr_data_ahb = source_greater_reg[7:0];
                       2: o_wr_data_ahb = source_greater_reg[15:8];
					   3: o_wr_data_ahb = source_greater_reg[23:16];/////////
					   4: o_wr_data_ahb = source_greater_reg[31:24];
                       default: o_wr_data_ahb = 0;
                    endcase
					end
					end else if (i_src_data_width_reg == 'd16 && i_dist_data_width_reg == 'd8 )begin
				    case (counter_2)
                       0: o_wr_data_ahb = source_greater_reg[7:0];
                       1: o_wr_data_ahb = source_greater_reg[15:8];
                       default: o_wr_data_ahb = 0;
                    endcase
					end else begin
					  o_wr_data_ahb = 0;
					end
				
					 counter_2 = counter_2 + 1;
					 counter_reg = counter_main ; 
					 
					 if ((counter_2 == data_width_differ) || (data_width_differ==4 && counter_2==5))begin 
					     i_dist_addr_reg = i_dist_addr_reg + 4;
					     counter_main = counter_main +1;
						 counter_2 = 0;
						 o_valid_buff=1; 
					 end else begin
					     counter_main = counter_reg ; 
                        end					
						 
				 end else begin
				     i_dist_addr_reg = i_dist_addr_reg + 4;
				     o_wr_data_ahb = i_data_buff;
					 counter_main = counter_main +1;

					  if (counter_main == 'd2) begin
					     i_dist_addr_reg = i_dist_addr_reg - 4;
						  
						 end
				 
				 end
			 end else begin 
                   o_valid_ahb =0;
				    if( counter_main  && last_flag) 
				    o_valid_ahb =1;
             end	

     end else begin
		    o_valid_ahb = 0;
			o_valid_buff = 0;
	 end	 				 
/////////////////////////////////////////////////////////////////////////////////////////	
		if (!i_ready_ahb) begin  
		     next_state = state_5_3 ;
         end else if( counter_main < i_total_trans_reg && !chunk_indecate && last_flag) begin	
		     next_state = state_6  ;
		 
	     end else if (counter_main == i_total_trans_reg  && !chunk_indecate && last_flag) begin
		    next_state = finish ;
			 o_valid_buff=0;
			 counter_main = 0;	
			 
		 end else if ( (((counter_chunck-1) * BUFFER_DEPTH) + counter_main) > i_total_trans_reg && chunk_indecate && last_flag) begin 
	          next_state = finish ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;

		 end else if ( counter_main < BUFFER_DEPTH && chunk_indecate && last_flag) begin
		     next_state = state_6 ;
			 
		 end else if (counter_main == BUFFER_DEPTH && chunk_indecate && last_flag) begin
		     next_state = finish ;
			  o_valid_buff=0;
			 counter_main = 0;	
			
			 
          end else if (i_valid_buff && counter_main < i_total_trans_reg && !chunk_indecate ) begin
	        next_state = state_5_3  ;
		  end else if (counter_main > i_total_trans_reg && i_valid_buff && !chunk_indecate) begin
		     next_state = finish ;
			 o_valid_buff=0;
			 counter_main = 0;	
	
		 end else if ( (((counter_chunck-1) * BUFFER_DEPTH) + counter_main) > i_total_trans_reg && chunk_indecate ) begin 
	          next_state = finish ;
			 counter_main = 0;	
             counter_chunck = counter_chunck +1;
	
		 end else if (i_valid_buff && counter_main < BUFFER_DEPTH && chunk_indecate) begin
		     next_state = state_5_3 ;
		 end else if (counter_main > BUFFER_DEPTH && i_valid_buff && chunk_indecate) begin
		     next_state = finish ;
			 o_valid_buff=0;
			 counter_main = 0;	 

		 end else begin
         	next_state = state_5_3 ;	
         end			 
	end
	finish: begin
	       o_valid_ahb =0;
           o_valid_buff = 0;
	     if (counter_chunck > chunk_reg && chunk_indecate) begin
		    	o_trig_end = 1;
		 end else if (!chunk_indecate) begin
		    	o_trig_end = 1;
         end else begin 
                o_trig_end = 0;
         end		
		 
		 
        if (counter_chunck < chunk_reg) begin
	         next_state = state_1  ;
			
		 end else if (!chunk_indecate) begin
         	 next_state = idle ;	
			 counter_chunck = 0;
         end else begin 
             next_state = idle ;	
         end		 		 
	    
	end 
	default: begin
         i_src_addr_reg = 'b0;
          i_dist_addr_reg= 'b0;
          i_src_data_width_reg= 'b0;
          i_dist_data_width_reg= 'b0;
          i_total_trans_reg= 'b0;
          data_width_differ= 'b0;
          chunk_reg= 'b0;
          chunk_indecate= 'b0;
		  counter_main= 'b0;
          counter_chunck= 'b0;
          counter_internal= 'b0;
		  counter_2= 'b0;
          counter_reg= 'b0;
          source_greater_reg= 'b0;
          differ_width_flag= 'b0 ;
		  o_rd0_wr1_buff= 'b0;
          o_valid_buff= 'b0;
          o_data_buff= 'b0;
          o_wr_data_ahb= 'b0;
          o_addr_ahb= 'b0;
          o_valid_ahb= 'b0;
          o_rd0_wr1_ahb= 'b0;
          o_trig_end= 'b0;
		 
		  next_state = idle ;	
	end
endcase
end


endmodule
