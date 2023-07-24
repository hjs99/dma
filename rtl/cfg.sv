module cfg (
    input                   clk, rstn,
    output logic            intr,

    apb.slave               apb_s,

    output logic [31:0]     cfg_sar,//source byte addr
    output logic [31:0]     cfg_dar,//destination byte addr
    output logic [15:0]     cfg_trans_xsize,//2D DMA x-dir transfer byte size
    output logic [15:0]     cfg_trans_ysize,//2D DMA y-dir transfer line
    output logic [15:0]     cfg_sa_ystep,//source byte addr offset between each line
    output logic [15:0]     cfg_da_ystep,//destination byte addr offset
    output logic [31:0]     cfg_llr,//DMA cmd linked list base addr
    output logic            cfg_dma_halt,//1:AXI halt trasfer
    output logic            cfg_bf,//bufferable flag 
    output logic            cfg_cf,//cacheable flag

    input                   buf_err,
    output logic            clr_buf_err,

    link.req                ll ,//link list

    //dma status
    output logic            dma_cmd_sof,//
    input                   dma_cmd_end,
    output logic [7:0]      cmd_num,//
    output logic            dma_busy//1:DMA is working 
);
    
//==========apb interface==================
wire            apb_write;
wire            apb_read;
wire [31:0]     apb_addr;
wire            clr_intr;
wire            cmd_update;
wire    [3:0]   cmd_update_addr;
wire [31:0]     cmd_update_wd;

wire            dma_sof_w;
wire            cfg_intr_en;

//==============================assign=======================
assign  apb_write = apb_s.psel & apb_s.pwrite & apb_s.penable;
assign  apb_read  = apb_s.psel & (!apb_s.pwrite);
assign  apb_addr  = apb_s.paddr[2 +: 4];
assign  apb_s.pready =1'b1;  
assign  clr_intr     = apb_write & apb_s.penable & (apb_addr == 'd6) & (!apb_s.pwdata[0]);
assign  dma_sof_w    = apb_write & apb_s.penable & (apb_addr == 'd8) & apb_s.pwdata[0];
assign  clr_buf_err  = apb_write & apb_s.penable & (apb_addr == 'd6) & (!pwdata[4]);

assign  cmd_update   = apb_write | ll.dvld;
assign  cmd_update_addr = apb_write ? apb_addr : {1'b0,ll.dcnt};
assign  cmd_update_wd   = apb_write ? apb_s.pwdata : ll.rdata; 

//=========================regs==================================
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        cfg_sar         <= 'd0;
        cfg_dar         <= 'd0;
        cfg_trans_xsize <= 'd0;
        cfg_trans_ysize <= 'd0;
        cfg_sa_ystep    <= 'd0;
        cfg_da_ystep    <= 'd0;
        cfg_llr         <= 'd0;
    end else if(cmd_update) begin
        case(cmd_update_addr[3:0])
        'd0:    cfg_sar <= cmd_update_wd;
        'd1:    cfg_dar <= cmd_update_wd;
        'd2:    cfg_trans_xsize <= cmd_update_wd[15:0];
        'd3:    cfg_trans_ysize <= cmd_update_wd[15:0];

        'd4:    {cfg_da_ystep,cfg_sa_ystep}    <= {cmd_update_wd[31:16],cmd_update_wd[15:0]};
        'd5:    cfg_llr <= cmd_update_wd;
        default:begin 
                end
        endcase
end
end

always @(posedge clk or negedge rstn)
begin
    if(!rstn) begin
        cfg_dma_halt    <= 'd0;
        cfg_intr_en     <= 'd0;
        cfg_bf          <= 'd0;
        cfg_cf          <= 'd0;
    end else if(apb_write && (apb_addr == 'd7)) begin
        cfg_intr_en  <= pwdata[0];
        cfg_dma_halt <= pwdata[4];
        cfg_bf       <= pwdata[8];
        cfg_cf       <= pwdata[9];
    end
end
//===================2.DMA linked list ctrl===================
logic           ll_sta;
wire            dma_end_w;
logic           dma_end_flag;
parameter       s_idle = 'd0 , s_req = 'd1;

assign          ll.addr =cfg_llr;
assign          ll.req = (ll_sta == s_req) ? 1'b1 : 1'b0 ;
assign          dma_end_w  = dma_cmd_end && (cfg_llr[31:2] == 'd0);


always @(posedge clk or negedge rstn)
begin
    if(!rstn) 
        ll_sta <= s_idle;
    else begin
        case(ll_sta)
            s_idle:begin
                if(dma_cmd_end && (cfg_llr[31:2] != 'd0)) begin
                    ll_sta <= s_req;
                end
            end

            s_req: begin
                if(ll.ack)
                    ll_sta <= s_idle;
            end

            default: ll_sta <= s_idle;
    endcase
    end
end


//==================3:DMA_ STATUS==================
logic    dma_cmd_goon ;
assign   dma_cmd_goon = ll.dvld &(ll.dcnt == 'd5) ;


always @(posedge clk or negedge rstn)
begin
    if(!rstn)
        cmd_num <= 'd0;
    else if(dma_sof_w)
        cmd_num <= 'd0;
    else if(dma_cmd_end)
        cmd_num <= cmd_num + 'd1;
end

always @(posedge clk or negedge rstn)
begin
    if(!rstn)
        dma_busy <= 1'b0;
    else if(dma_sof_w)
        dma_busy <= 1'b1;
    else if(dma_end_w) 
        dma_busy <= 1'b0;

end

always @(posedge clk or negedge rstn)
if(!rstn)
    dma_end_flag <= 1'b0 ;
else if(dma_end_w )
    dma_end_flag <= 1'b1;
else if(clr_intr)
    dma_end_flag <= 1'b0 ;

assign intr = dma_end_flag & cfg_intr_en;

always @(posedge clk or negedge rstn)
if(!rstn)
    dma_cmd_sof   <= 1'b0;
else if(dma_sof_w || dma_cmd_goon) 
    dma_cmd_sof <= 1'b1 ;
else 
    dma_cmd_sof <= 1'b0 ;


//==============apb read out===============

always @(posedge clk or negedge rstn)
begin
if(!rstn)
    prdata    <= 32'h0;
else if (apb_read) begin
    case(apb_addr[3:0])
    'd0:    apb_s.prdata <= cfg_sar;
    'd1:    apb_s.prdata <= cfg_dar;
    'd2:    apb_s.prdata <= {16'h0 , cfg_trans_xsize};
    'd3:    apb_s.prdata <= {16'h0, cfg_trans_ysize};
    'd4:    apb_s.prdata <= {cfg_da_ystep,cfg_sa_ystep};
    'd5:    apb_s.prdata <= cfg_llr;

    'd6:    apb_s.prdata <= {16'h0,cmd_num,3'h0,buf_err,2'h0, dma_busy dma_end_flag};
    'd7:    apb_s.prdata <= {22'h0,cfg_cf,cfg_bf,3'h0,cfg_dma_halt,3'h0, cfg_intr_en};

    'd8:    apb_s.prdata <= 'd0;
    'd9:    apb_s.prdata <= 'd0;
    'd10:   apb_s.prdata <= 'd0;
    'd11:   apb_s.prdata <= {16'h0,16'h5310};
    default: apb_s.prdata <= 32'h0;
endcase
end
end



endmodule