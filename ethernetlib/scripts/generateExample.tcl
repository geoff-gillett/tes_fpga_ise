create_project tmp/tmp -part xc6vlx240tff1156-1 -force
set_property target_language VHDL [current_project]
if ![file exists ../IP_cores/v6_emac_v2_3_0] {
	file mkdir ../IP_cores/v6_emac_v2_3_0
}
if ![file exists ../IP_cores/v6_emac_v2_3_0/v6_emac_v2_3_0.xco] {
	file copy ../IP_cores/v6_emac_v2_3_0.xco \
		../IP_cores/v6_emac_v2_3_0/v6_emac_v2_3_0.xco 
}
read_ip -file ../IP_cores/v6_emac_v2_3_0/v6_emac_v2_3_0.xco
generate_target {all} [get_ips v6_emac_v2_3_0]
close_project -delete