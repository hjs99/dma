module fetch(
    input   clk,
    input   rstn,

    link.ack  ll,// link list

    dma.req   dma ,// dma interface

);

assign dma.r_req  = ll.req;
assign dma.r_addr = ll.addr;
assign dma.r_len  = 4*6-1;
assign dma.dack   = 1'b1;

assign ll.ack     = dma.ack;
assign ll.dvld     = dma.vald;
assign ll.rdata    = dma.data;

always@(posedge clk or negedge rstn)
begin
    if(!rstn)
        ll.dcnt <= 'd0;
    else if(ll.req && ll.ack)
        ll.dcnt <= 'd0;
    else if(ll.dvld)
        ll.dcnt <= ll.dcnt + 'd1 ;
end
endmodule
