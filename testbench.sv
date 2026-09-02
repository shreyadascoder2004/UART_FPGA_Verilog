class transaction;

    rand bit [7:0] data;

    bit TXD;
    bit [7:0] RxData;
    bit done;

    function transaction copy();

        copy = new();

        copy.data   = this.data;
        copy.TXD    = this.TXD;
        copy.RxData = this.RxData;
        copy.done   = this.done;

    endfunction

endclass
class generator;

    transaction tr;

    mailbox #(transaction) mbx;

    int count = 0;

    event drvnext;
    event sconext;
    event done;


    function new(mailbox #(transaction) mbx);

        this.mbx = mbx;

        tr = new();

    endfunction


    task run();

        repeat(count) begin

            assert(tr.randomize())
            else $error("[GEN] Randomization Failed");


            $display("[GEN] DATA = %0d (0x%02h)",
                     tr.data,
                     tr.data);


            mbx.put(tr.copy());


            // Wait for driver
            @(drvnext);

            // Wait for scoreboard
            @(sconext);

        end

        -> done;

    endtask
endclass
    class driver;

    virtual uart_if vif;

    mailbox #(transaction) mbx;

    transaction tr;

    event drvnext;


    function new(mailbox #(transaction) mbx);

        this.mbx = mbx;

    endfunction


    task reset();

        vif.btn_reset    <= 1'b1;
        vif.btn_transmit <= 1'b0;
        vif.data         <= 8'h00;

        repeat(20)
            @(posedge vif.clk);

        vif.btn_reset <= 1'b0;

        repeat(20)
            @(posedge vif.clk);

        $display("[DRV] RESET DONE");
        $display("------------------------------------");

    endtask


    task run();

        forever begin

            mbx.get(tr);


            // Put data on DUT
            vif.data <= tr.data;

            $display("[DRV] DATA = %0d",
                     tr.data);


            // Press transmit button
            vif.btn_transmit <= 1'b1;

            repeat(20)
                @(posedge vif.clk);


            // Release button
            vif.btn_transmit <= 1'b0;


            $display("[DRV] TRANSMIT BUTTON RELEASED");


            // Tell generator that driving is complete
            -> drvnext;


            // Wait until receiver finishes
            wait(vif.done == 1'b1);

        end

    endtask

endclass
class monitor;

    mailbox #(transaction) mbx;

    virtual uart_if vif;

    transaction tr;


    function new(mailbox #(transaction) mbx);

        this.mbx = mbx;

    endfunction


    task run();

        forever begin

            // Wait until receiver says byte is complete
            @(posedge vif.done);

            tr = new();

            tr.RxData = vif.RxData;

            $display("[MON] RX DATA = %0d (0x%02h)",
                     tr.RxData,
                     tr.RxData);


            mbx.put(tr);

        end

    endtask

endclass


class scoreboard;

    mailbox #(transaction) mbxds;
    mailbox #(transaction) mbxms;

    transaction expected;
    transaction actual;

    event sconext;

    int err = 0;


    function new(
        mailbox #(transaction) mbxds,
        mailbox #(transaction) mbxms
    );

        this.mbxds = mbxds;
        this.mbxms = mbxms;

    endfunction


    task run();

        forever begin

            // Expected transaction
            mbxds.get(expected);

            // Actual transaction
            mbxms.get(actual);


            $display(
                "[SCO] EXPECTED = %0d (0x%02h) | ACTUAL = %0d (0x%02h)",
                expected.data,
                expected.data,
                actual.RxData,
                actual.RxData
            );


            if(expected.data == actual.RxData) begin

                $display("[SCO] DATA MATCH");

            end

            else begin

                $display("[SCO] DATA MISMATCH");

                err++;

            end


            $display("------------------------------------");


            -> sconext;

        end

    endtask

endclass

class environment;

    generator   gen;
    driver      drv;
    monitor     mon;
    scoreboard  sco;


    mailbox #(transaction) mbxgd;

    mailbox #(transaction) mbxds;

    mailbox #(transaction) mbxms;


    event nextgd;
    event nextgs;


    virtual uart_if vif;


    function new(virtual uart_if vif);

        this.vif = vif;


        // Mailboxes
        mbxgd = new();
        mbxds = new();
        mbxms = new();


        // Components
        gen = new(mbxgd);

        drv = new(mbxgd);

        mon = new(mbxms);

        sco = new(mbxds, mbxms);


        // Interface connections
        drv.vif = vif;
        mon.vif = vif;


        // Generator -> Driver synchronization
        gen.drvnext = nextgd;
        drv.drvnext = nextgd;


        // Generator -> Scoreboard synchronization
        gen.sconext = nextgs;
        sco.sconext = nextgs;

    endfunction


    task pre_test();

        drv.reset();

    endtask


    task test();

        fork

            gen.run();

            drv.run();

            mon.run();

            sco.run();

        join_any

    endtask


    task post_test();

        wait(gen.done.triggered);

        $display("");
        $display("====================================");
        $display("ERROR COUNT = %0d", sco.err);
        $display("====================================");

        $finish();

    endtask


    task run();

        pre_test();

        test();

        post_test();

    endtask

endclass
