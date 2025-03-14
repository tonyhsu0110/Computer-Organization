module SP(
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

parameter  IDLE = 0,
           FandD = 1,
		   EXE = 2,
		   SLW = 3;

reg signed[31:0] rs_cur, rt_cur, rd_cur;
reg [1:0] state, next;
reg [5:0] op;
reg [4:0] rs, rt, rd;
reg stage_1,stage_2,stage_3,stage_4;
reg [31:0] ZE, SE;
reg signed [31:0] aout;
reg signed[31:0] rt_temp,rd_temp;

//------------------------------------------------------------------------
//   DESIGN
//------------------------------------------------------------------------

always @(posedge clk, negedge rst_n)begin
	if(!rst_n)
    begin
        state <= IDLE;
        mem_wen<=1;
        mem_addr<=0;
        mem_din<=0;
		stage_1<=0;
		stage_2<=0;
		stage_3<=0;
		stage_4<=0;
		out_valid<=0;
    end
        
    else begin
        state <= next;
		stage_1<=in_valid;
		stage_2<=stage_1;
		stage_3<=stage_2;
		stage_4<=stage_3;
		out_valid<=stage_4;
    end

	case (next)
	IDLE: begin
		if(!rst_n)
		begin
			out_valid <= 0;
			inst_addr <= 0;
			for(integer i=0;i<32;i++)
			begin
				r[i] = 0;
			end	
		end
	end

	FandD: begin
		// decode
		op = inst[31:26];
		rs = inst[25:21];
		rt = inst[20:16];
		rd = inst[15:11];
		ZE[31:16] = 16'b0;
		ZE[15:0] = inst[15:0];
		SE[31:16] = {16{inst[15]}};
		SE[15:0] = inst[15:0];
		rs_cur = r[rs];
		rt_cur = r[rt];
		rd_cur = r[rd];
		
		case(op)
			'd0:
				begin
					case(inst[5:0])
						'd0:
							aout <= rs_cur & rt_cur;
						'd1:
							aout <= rs_cur | rt_cur;
						'd2:
							aout <= rs_cur + rt_cur;
						'd3:
							aout <= rs_cur - rt_cur;
						'd4:
							aout <= rs_cur < rt_cur;
						'd5:
							aout <= rs_cur << inst[10:6];
						'd6:
							aout <= ~(rs_cur | rt_cur);
					endcase
				end

			'd1:
				aout <= rs_cur & ZE;
			'd2:
				aout <= rs_cur | ZE;
			'd3:
				aout <= rs_cur + SE;
			'd4:
				aout <= rs_cur - SE;
			'd5:
				aout <= rs_cur + SE;
			'd6:
				aout <= rs_cur + SE;
			'd7: 												
	            if(rs_cur==rt_cur)
                    aout <= inst_addr+SE*4;
            'd8:
                if(rs_cur!=rt_cur)
                    aout <= inst_addr+SE*4;
			'd9: begin
				aout[31:16] <= inst[15:0];
				aout[15:0] <= 16'b0;
			end
		endcase
	end

	EXE:begin
		case(op)
			'd0:
				rd_temp=aout;
			'd1:
				rt_temp=aout;
			'd2:
				rt_temp=aout;
			'd3:
				rt_temp=aout;
			'd4:
				rt_temp=aout;
			'd5: begin
				mem_wen=1;
				mem_addr=aout;
				rt_temp=mem_dout;
			end
			'd6: begin
				mem_wen=0;
				mem_addr=aout;
				mem_din=rt_cur;
			end	
			'd7: begin
				if(rs_cur==rt_cur)
					inst_addr=aout;
			end	
			'd8: begin
				if(rs_cur!=rt_cur)
					inst_addr=aout;
			end	
			'd9: begin
				rt_temp = aout;
			end
		endcase
	end
	SLW: begin
		case(op)
            'd0:
				r[rd] = rd_temp;
            'd1:
				r[rt] = rt_temp;
        	'd2:
                r[rt] = rt_temp;
        	'd3:
                r[rt] = rt_temp;
        	'd4:
				r[rt] = rt_temp;
        	'd5:
                r[rt] = rt_temp;
			'd9:
				r[rt] = rt_temp;
        endcase	
	end

	endcase
end

always @(*) begin
	case(state)
		IDLE:
			next = (in_valid) ? FandD : IDLE;
		FandD:
		begin
			next = (in_valid) ? FandD : EXE;
			out_valid = (in_valid) ? 0 : in_valid;
		end		
		EXE:
			next = (stage_4) ? SLW : EXE;
		SLW:
		begin
			next = IDLE;
			inst_addr=inst_addr+4;
		end
		default:
			next=IDLE;	
	endcase			
end

endmodule