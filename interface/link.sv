interface link;
parameter ADDR_W=32;
parameter DATA_W=32;
logic               req;
logic               ack;
logic               dvld;
logic  [ADDR_W-1:0] addr;
logic  [DATA_W-1:0] rdata;
logic   [2:0]       dcnt;

modport req(
    output req,output addr,
    input ack, input dvld, input rdata , input dcnt
);

modport ack(
    input req, input addr,
    output ack , output dvld, output rdata, output dcnt
);

endinterface
