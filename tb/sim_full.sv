`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
import axi_vip_pkg::*;
import system_axi_vip_0_pkg::*;

module sim_full(

    );

    localparam STEP_SYS = 200;
    localparam STEP_DEV = 40;
    localparam SIM_LENGTH = 1024*16;
    localparam DS_RATE = 32;

    logic [31:0] offset_imag_offset = 32'h44A0_0000;
    logic [31:0] offset_real_offset = 32'h44A1_0000;
    logic [31:0] phase_rew_offset   = 32'h44A2_0000;
    logic [31:0] phi_0_offset       = 32'h44A3_0000;

    // input
    logic        axi_aresetn;
    logic        axi_clk;

    logic [95:0] axis_data_in_tdata;
    logic [11:0] axis_data_in_tkeep;
    logic [0:0]  axis_data_in_tlast;
    logic        axis_data_in_tready;
    logic [11:0] axis_data_in_tstrb;
    logic        axis_data_in_tvalid;

    logic [95:0] axis_data_out_tdata;
    logic [11:0] axis_data_out_tkeep;
    logic [0:0]  axis_data_out_tlast;
    logic        axis_data_out_tready;
    logic [11:0] axis_data_out_tstrb;
    logic        axis_data_out_tvalid;

    logic [63:0] axis_phase_out_tdata;
    logic        axis_phase_out_tready;
    logic        axis_phase_out_tvalid;

    logic        s_axis_aclk;
    logic        s_axis_aresetn;

    system_wrapper dut(.*);

    // Utility
    integer fd_din_data;

    integer fd_dout;
    integer fd_pout;

    logic write_ready = 0;
    logic [$clog2(SIM_LENGTH)-1:0] counter = 0;
    logic [$clog2(SIM_LENGTH)-1:0] counter_phase = 0;
    logic finish = 0;
    logic finish_phase = 0;

    // Threshold
    logic [63:0] offset_real [0:15];
    logic [63:0] offset_imag [0:15];
    logic [63:0] phase_rew [0:15];
    logic [63:0] phi_0 [0:15];

    // data flow control
    logic din_on;
    logic din_fin;

    system_axi_vip_0_mst_t  vip_agent;

    task clk_gen();
        axi_clk = 0;
        forever #(STEP_SYS/2) axi_clk = ~axi_clk;
    endtask

    task clk_gen_dev();
        s_axis_aclk = 0;
        forever #(STEP_DEV/2) s_axis_aclk = ~s_axis_aclk;
    endtask

    task rst_gen();
        axi_aresetn = 0;
        s_axis_aresetn = 0;

        axis_data_in_tdata = 0;
        axis_data_in_tvalid = 0;
        
        axis_data_out_tready = 1;
        axis_phase_out_tready = 1;

        din_on = 0;
        din_fin = 0;

        #(STEP_SYS*30);
        axi_aresetn = 1;
        s_axis_aresetn = 1;
    endtask
    
    task file_open();
        fd_din_data = $fopen("./tb_data.dat", "r");

        fd_dout = $fopen("./tb_dout.dat", "w");
        fd_pout = $fopen("./tb_pout.dat", "w");

        if ((fd_din_data == 0) | (fd_dout == 0)) begin
            $display("File open error.");
            $finish;
        end else begin
            $display("File open.");
            write_ready = 1;
        end
    endtask

    task thr_setting_read();
        $readmemb("./tb_offset_real.dat", offset_real);
        $readmemb("./tb_offset_imag.dat", offset_imag);
        $readmemb("./tb_phase_rew.dat",   phase_rew);
        $readmemb("./tb_phi_0.dat",       phi_0);
    endtask

    task file_close();
        if (write_ready) begin
            write_ready = 0;
            $fclose(fd_dout);
        end
    endtask

    axi_transaction wr_transaction;
    axi_transaction rd_transaction;
    
    initial begin : START_system_axi_vip_0_0_MASTER
        fork
            clk_gen();
            clk_gen_dev();
            rst_gen();
            file_open();
            thr_setting_read();
        join_none
        
        #(STEP_SYS*500);
    
        vip_agent = new("my VIP master", sim_full.dut.system_i.axi_vip.inst.IF);
        vip_agent.start_master();
        #(STEP_SYS*100);
        wr_transaction = vip_agent.wr_driver.create_transaction("write transaction");

        // BRAM setting
        for(int i = 0; i < 16; i++) begin
            // Lower 4 bytes
            wr_transaction.set_write_cmd(offset_imag_offset + 8*i, XIL_AXI_BURST_TYPE_INCR, 0, 0, xil_axi_size_t'(xil_clog2((32)/8)));
            wr_transaction.set_data_block(offset_imag[i][31:0]);
            vip_agent.wr_driver.send(wr_transaction);
            // Upper 4 bytes
            wr_transaction.set_write_cmd(offset_imag_offset + 8*i + 4, XIL_AXI_BURST_TYPE_INCR, 0, 0, xil_axi_size_t'(xil_clog2((32)/8)));
            wr_transaction.set_data_block(offset_imag[i][63:32]);
            vip_agent.wr_driver.send(wr_transaction);
        end

        for(int i = 0; i < 16; i++) begin
            // Lower 4 bytes
            wr_transaction.set_write_cmd(offset_real_offset + 8*i, XIL_AXI_BURST_TYPE_INCR, 0, 0, xil_axi_size_t'(xil_clog2((32)/8)));
            wr_transaction.set_data_block(offset_real[i][31:0]);
            vip_agent.wr_driver.send(wr_transaction);
            // Upper 4 bytes
            wr_transaction.set_write_cmd(offset_real_offset + 8*i + 4, XIL_AXI_BURST_TYPE_INCR, 0, 0, xil_axi_size_t'(xil_clog2((32)/8)));
            wr_transaction.set_data_block(offset_real[i][63:32]);
            vip_agent.wr_driver.send(wr_transaction);
        end

        for(int i = 0; i < 16; i++) begin
            // Lower 4 bytes
            wr_transaction.set_write_cmd(phase_rew_offset + 8*i, XIL_AXI_BURST_TYPE_INCR, 0, 0, xil_axi_size_t'(xil_clog2((32)/8)));
            wr_transaction.set_data_block(phase_rew[i][31:0]);
            vip_agent.wr_driver.send(wr_transaction);
            // Upper 4 bytes
            wr_transaction.set_write_cmd(phase_rew_offset + 8*i + 4, XIL_AXI_BURST_TYPE_INCR, 0, 0, xil_axi_size_t'(xil_clog2((32)/8)));
            wr_transaction.set_data_block(phase_rew[i][63:32]);
            vip_agent.wr_driver.send(wr_transaction);
        end

        for(int i = 0; i < 16; i++) begin
            // Lower 4 bytes
            wr_transaction.set_write_cmd(phi_0_offset + 8*i, XIL_AXI_BURST_TYPE_INCR, 0, 0, xil_axi_size_t'(xil_clog2((32)/8)));
            wr_transaction.set_data_block(phi_0[i][31:0]);
            vip_agent.wr_driver.send(wr_transaction);
            // Upper 4 bytes
            wr_transaction.set_write_cmd(phi_0_offset + 8*i + 4, XIL_AXI_BURST_TYPE_INCR, 0, 0, xil_axi_size_t'(xil_clog2((32)/8)));
            wr_transaction.set_data_block(phi_0[i][63:32]);
            vip_agent.wr_driver.send(wr_transaction);
        end

        #(STEP_SYS*1000);

        din_on <= 1;
        wait(finish);
        repeat(1000)@(posedge s_axis_aclk);
        
        $finish;
    end

    always @(posedge s_axis_aclk) begin
        if (axis_data_out_tvalid && din_on && write_ready) begin
            if (~finish) begin
                $fdisplay(fd_dout, "%b", axis_data_out_tdata);
                if (counter == SIM_LENGTH) begin
                    finish <= 1;
                    $fclose(fd_dout);
                end else begin
                    counter <= counter + 1;
                end
            end
        end
    end

    always @(posedge s_axis_aclk) begin
        if (axis_phase_out_tvalid && din_on && write_ready) begin
            if (~finish_phase) begin
                $fdisplay(fd_pout, "%b", axis_phase_out_tdata);
                if (counter_phase == SIM_LENGTH) begin
                    finish_phase <= 1;
                    $fclose(fd_pout);
                end else begin
                    counter_phase <= counter_phase + 1;
                end
            end
        end
    end

    always @(posedge s_axis_aclk) begin
        if (din_on & ~din_fin) begin
            if($feof(fd_din_data) != 0) begin
                axis_data_in_tvalid <= 1'b0;

                $display("DIN fin");
                $fclose(fd_din_data);
                din_fin <= 1'b1;
            end
            $fscanf(fd_din_data, "%b %b\n", axis_data_in_tdata, axis_data_in_tvalid);
        end
    end

endmodule
