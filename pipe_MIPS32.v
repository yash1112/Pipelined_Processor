module pipe_MIPS32(clk1, clk2);
	input clk1, clk2;							//Two phase clock
	
	reg[31:0] PC, IF_ID_IR, IF_ID_NPC;										//Latches at IF ID Interface
	reg[31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;		//Latches at ID EX Interface
	reg[31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;						//Latches at EX MEM Interface
	reg		 EX_MEM_cond;
	reg[31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;						//Latches at MEM WB Interface
	
	reg[2:0]  ID_EX_type, EX_MEM_type, MEM_WB_type;						//Latch to store type of instruction
	
	reg[31:0] Reg [0:31]; 					// Register Bank (32x32)
	reg[31:0] Mem [0:1023];					// 1024 x 32 Memory
	
	parameter ADD = 6'b000000, SUB = 6'b000001, AND = 6'b000010, OR = 6'b000011,
				 SLT = 6'b000100, MUL = 6'b000101, HLT = 6'b111111, LW = 6'b001000, 
				 SW = 6'b001001, ADDI = 6'b001010, SUBI = 6'b001011, SLTI = 6'b001100,
				 BNEQZ = 6'b001101, BEQZ = 6'b001110;														// Opcodes
				 
	parameter RR_ALU = 3'b000, RM_ALU = 3'b001, LOAD = 3'b010, STORE = 3'b011,				
				 BRANCH = 3'b100, HALT = 3'b101;																// For type of operation
				 
	reg HALTED;											// Set after HLT instruction is completed (in WB stage)		
	reg TAKEN_BRANCH;									// Required to disable instructions after branch 
				 
				 
	// IF Stage
	
	always @(posedge clk1)
		if (HALTED == 0)								// If HALTED is set we don't fetch next instruction
		begin 
			if (((EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_cond == 1)) ||
				 ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_cond == 0)))				//If branch condition is true
				begin
					IF_ID_IR 		<= #2 Mem[EX_MEM_ALUOut];
					//TAKEN_BRANCH 	<= #2 1'b1;						// This resolves issue of multiple assignment and also gives proper results (I don't know why?)
					IF_ID_NPC		<= #2 EX_MEM_ALUOut + 1;
					PC					<= #2 EX_MEM_ALUOut + 1;
				end
			else
				begin
					IF_ID_IR			<= #2 Mem[PC];
					IF_ID_NPC 		<=	#2 PC + 1;
					PC					<= #2 PC + 1;
				end
		end
		
	// ID Stage
	
	always @(posedge clk2)
		if (HALTED == 0)								// If HALTED is set no need
		begin
			if (IF_ID_IR[25:21] == 5'b00000)  ID_EX_A <= 0 ;			//In case of R0
			else ID_EX_A  <= #2 Reg[IF_ID_IR[25:21]];
			
			if (IF_ID_IR[20:16] == 5'b00000)  ID_EX_B <= 0 ;			//In case of R0
			else ID_EX_B  <= #2 Reg[IF_ID_IR[20:16]];
		
			ID_EX_NPC <= #2 IF_ID_NPC;
			ID_EX_IR  <= #2 IF_ID_IR;
			ID_EX_Imm <= #2 {{16{IF_ID_IR[15]}}, {IF_ID_IR[15:0]}};
			
			case (IF_ID_IR[31:26])
				ADD, SUB, AND, OR, SLT, MUL:    ID_EX_type   <=  #2 RR_ALU;
				ADDI, SUBI, SLTI:					  ID_EX_type   <=  #2 RM_ALU;
				LW:									  ID_EX_type   <=  #2 LOAD;
				SW: 									  ID_EX_type   <=  #2 STORE;
				BNEQZ, BEQZ:						  ID_EX_type   <=  #2 BRANCH;
				HLT:									  ID_EX_type   <=  #2 HALT;
				default:                        ID_EX_type   <=  #2 HALT;       // Represents invalid Opcode
			endcase
		end
		
	//EX Stage
	
	always @(posedge clk1)
	if (HALTED == 0)
	begin
		EX_MEM_type  <= #2 ID_EX_type;
		EX_MEM_IR	 <= #2 ID_EX_IR;
		TAKEN_BRANCH <= #2 1'b0;						  // Error mulitple assignment in same clock
		
		case (ID_EX_type)									  //Case for different type of instructions
			RR_ALU: begin
							case (ID_EX_IR[31:26])       //Case for various RR operations
								ADD:    EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_B;
								SUB:    EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_B;
								AND:    EX_MEM_ALUOut <= #2 ID_EX_A & ID_EX_B;
								OR:     EX_MEM_ALUOut <= #2 ID_EX_A | ID_EX_B;
								SLT:    EX_MEM_ALUOut <= #2 ID_EX_A < ID_EX_B;
								MUL:    EX_MEM_ALUOut <= #2 ID_EX_A * ID_EX_B;
								default:EX_MEM_ALUOut <= #2 32'hxxxxxxxx;
							endcase
					  end

			RM_ALU: begin
							case (ID_EX_IR[31:26])			//For various RM operations
								ADDI:   EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;
								SUBI:   EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_Imm;
								SLTI:   EX_MEM_ALUOut <= #2 ID_EX_A < ID_EX_Imm;
								default:EX_MEM_ALUOut <= #2 32'hxxxxxxxx;
							endcase
					  end
					  
			LOAD, STORE:
					  begin
										  EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;
										  EX_MEM_B      <= #2 ID_EX_B;
					  end
					  
			BRANCH: 
					  begin
										  EX_MEM_ALUOut <= #2 ID_EX_NPC + ID_EX_Imm;
										  EX_MEM_cond   <= #2 (ID_EX_A == 0);
					  end
		endcase
	end
	
	//MEM Stage
	always @(posedge clk2)
		if(HALTED == 0)
		begin
			MEM_WB_type <= #2 EX_MEM_type;
			MEM_WB_IR   <= #2 EX_MEM_IR;
			
			case (EX_MEM_type)
				RR_ALU, RM_ALU:
									MEM_WB_ALUOut  <= #2 EX_MEM_ALUOut;
				LOAD:
									MEM_WB_LMD		<= #2 Mem[EX_MEM_ALUOut];
				STORE:
									if (TAKEN_BRANCH == 0)     // Disable Write
										Mem[EX_MEM_ALUOut]   <= #2 EX_MEM_B;
			endcase
		end
		
	//WB Stage
	always @(posedge clk1)
		begin
			if (TAKEN_BRANCH == 0)						// Disable write if branch taken
				case (MEM_WB_type)
					RR_ALU:			Reg[MEM_WB_IR[15:11]]  <= #2 MEM_WB_ALUOut;		//rd
					
					RM_ALU:			Reg[MEM_WB_IR[20:16]]  <= #2 MEM_WB_ALUOut;		//rt
					
					LOAD:			   Reg[MEM_WB_IR[20:16]]  <= #2 MEM_WB_LMD;			//rt
					
					HALT:				HALTED <= #2 1'b1;
				endcase
		end
		
		
endmodule
							
						