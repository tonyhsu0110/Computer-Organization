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

input             clk, rst_n, in_valid;
input             [31:0] inst;
input  signed     [31:0] mem_dout;
output reg        out_valid;
output reg [31:0] inst_addr;
output reg        mem_wen;
output reg [11:0] mem_addr;
output reg signed [31:0] mem_din;

//------------------------------------------------------------------------
//   DECLARATION
//------------------------------------------------------------------------

// REGISTER FILE, DO NOT EDIT THE NAME.
reg	signed [31:0] r [0:31]; 

//------------------------------------------------------------------------
//   DESIGN
//------------------------------------------------------------------------

reg signed [31:0] r_next [0:31];
reg valid1, valid2, valid3;
reg [31:0] inst_addr_pc;
reg [1:0] pcSrc;

reg [31:0] inst_addr_4, inst_ss;
reg signed [31:0] rs_d1, rt_d1;
reg [4:0]  rt_addr, rd_addr;
reg signed [31:0] inst_f;
reg [31:0] j_addr;

reg regW;
reg ALUSrc;
reg [5:0] opc;
reg regDst, jal, memR, memW, memtoReg;
reg [5:0] func;
reg signed [31:0] rs, rt, rt_0, rt_1, aout;
reg [4:0] reg_dst;

reg [5:0] acon;
reg [4:0] shamt;
reg [31:0] rta, rtb, rt_2, rt_3;
reg signed [31:0] aout_EX;
reg [4:0]  reg_dst_EX;
reg [31:0] jal_addr_EX;

reg jal_EX, RegWrite_EX, memtoReg_EX, memR_EX, memW_EX;

reg signed [31:0] aout_mem;
reg [4:0]  reg_dst_mem;
reg [31:0] jal_addr_mem;

reg memtoReg_ts;
reg RegWrite_mem;
reg jal_mem;

reg [5:0] op_comb, op_ff;

always@(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        valid1 <= 0;
        valid2 <= 0;
        valid3 <= 0;
        out_valid <= 0;
        for(integer i=0; i<32; i++) begin
            r[i] <= 0;
        end

        inst_addr_4 <= 0;
        inst_addr <= 0;
        inst_ss <= 0;

        op_comb <= 0;
        memR_EX <= 0;
        memW_EX <= 0;
        mem_addr <= 0;
        mem_din <= 0;
        jal_addr_EX <= 0;
        aout_EX <= 0;
        reg_dst_EX <= 0;
        jal_EX <= 0;
        RegWrite_EX <= 0;
        memtoReg_EX <= 0;

        memtoReg_ts <= 0;
        RegWrite_mem <= 0;
        jal_mem <= 0;
        aout_mem <= 0;
        reg_dst_mem <= 0;
        jal_addr_mem <= 0;
    end

    else begin
        valid3 <= in_valid;
        valid2 <= valid3;
        valid1 <= valid2;
        out_valid <= valid1;

        for(integer i=0; i<32; i++) begin
            if(i==31 && jal_mem)
                r[i] <= jal_addr_mem;
            else
                r[i] <= r_next[i];
        end

        //if to id
        inst_addr_4 <= inst_addr + 4;
        inst_addr <= inst_addr_pc;
        inst_ss <= inst;

        //id to exe
        op_comb <= op_ff;
        memR_EX <= memR;
        memW_EX <= memW;
        mem_addr <= aout;
        mem_din <= rt_d1;
        jal_addr_EX <= inst_addr_4;
        aout_EX <= aout;
        reg_dst_EX <= reg_dst;
        jal_EX <= jal;
        RegWrite_EX <= regW;
        memtoReg_EX <= memtoReg;

        //mem to wb
        memtoReg_ts <= memtoReg_EX;
        RegWrite_mem <= RegWrite_EX;
        jal_mem <= jal_EX;
        aout_mem <= aout_EX;
        reg_dst_mem <= reg_dst_EX;
        jal_addr_mem <= jal_addr_EX;
    end
end

always@(*) begin

    //if
    case (inst[31:26])
        'd0: pcSrc = (inst[5:0]==7) ? 2 : 0;
        'd1: pcSrc = 0;
        'd2: pcSrc = 0;
        'd3: pcSrc = 0;
        'd4: pcSrc = 0;
        'd5: pcSrc = 0;
        'd6: pcSrc = 0;
        'd7: pcSrc = (r_next[inst[25:21]] == r_next[inst[20:16]]);
        'd8: pcSrc = (r_next[inst[25:21]] != r_next[inst[20:16]]);
        'd7: pcSrc = 0;
        'd10: pcSrc = 3;
        'd11: pcSrc = 3;
    endcase
    
    if(in_valid) begin
        case(pcSrc)
            'd0: inst_addr_pc = inst_addr + 4;
            'd1: inst_addr_pc = inst_addr + 4 + ({{16{inst[15]}}, inst[15:0]} << 2);
            'd2: inst_addr_pc = r_next[inst[25:21]];
            'd3: inst_addr_pc = {inst_addr[31:28], inst[25:0], 2'b00};
        endcase
    end
    else inst_addr_pc = inst_addr;

    //id
    for(integer i=0;i<32;i++) begin
        r_next[i] = r[i];
    end
    r_next[reg_dst_mem] = (RegWrite_mem) ? writeData : r[reg_dst_mem];

    rs_d1 = r_next[inst_ss[25:21]];
    rt_d1 = r_next[inst_ss[20:16]];
    rt_addr = inst_ss[20:16];
    rd_addr = inst_ss[15:11];
    
    //con
    opc = inst_ss[31:26];
    func = inst_ss[5:0];

    //inst_f ext
    inst_f[31:16] = {16{inst_ss[15]}};
    inst_f[15:0] = inst_ss[15:0];

    //j addr
    j_addr = {inst_ss[31:28], inst_ss[25:0], 2'b00};
        
    case(opc)
        'd0: begin
            ALUSrc = 0;
            regW = (func ==7) ? 0 : 1;
        end
        'd1: begin
            ALUSrc = 1;    
            regW = 1;
        end
        'd2: begin
            ALUSrc = 1;
            regW = 1;
        end
        'd3: begin
            ALUSrc = 1;
            regW = 1;
        end
        'd4: begin
            ALUSrc = 1;
            regW = 1;
        end
        'd5: begin
            ALUSrc = 1;
            regW = 1;
        end
        'd6: begin
            ALUSrc = 1;
            regW = 0;
        end
        'd7: begin
            ALUSrc = 0;
            regW = 0;
        end
        'd8: begin
            ALUSrc = 0;
            regW = 0;
        end
        'd9: begin
            ALUSrc = 1;
            regW = 1;
        end
        'd10: begin
            ALUSrc = 0;
            regW = 0;
        end
        'd11: begin
            ALUSrc = 0;
            regW = 0;
        end
        default: begin
            ALUSrc = 0;
            regW = 0;
        end
    endcase

    regDst = !opc ;
    jal = (opc==11);
    memtoReg = !(opc==5);
    memR = (opc==5);
    if(opc == 6)
        memW = 1;
    else
        memW = 0;
end

reg signed [31:0] writeData;
always@(*) begin

    //exe
    reg_dst = regDst ? rd_addr : rt_addr;
    
    case(inst_ss[31:26])
        'd0: acon = inst_f[5:0];
        'd1: acon = 'd0;
        'd2: acon = 'd1;
        'd3: acon = 'd2;
        'd4: acon = 'd3;
        'd5: acon = 'd2;
        'd6: acon = 'd2;
        'd7: acon = 'd3;
        'd8: acon = 'd3;
        'd9: acon = 'd7;
        default: acon = 'd2;
    endcase
    
    //cal
    rs = rs_d1;
    rt_0 = rt_d1;
    rt_1 = inst_f;

    rt = ALUSrc ? rt_1 : rt_0;
    shamt = inst_f[10:6];

    rt_2[31:16] = 16'b0;
    rt_2[15:0] = inst_f[15:0];
    rt_3[31:16] = {16{inst_f[15]}};
    rt_3[15:0] = inst_f[15:0];
    rta = ALUSrc ? rt_2 : rt_0;
    rtb = ALUSrc ? rt_3 : rt_0;

    case(acon)
        'd0: aout = rs & rta;  
        'd1: aout = rs | rta;  
        'd2: aout = rs + rtb;  
        'd3: aout = rs - rtb;  
        'd4: aout = (rs < rt);
        'd5: aout = (rs << shamt);
        'd6: aout = ~(rs | rt);
        'd7: begin
            aout[31:16] = rt[15:0];
            aout[15:0] = 16'b0;
        end
        // default: aout = 0;
    endcase

    //mem
    mem_wen = (memW_EX && !memR_EX) ? 0 : 1;
    
    //wb
    writeData = (memtoReg_ts>0) ? aout_mem : mem_dout;
end

endmodule