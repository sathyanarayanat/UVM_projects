`timescale 1ns/1ps
////////////////////////////////////////////////////
`include "uvm_macros.svh"
import uvm_pkg::*;

/////////////////// TRANSACTION CLASS //////////////

class transaction extends uvm_sequence_item;
  
  rand bit [3:0] a;
  rand bit [3:0] b ;
  rand bit [3:0] c ;
  rand bit [3:0] d ;
  randc bit [1:0] sel; // to make sure that all the mux lines are used atleast once
  bit [4:0] y;
  
  function new(string path = "transaction");
    super.new(path);
  endfunction
  
  `uvm_object_utils_begin(transaction)
  `uvm_field_int(a,UVM_DEFAULT)
  `uvm_field_int(b,UVM_DEFAULT)
  `uvm_field_int(c,UVM_DEFAULT)
  `uvm_field_int(d,UVM_DEFAULT)
  `uvm_field_int(sel,UVM_DEFAULT)
  `uvm_field_int(y,UVM_DEFAULT)
  `uvm_object_utils_end
endclass

//////////// Sequence class /////////////////

class generator extends uvm_sequence #(transaction);
  `uvm_object_utils(generator)

  transaction trs;
  
  function new(string path = "generator");
    super.new(path);
  endfunction
  
  virtual task body();
    trs = transaction::type_id::create("trs");
    repeat(10) begin
      start_item(trs);
      assert(trs.randomize());
      //trs.print(uvm_default_line_printer);
      `uvm_info("GEN",$sformatf("Data send to Driver a :%0d , b :%0d , c : %0d , d : %0d, sel : %0d ",trs.a,trs.b,trs.c,trs.d,trs.sel), UVM_NONE);
      finish_item(trs);
    end
  endtask
endclass

/////////////////////////Driver class ///////////////
class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver);
  
  function new(string path="driver", uvm_component parent = null);
    super.new(path,parent);
  endfunction
  
  transaction t;
  virtual mux_if mif;
  
  
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t = transaction::type_id::create("t");
    if(!uvm_config_db #(virtual mux_if)::get(this,"","mif",mif))
       `uvm_error("DRV","Unable to access uvm_config_db");
  endfunction
       
       virtual task run_phase(uvm_phase phase);
         forever begin
           
           seq_item_port.get_next_item(t);
           mif.a <= t.a;
           mif.b <= t.b;
           mif.c <= t.c;
           mif.d <= t.d;
           mif.sel <= t.sel;
           //t.print(uvm_default_line_printer);
           `uvm_info("DRV",$sformatf("Trigger DUT a :%0d , b :%0d , c : %0d , d : %0d, sel : %0d ",t.a,t.b,t.c,t.d,t.sel), UVM_NONE);
           seq_item_port.item_done();
           #10;
         end
         endtask
  endclass

/////////////////  MONITER CLASS /////////////

class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)
  
  
  uvm_analysis_port #(transaction) send;
  
  function new(string path="monitor", uvm_component parent = null);
    super.new(path,parent);
    send = new("send",this);
  endfunction
  
  transaction tr;
  virtual mux_if mif;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr = transaction::type_id::create("tr");
    if(!uvm_config_db #(virtual mux_if)::get(this,"","mif",mif))
      `uvm_error("MON","Unable to access uvm_config_db");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      #10;
      tr.a = mif.a;
      tr.b = mif.b;
      tr.c = mif.c;
      tr.d = mif.d;
      tr.sel = mif.sel;
      tr.y = mif.y;
      //tr.print(uvm_default_line_printer);
      `uvm_info("MON",$sformatf("Data send to Scoreboard a :%0d , b :%0d , c : %0d , d : %0d, sel : %0d and y : %0d",tr.a,tr.b,tr.c,tr.d,tr.sel,tr.y), UVM_NONE);
      send.write(tr);
    end
  endtask    
endclass

//////////////////////    Scorecoard class ////////////////
class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)
  
  uvm_analysis_imp #(transaction,scoreboard) rcv;
  
  function new(string path="scoreboard", uvm_component parent = null);
    super.new(path,parent);
    rcv = new("rcv",this);
  endfunction
  
  transaction ts;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ts = transaction::type_id::create("ts");
  endfunction
  
  virtual function void write(input transaction t);
    ts = t;
    //ts.print(uvm_default_line_printer);
    `uvm_info("SCO",$sformatf("Data rcvd from Monitor a :%0d , b :%0d , c : %0d , d : %0d, sel : %0d and y : %0d ",ts.a,ts.b,ts.c,ts.d,ts.sel,ts.y), UVM_NONE);
    
     if((ts.sel==2'b00)&(ts.y==ts.a))begin
      `uvm_info("SCO","test passed",UVM_NONE);end
    else if((ts.sel==2'b01)&(ts.y==ts.b))begin
      `uvm_info("SCO","test passed",UVM_NONE);end
    else if((ts.sel==2'b10)&(ts.y==ts.c))begin
      `uvm_info("SCO","test passed",UVM_NONE);end
    else if((ts.sel==2'b11)&(ts.y==ts.d))begin
      `uvm_info("SCO","test passed",UVM_NONE);end
    else begin
      `uvm_info("SCO","test failed",UVM_NONE);end
  endfunction
/*  
  virtual task run_phase(uvm_phase phase);
    if((ts.sel==2'b00)&(ts.y==ts.a))begin
      `uvm_info("SCO","test passed",UVM_NONE);end
    else if((ts.sel==2'b01)&(ts.y==ts.b))begin
      `uvm_info("SCO","test passed",UVM_NONE);end
    else if((ts.sel==2'b10)&(ts.y==ts.c))begin
      `uvm_info("SCO","test passed",UVM_NONE);end
    else if((ts.sel==2'b11)&(ts.y==ts.d))begin
      `uvm_info("SCO","test passed",UVM_NONE);end
    else begin
      `uvm_info("SCO","test failed",UVM_NONE);end
  endtask
  */
endclass

/////////// Agent class ///////////////

class agent extends uvm_agent;
  `uvm_component_utils(agent)
  
  function new(string path = "agent",uvm_component c);
    super.new(path,c);
  endfunction
    
    driver drv;
    uvm_sequencer #(transaction) seqr;
    monitor mon;
    
  virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      drv = driver::type_id::create("drv",this);
      mon = monitor::type_id::create("mon",this);
      seqr =  uvm_sequencer#(transaction)::type_id::create("seqr",this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
     super.connect_phase(phase);
     drv.seq_item_port.connect(seqr.seq_item_export);
    endfunction
endclass
/////////////////////////// ENV class /////////////////
 
   class env extends uvm_env;
     `uvm_component_utils(env)
  
function new(input string inst = "ENV", uvm_component c);
super.new(inst, c);
endfunction
 
scoreboard s;
agent a;
 
virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
  s = scoreboard::type_id::create("s",this);
  a = agent::type_id::create("a",this);
endfunction
 
     virtual function void connect_phase(uvm_phase phase);
       super.connect_phase(phase);
       a.mon.send.connect(s.rcv);
     endfunction
 
endclass
    
//////////////////////////// TEST class ////////////////////////
    
    class test extends uvm_test;
      `uvm_component_utils(test)
      
      function new(input string inst = "test", uvm_component c);
        super.new(inst, c);
      endfunction
      
      env e;
      generator gen;
      
      virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        gen = generator::type_id::create("gen");
        e = env::type_id::create("e",this);
      endfunction
      
      virtual task run_phase(uvm_phase phase);
         phase.raise_objection(this);
         gen.start(e.a.seqr);
          #50;
         phase.drop_objection(this);
      endtask  
    endclass
    
  ///////////////////////// TB //////////////////////
  module tb;
    
    mux_if mif();
      mux dut (.a(mif.a),.b(mif.b),.c(mif.c),.d(mif.d),.sel(mif.sel),.y(mif.y));
    
    initial begin
    $dumpfile("dump.vcd");
	$dumpvars;
	end
    
    initial begin
     
      uvm_config_db #(virtual mux_if)::set(null,"uvm_test_top.e.a*","mif",mif);
      run_test("test");
    end
  endmodule