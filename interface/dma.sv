interface dma;
logic           req;//1:sent out dma req
logic           ack;
logic  [31:0]   addr;
logic   [15:0]  len;

logic           dvld;
logic           d_last;//1:last data of a dma_r_req
logic   [31:0]  data;
logic   [3:0]   be;//read data bute valid
logic           dack;

modport req(
    output req, output addr, output len, output dack, 
    input ack, input dvld, input d_last, input data ,input be

);

modport wreq(
    output req, output addr, output len, output dack, 
    input ack, input dvld, input data ,input be

);
modport ack(
    input req, input addr, input len ,input dack,
    output ack, output dvld, output d_last, output data, output be
);
endinterface