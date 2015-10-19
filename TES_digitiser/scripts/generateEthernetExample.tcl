create_project tmp/tmp -part xc6vlx240tff1156-1 -force
set_property target_language VHDL [current_project]
if ![file exists ../../ethernetlib/IP_cores/v6_emac_v2_3_0] {
	file mkdir ../../ethernetlib/IP_cores/v6_emac_v2_3_0
}
if ![file exists ../../ethernetlib/IP_cores/v6_emac_v2_3_0/v6_emac_v2_3_0.xco] {
	file copy ../../ethernetlib/IP_cores/v6_emac_v2_3_0.xco \
		../../ethernetlib/IP_cores/v6_emac_v2_3_0/v6_emac_v2_3_0.xco 
}
read_ip -file ../../ethernetlib/IP_cores/v6_emac_v2_3_0/v6_emac_v2_3_0.xco
generate_target {all} [get_ips v6_emac_v2_3_0]
close_project -delete