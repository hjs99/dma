interface dma;
logic           r_req;//1:sent out dma req
logic           r_ack;
logic  [31:0]   r_addr;
logic   [15:0]  r_len;

logic           dvld;
logic           rd_last;//1:last data of a dma_r_req
logic   [31:0]  rdata;
logic   [3:0]   rbe;//read data bute valid
logic           dack;

modport req(
    output r_req, output r_addr, output r_len, output dack, 
    input r_ack, input dvld, input rd_last, input rdata ,input rbe

);

modport ack(
    input r_req, input r_addr, input r_len ,input dack,
    output r_ack, output dvld, output rd_last, output rdata, output rbe
);
endinterface