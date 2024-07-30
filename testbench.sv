interface adder_int;
  logic [3:0]a;
  logic [3:0]b;
  logic [4:0]out;
endinterface

class transaction;
  randc bit[3:0]a;
  randc bit[3:0]b;
  bit [4:0]out;
endclass

class generator;
  transaction trans;
  mailbox mbx;
  function new(mailbox mbx);
    this.mbx=mbx;
  endfunction
  
  task main();
    for(int i=0;i<10;i++)
      begin
        trans=new();
        assert(trans.randomize())
          $display("GENERATED VALUES OF A IS %d and B IS %d",trans.a,trans.b);
        else
          $display("FAILED");
        mbx.put(trans);
        #10;
      end
  endtask
endclass

class driver;
  transaction trans;
  mailbox mbx;
  
  virtual adder_int inf;
  
  function new(mailbox mbx);
    this.mbx=mbx;
  endfunction
  
  
  task main();
    forever 
      begin
        mbx.get(trans);
        inf.a<=trans.a;
        inf.b<=trans.b;
        $display("VALUE SENT TO INTERFACE OF A IS %d and B IS %d",trans.a,trans.b);
        #10;
      end
  endtask
    
endclass


class monitor;
  transaction trans;
  mailbox mbx;
  virtual adder_int infe;
  
  function new(mailbox mbx);
    this.mbx=mbx;
  endfunction
  
  task main();
    trans=new();    
    repeat(10)
      begin
        trans.a=infe.a;
        trans.b=infe.b;
        trans.out=infe.out;
        $display("RECIEVED DATA FROM DUT OF A IS %d and B is %d AND OUT IS %d",infe.a,infe.b,infe.out);
        mbx.put(trans);
        #10;
      end
  endtask
endclass

class scoreboard;
  mailbox mbx;
  transaction trans;
  function new(mailbox mbx);
    this.mbx=mbx;
  endfunction
  
  task main();
    repeat(10)
      begin
        mbx.get(trans);
        if(trans.a+trans.b==trans.out)
          $display("PASSED");
        else
          $display("FAILED");
        #10;
      end
  endtask
endclass


module tb();
  generator gen;
  driver drv;
  mailbox mbx;
  mailbox mbx2;
  monitor mon;
  scoreboard sco;
  adder_int inf();
  adder dut(.a(inf.a),.b(inf.b),.out(inf.out));
  initial
    begin
      mbx=new();
      mbx2=new();
      gen=new(mbx);
      drv=new(mbx);
      mon=new(mbx2);
      sco=new(mbx2);
      drv.inf=inf;
      mon.infe=inf;
      fork
        #5 gen.main();
        #5 drv.main();
        #10 mon.main();
        #5 sco.main();
      join
    end
endmodule
