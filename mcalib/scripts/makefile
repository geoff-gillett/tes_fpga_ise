#ethernet=../../ethernetlib/IP_cores/v6_emac_v2_3/v6_emac_v2_3_0/example_design
planahead_project=../PlanAhead/mcalib.ppr
vivado_project=../Vivado/mcalib.xpr
vivado_sim=../Vivado/maclib.sim/
hdl=../HDL/

planahead: $(planahead_project)

vivado: $(vivado_project)

$(planahead_project): 
	planAhead -mode batch -source create_planahead.tcl

$(vivado_project):
	vivado -mode batch -source create_vivado.tcl	
