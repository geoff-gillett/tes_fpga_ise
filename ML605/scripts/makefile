project=../PlanAhead/ML605.ppr
ethernet=../IP_cores/v6_emac_v2_3_0/v6_emac_v2_3_0/example_design

all: cpus | $(project)

$(ethernet):
	planahead -mode batch -source generateEthernetExample.tcl

cpus:
	$(MAKE) -C ../../teslib/PSM
	
$(project): | $(ethernet)
	planahead -mode batch -source create_planahead.tcl
