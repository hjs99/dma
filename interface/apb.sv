interface apb;
    parameter ADDR_W = 32 ;
    parameter DATA_W =32;

    logic               psel;
    logic [7:0]         paddr;
    logic               penable;
    logic               pwrite;
    logic [DATA_W-1:0]  pwdata;
    logic [DATA_W-1:0]  prdata;
    logic               pready;

    modport slave (
        input psel,input penable,input paddr, input pwrite,input pwdata,
        output prdata , output pready
    );

    modport master(
        output psel , output penable,output paddr, output pwrite , output pwdata,
        input prdata , input pready
    );

endinterface //apbparameter ADDR_W = 32 ;

