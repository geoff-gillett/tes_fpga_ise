#ethernet=../../ethernetlib/IP_cores/v6_emac_v2_3/v6_emac_v2_3_0/example_design
project=../PlanAhead/tests.ppr

all: cpus | $(project)

ethernetExample:
	$(MAKE) -C ../../ethernetlib/scripts

cpus:
	$(MAKE) -C ../../controllerlib/PSM

$(project): | ethernetExample
	planahead -mode batch -source create_planahead.tcl

	