module SP_pipeline(
	// INPUT SIGNAL
	clk,
	rst_n,
	in_valid,
	inst,
	mem_dout,
	// OUTPUT SIGNAL
	out_valid,
	inst_addr,
	mem_wen,
	mem_addr,
	mem_din
);



//------------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//------------------------------------------------------------------------

input                    clk, rst_n, in_valid;
input             [31:0] inst;
input  signed     [31:0] mem_dout;
output reg               out_valid;
output reg        [31:0] inst_addr;
output reg               mem_wen;
output reg        [11:0] mem_addr;
output reg signed [31:0] mem_din;


//------------------------------------------------------------------------
//   DECLARATION
//------------------------------------------------------------------------

// REGISTER FILE, DO NOT EDIT THE NAME.
reg	signed [31:0] r [0:31]; 

reg [31:0] next_pc, pc_new, PC_fs, PC_ss, PC_ts, b_addr, b_addr_fs, b_addr_ss, b_addr_ss_comb;

reg [31:0] RegDst, RegDst_fs, RegDst_ss, RegDst_ts;
reg [31:0] branch, branch_fs, branch_ss, branch_ts;
reg [31:0] MRead, MRead_fs, MRead_ss, MRead_ts;
reg [31:0] MtoReg, MtoReg_fs, MtoReg_ss, MtoReg_ts;
reg [31:0] MWrite, MWrite_fs, MWrite_ss, MWrite_ts;
reg [31:0] ALUSrc, ALUSrc_fs, ALUSrc_ss, ALUSrc_ts;
reg [31:0] RWrite, RWrite_fs, RWrite_ss, RWrite_ts;
reg [31:0] notEq, notEq_fs, notEq_ss, notEq_ts;

reg [3:0] aop, aop_fs;
reg [4:0] shamt, shamt_fs;
reg va1, va2, va3, va4;
reg va1_next;
reg[31:0] r_next [0:31];
reg signed [31:0] RStemp, Rttemp, RStemp_next, Rttemp_next;
reg signed [31:0] aout, aout_ss, aout_ts;
reg [31:0] inst_cur, inst_next;
reg [4:0] WReg, WReg_fs, WReg_ss, WReg_ts;
reg signed [31:0] Rdata1, Rdata2, Rdata2_fs, Wdata;
reg signed [31:0] ZE, SE ,ext;
reg signed [31:0] MOUT, MOUT_next;
reg zero, zero_ss;
reg [31:0] in_wb, in_wb_ff, in_wb_s;
reg [31:0] pc_wb, pc_s, pc_ff;

//------------------------------------------------------------------------
//   DESIGN
//------------------------------------------------------------------------

always @ (posedge clk, negedge rst_n)begin
	out_valid <= (!rst_n) ? 0 : va4;
	if(!rst_n)begin
		in_wb_ff <= 0;
		//if
		inst_addr <= 0;
		inst_cur <= 0;
		PC_fs <= 0;
		va1  <= 0;
		//id
		for(integer i=0; i<32; i++)begin
			r[i] <= 0;
		end
		va2 <= 0;
		PC_ss <= 0;
		b_addr_fs <= 0;
		RStemp <= 0;
		Rttemp <= 0;
		RegDst_fs <= 0;
		branch_fs <= 0;
		MRead_fs  <= 0;
		MtoReg_fs <= 0;
		MWrite_fs <= 0;
		ALUSrc_fs <= 0;
		RWrite_fs <= 0;
		notEq_fs    <= 0;
		aop_fs  <= 0;
		shamt_fs  <= 0;
		WReg_fs   <= 0;
		Rdata2_fs <= 0;

		//exe
		va3 <= 0;
		PC_ts <= 0;
		WReg_ss <= 0;
		aout_ss <= 0;
		b_addr_ss <= 0;
		zero_ss <= 0;

		//mem
		va4 <= 0;
		aout_ts <= 0;
		MOUT <= 0;
		WReg_ts <= 0;
		RegDst_ts <= 0;
		branch_ts <= 0;
		MRead_ts <= 0;
		MtoReg_ts <= 0;
		MWrite_ts <= 0;
		ALUSrc_ts <= 0;
		RWrite_ts <= 0;
		notEq_ts <= 0;
	end

	else begin
		//if
		inst_addr <= pc_new;
		inst_cur <= inst_next;
		PC_fs <= inst_addr;
		va1  <= in_valid;

		//id
		for(integer i=0; i<32; i++)begin
			r[i] <= r_next[i];
		end
		va2 <= va1;
		PC_ss <= PC_fs;
		b_addr_fs <= b_addr;
		RStemp <= RStemp_next;
		Rttemp <= Rttemp_next;
		RegDst_fs <= RegDst;
		branch_fs <= branch;
		MRead_fs <= MRead;
		MtoReg_fs <= MtoReg;
		MWrite_fs <= MWrite;
		ALUSrc_fs <= ALUSrc;
		RWrite_fs <= RWrite;
		notEq_fs <= notEq;
		aop_fs <= aop;
		shamt_fs <= shamt;
		WReg_fs <= WReg;
		Rdata2_fs <= Rdata2;

		//exe
		va3 <= va2;
		PC_ts <= PC_ss;
		WReg_ss <= WReg_fs;
		aout_ss <= aout;
		b_addr_ss <= b_addr_ss_comb;
		RegDst_ss <= RegDst_fs;
		branch_ss <= branch_fs;
		MRead_ss <= MRead_fs;
		MtoReg_ss <= MtoReg_fs;
		MWrite_ss <= MWrite_fs;
		ALUSrc_ss <= ALUSrc_fs;
		RWrite_ss <= RWrite_fs;
		notEq_ss <= notEq_fs;
		zero_ss <= zero;

		//mem
		va4 <= va3;
		WReg_ts <= WReg_ss;
		aout_ts <= aout_ss;
		MOUT <= MOUT_next;			
		RegDst_ts <= RegDst_ss;
		branch_ts <= branch_ss;
		MRead_ts <= MRead_ss;
		MtoReg_ts <= MtoReg_ss;
		MWrite_ts <= MWrite_ss;
		ALUSrc_ts <= ALUSrc_ss;
		RWrite_ts <= RWrite_ss;
		notEq_ts <= notEq_ss;
	end
end

always @(*)begin
	//if
	inst_next = in_valid ? inst : inst_cur;
	next_pc = in_valid ? (inst_addr + 4) : inst_addr;
	va1_next = in_valid;

	//id
	RStemp_next = va1 ? Rdata1 : RStemp;
	Rttemp_next = va1 ? ((ALUSrc) ? ((inst_cur[31:26]==1 || inst_cur[31:26]==2) ? ZE:SE) : Rdata2) : Rttemp;
	b_addr = va1 ? ((inst_cur[31:26]==1 || inst_cur[31:26]==2) ? ZE<<2:SE<<2) : b_addr_fs;

	//id_con
	if(va1)begin
		RegDst = (inst_cur[31:26] == 'd0) ? 1 : 0;
		if(inst_cur[31:26] == 'd0)begin
			branch = 0;
			MRead  = 0;
			MtoReg = 0;
			MWrite = 1;
			ALUSrc = 0;
			RWrite = 1;
			notEq = 0;
			aop = inst_cur[3:0];
			shamt = inst_cur[10:6];
		end
		else begin
			//if branch
			branch = (inst_cur[31:26] == 'd7 || inst_cur[31:26] == 'd8) ? 1 : 0;
			ALUSrc = (inst_cur[31:26] == 'd7 || inst_cur[31:26] == 'd8) ? 0 : 1;

			MRead = (inst_cur[31:26] == 'd5) ? 1 : 0;
			MtoReg = (inst_cur[31:26] == 'd5) ? 1 : 0;

			MWrite = (inst_cur[31:26] == 6) ? 0 : 1;
			
			RWrite = (inst_cur[31:26]>='d6 && inst_cur[31:26]<='d8) ? 0 : 1;
			
			notEq = (inst_cur[31:26] == 8) ? 1 : 0;
			
			case(inst_cur[31:26])
				1: aop = 0;
				2: aop = 1;
				3: aop = 2;
				4: aop = 3;
				5: aop = 2;
				6: aop = 2;
				7: aop = 3;
				8: aop = 3;
				9: aop = 5;
				10: aop = 6;
				11: aop = 7;
			endcase
			
			shamt = 'd16;
		end
	end
	else begin
		RegDst = RegDst_fs;
		branch = branch_fs;
		MRead = MRead_fs;
		MtoReg = MtoReg_fs;
		MWrite = MWrite_fs;
		ALUSrc = ALUSrc_fs;
		RWrite = RWrite_fs;
		notEq = notEq_fs;
		aop = aop_fs;
		shamt = shamt_fs;
	end

	//data take
	Rdata1 = r_next[inst_cur[25:21]];
	Rdata2 = r_next[inst_cur[20:16]];
		
	if(inst_cur[31:26] == 'd1 || inst_cur[31:26] == 'd2)begin
		ZE[31:0] = {16'b0, inst_cur[15:0]};
	end
	else if(inst_cur[31:26] == 'd3 || inst_cur[31:26] == 'd4)begin
		SE[31:16] = {16{inst_cur[15]}};
		SE[15:0] = inst_cur[15:0];
	end
	else begin
		ZE[31:16] = {16{inst_cur[15]}};
		ZE[15:0] = inst_cur[15:0];
		SE[31:16] = {16{inst_cur[15]}};
		SE[15:0] = inst_cur[15:0];
	end

	WReg = va1 ? (RegDst ? inst_cur[15:11] : inst_cur[20:16]) : WReg_fs;


	//exe
	b_addr_ss_comb = va2 ? (PC_ss+b_addr_fs) : b_addr_ss;
	//exe_cal
	if(va2)begin
		case(aop_fs)
			0: aout = RStemp & Rttemp;
			1: aout = RStemp | Rttemp;
			2: aout = RStemp + Rttemp;
			3: aout = RStemp - Rttemp;
			4: aout = (RStemp<Rttemp) ? 1:0;
			5: aout = (RegDst_fs) ? (RStemp << shamt_fs) : (Rttemp << shamt_fs);
			6: aout = ~(RStemp | Rttemp);
			default: aout = 0;
		endcase
	end
	else begin
		aout = aout_ss;
	end

	//exe_ifzero
	zero = va2 ? (((!notEq_fs && aout)||(notEq_fs && !aout)) ? 1 : 0) : zero_ss;

	//exe_to_rd/rt
	mem_wen = va2 ? MWrite_fs : 1;
	mem_din = va2 ? Rdata2_fs : 0;
	mem_addr = va2 ? aout : 0;

	//mem
	MOUT_next = (va3) ? mem_dout : MOUT;
	ext[31:16] = {16{inst[15]}};
	ext[15:0] = inst[15:0];
	if((inst[31:26] == 8) && (r_next[inst[25:21]] != r_next[inst[20:16]])) begin
		pc_new = next_pc + ext*'d4;
	end
	else if((inst[31:26] == 7) && (r_next[inst[25:21]] == r_next[inst[20:16]]))begin
		pc_new = next_pc + ext*'d4;
	end
	else if((inst[31:26] == 10) || (inst[31:26] == 11))begin
		pc_new = {next_pc[31:28], inst[25:0], 2'b00};
	end
	else begin
		pc_new = next_pc;
	end
	in_wb = inst;
	pc_wb = next_pc;
end

//WB
always @(*)begin
	in_wb_s = in_wb_ff;
	pc_s = pc_ff;
	Wdata = in_wb_s ? pc_s : (MtoReg_ts ? MOUT : aout_ts);
	for(integer i=0;i<32;i++) begin
		r_next[i] = r[i];
	end
	r_next[WReg_ts] = (va4 && RWrite_ts) ? Wdata : r[WReg_ts];
end

endmodule