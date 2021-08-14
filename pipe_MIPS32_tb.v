module  pipe_MIPS32_tb;
	
	reg clk1, clk2;
	integer k;
	
	pipe_MIPS32 mips (clk1, clk2);
	
	initial
		begin
			clk1 = 0; clk2 = 0;
			repeat(50)									// Generating two phase clock
				begin
					#5 clk1 = 1; #5 clk1 = 0;
					#5 clk2 = 1; #5 clk2 = 0;
				end
		end
	
/*---------------------------Example 1-----------------------------------------------	
	initial
		begin
			for (k = 0; k < 31; k=k+1)				// To initialze registers
				mips.Reg[k] = k;
			
			mips.Mem[0] = 32'h2801000a;         // ADDI R1, R0, 10
			mips.Mem[1] = 32'h28020014;         // ADDI R2, R0, 20
			mips.Mem[2] = 32'h28030019;         // ADDI R3, R0, 25
			mips.Mem[3] = 32'h0ce77800;         // OR   R7, R7, 17       // DUMMY
			mips.Mem[4] = 32'h0ce77800;         // OR   R7, R7, 17       // DUMMY
			mips.Mem[5] = 32'h00222000;         // ADD  R4, R1, R2
			mips.Mem[6] = 32'h0ce77800;         // OR   R7, R7, 17       // DUMMY
			mips.Mem[7] = 32'h00832800;         // ADD  R5, R4, R3
			mips.Mem[8] = 32'hfc000000;         // HLT
			
			mips.HALTED 		= 0;
			mips.PC     		= 0;
			mips.TAKEN_BRANCH = 0;
			
			#280
			for (k = 0; k < 6; k=k+1)
				$display ("R%1d - %2d", k, mips.Reg[k]);
		end
-----------------------------Example 1-----------------------------------------------*/

/*---------------------------Example 2-----------------------------------------------

	initial
		begin
			for (k = 0; k < 31; k=k+1)				// To initialze registers
				mips.Reg[k] = k;
			
			mips.Mem[0] = 32'h28010078;         // ADDI R1, R0, 120
			mips.Mem[1] = 32'h0ce77800;         // OR   R7, R7, 17		 //DUMMY
			mips.Mem[2] = 32'h20220000;         // LW   R2, 0(R1)
			mips.Mem[3] = 32'h0ce77800;         // OR   R7, R7, 17		 //DUMMY
			mips.Mem[4] = 32'h2842002d;         // ADDI R2, R2, 45       
			mips.Mem[5] = 32'h0ce77800;         // OR   R7, R7, 17		 //DUMMY
			mips.Mem[6] = 32'h24220001;         // SW   R2, 1(R1)      
			mips.Mem[7] = 32'hfc000000;         // HLT
			
			mips.Mem[120]      = 85;
			mips.HALTED 		= 0;
			mips.PC     		= 0;
			mips.TAKEN_BRANCH = 0;
			
			#500
			$display ("Mem[120]:  %4d \nMem[121]: %4d", mips.Mem[120], mips.Mem[121]);
		end
-----------------------------Example 2-----------------------------------------------*/

///*---------------------------Example 3-----------------------------------------------	
	initial
		begin
			for (k = 0; k < 31; k=k+1)				// To initialze registers
				mips.Reg[k] = k;
			
			mips.Mem[0] = 32'h280a00c8;         // ADDI R10, R0, 200
			mips.Mem[1] = 32'h28020001;         // ADDI R2,  R0, 1
			mips.Mem[2] = 32'h0ce77800;         // OR   R7, R7, 17       // DUMMY
			mips.Mem[3] = 32'h21430000;         // LW   R3, 0(R10)
			mips.Mem[4] = 32'h0ce77800;         // OR   R7, R7, 17       // DUMMY
			mips.Mem[5] = 32'h14431000;         // MUL  R2, R2, R3 -- LOOP
			mips.Mem[6] = 32'h2c630001;         // SUBI R3, R3, 1       
			mips.Mem[7] = 32'h0ce77800;         // OR   R7, R7, 17       // DUMMY       
			mips.Mem[8] = 32'h3460fffc;			// BNEQ R3, Loop      (-4 offset )(As PC already has next instr. address)
			mips.Mem[9] = 32'h2542fffe;			// SW R2, -2(R10)
			mips.Mem[10]= 32'hfc000000;         // HLT
			
			mips.Mem[200]     = 7; 					// To find factorial of 7
			mips.HALTED 		= 0;
			mips.PC     		= 0;
			mips.TAKEN_BRANCH = 0;
			
			#2000
			
			$display ("Mem[200]:  %4d \nMem[198]: %4d", mips.Mem[200], mips.Mem[198]);
		end
	
	initial
		begin
			$monitor ("R2:  %4d", mips.Reg[2]);
		end
//-----------------------------Example 3-----------------------------------------------*/

endmodule
			
			