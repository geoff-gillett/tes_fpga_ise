set runs [get_runs]

if {[lsearch $runs TES_synth]==-1} {
	create_run TES_synth -flow {XST 14} -strategy {PlanAhead Defaults}
}
set_property constrset TES_digitiser [get_runs TES_synth]
set_property steps.xst.args.opt_level 1 [get_runs TES_synth]
set_property steps.xst.args.register_duplication yes [get_runs TES_synth]
set_property steps.xst.args.register_balancing yes [get_runs TES_synth]
#
if {[lsearch $runs default]==-1} {
	create_run default -parent_run TES_synth -flow {ISE 14} -strategy {ISE Defaults}
}
set_property constrset TES_digitiser [get_runs default]
set_property steps.map.args.t 4 [get_runs default]
set_property steps.map.args.logic_opt off [get_runs default]
set_property steps.map.args.ol high [get_runs default]
set_property steps.map.args.xe <none> [get_runs default]
set_property steps.map.args.mt on [get_runs default]
set_property steps.par.args.ol high [get_runs default]
set_property steps.par.args.xe <none> [get_runs default]
set_property steps.par.args.mt 4 [get_runs default]
#
if {[lsearch $runs xe_n]==-1} {
	create_run xe_n -parent_run TES_synth -flow {ISE 14} -strategy {ISE Defaults}
}
set_property constrset TES_digitiser [get_runs xe_n]
set_property steps.map.args.t 4 [get_runs xe_n]
set_property steps.map.args.logic_opt off [get_runs xe_n]
set_property steps.map.args.ol high [get_runs xe_n]
set_property steps.map.args.xe n [get_runs xe_n]
set_property steps.map.args.mt on [get_runs xe_n]
set_property steps.par.args.ol high [get_runs xe_n]
set_property steps.par.args.xe n [get_runs xe_n]
set_property steps.par.args.mt 4 [get_runs xe_n]
#
if {[lsearch $runs xe_n_pr_b]==-1} {
	create_run xe_n_pr_b -parent_run TES_synth -flow {ISE 14} -strategy {ISE Defaults}
}
set_property constrset TES_digitiser [get_runs xe_n_pr_b]
set_property steps.map.args.t 4 [get_runs xe_n_pr_b]
set_property steps.map.args.pr b [get_runs xe_n_pr_b]
set_property steps.map.args.logic_opt off [get_runs xe_n_pr_b]
set_property steps.map.args.ol high [get_runs xe_n_pr_b]
set_property steps.map.args.xe n [get_runs xe_n_pr_b]
set_property steps.map.args.mt on [get_runs xe_n_pr_b]
set_property steps.par.args.ol high [get_runs xe_n_pr_b]
set_property steps.par.args.xe n [get_runs xe_n_pr_b]
set_property steps.par.args.mt 4 [get_runs xe_n_pr_b]
#
if {[lsearch $runs default_pr_b]==-1} {
	create_run default_pr_b -parent_run TES_synth -flow {ISE 14} -strategy {ISE Defaults}
}
set_property constrset TES_digitiser [get_runs default_pr_b]
set_property steps.map.args.t 4 [get_runs default_pr_b]
set_property steps.map.args.pr b [get_runs default_pr_b]
set_property steps.map.args.logic_opt off [get_runs default_pr_b]
set_property steps.map.args.ol high [get_runs default_pr_b]
set_property steps.map.args.xe <none> [get_runs default_pr_b]
set_property steps.map.args.mt on [get_runs default_pr_b]
set_property steps.par.args.ol high [get_runs default_pr_b]
set_property steps.par.args.xe <none> [get_runs default_pr_b]
set_property steps.par.args.mt 4 [get_runs default_pr_b]
#
current_run [get_runs default]
if {[lsearch $runs synth_1]!=-1} {
	delete_run [get_runs synth_1]
}