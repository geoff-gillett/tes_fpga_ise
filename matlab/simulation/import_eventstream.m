function stream=import_eventstream(testbench)
 path='C:\TES_project\fpga_ise\tests\PlanAhead\tests.sim\';
 file=sprintf('%s%s\\eventstream',path,testbench);
 %dsp_capture_TB\dsp_capture_TB.stream'
  stream=importint16(file,4);
end