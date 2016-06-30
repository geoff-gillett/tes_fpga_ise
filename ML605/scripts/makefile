planahead_project=../PlanAhead/teslib.ppr
vivado_project=../Vivado/teslib.xpr
ethernet=../IP_cores/v6_emac_v2_3_0/v6_emac_v2_3_0/example_design

planahead: $(planahead_project) | $(ethernet) cpus

$(ethernet):
	planahead -mode batch -source generateEthernetExample.tcl

cpus:
	$(MAKE) -C ../../teslib/PSM
	
$(planahead_project):  $(ethernet)
	planahead -mode batch -source create_planahead.tcl
