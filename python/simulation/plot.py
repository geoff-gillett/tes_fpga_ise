import numpy as np
import matplotlib.pyplot as plt
import math

from mpl_toolkits.axes_grid1 import host_subplot
from mpl_toolkits.axes_grid1.inset_locator import zoomed_inset_axes
from mpl_toolkits.axes_grid1.inset_locator import mark_inset


def align_yaxis(ax1, v1, ax2, v2):
    """adjust ax2 ylimit so that v2 in ax2 is aligned to v1 in ax1"""
    _, y1 = ax1.transData.transform((0, v1))
    _, y2 = ax2.transData.transform((0, v2))
    adjust_yaxis(ax2, (y1 - y2) / 2, v2)
    adjust_yaxis(ax1, (y2 - y1) / 2, v1)


def adjust_yaxis(ax, ydif, v):
    """shift axis ax by ydiff, maintaining point v at the same location"""
    inv = ax.transData.inverted()
    _, dy = inv.transform((0, 0)) - inv.transform((0, ydif))
    miny, maxy = ax.get_ylim()
    miny, maxy = miny - v, maxy - v
    if -miny > maxy or (-miny == maxy and dy > 0):
        nminy = miny
        nmaxy = miny * (maxy + dy) / (miny + dy)
    else:
        nmaxy = maxy
        nminy = maxy * (miny + dy) / (maxy + dy)
    ax.set_ylim(nminy + v, nmaxy + v)


def plot_pulse(pulse_num, data, pre=100, length=1000, time_scale=4, voltage_scale=1.0/math.pow(2, 14)*1000):

    pulse_num -= 1

    start = data.pulse_start[pulse_num] - pre
    stop = start + length
    x = np.arange(start, stop)
    pulse_data = data.slice((start, stop))

    fig = plot_slice(pulse_data, time_scale=time_scale, voltage_scale=voltage_scale)

    f_ax = fig._axstack.as_list()[0]
    s_ax = f_ax.parasites[0]

    f_ax.set_xlabel("Time (ns)", fontsize=18)
    f_ax.set_ylabel("Voltage (mV)", fontsize=18, color='r')
    s_ax.set_ylabel("Slope (mv/ns)", fontsize=18, color='b')

    f_sig = pulse_data.trace['filtered']*voltage_scale
    s_sig = pulse_data.trace['slope']*voltage_scale/time_scale

    f_ax.plot([start*time_scale, stop*time_scale], [0, 0], 'k')  # zero line

    f_ax.step(x*time_scale, f_sig, 'r', lw=2, label='filtered')
    s_ax.step(x*time_scale, s_sig, 'b', lw=1, label='slope')
    s_ax.set_ylim(-15, 50)

    plt.xlim(start*time_scale, stop*time_scale)
    # plt.xlim(start, stop)
    align_yaxis(f_ax, 0, s_ax, 0)
    fig.suptitle('Pulse {:d} of {:d}'.format(pulse_num+1, len(data.pulse_start)), fontsize=24)

    ins_start = pulse_data.peak_start[0]-5
    ins_stop = pulse_data.peak_start[0]+5
    f_ins_ax = zoomed_inset_axes(f_ax, 50, loc=1)  # zoom = 6
    f_ins_ax._label = 'f_ins'
    f_ins_ax.step(t[ins_start:ins_stop], f_sig[ins_start:ins_stop], 'r')
    f_ins_ax.set_yticks([])
    f_ins_ax.set_xticks([])

    f_ins_ax.plot([t[ins_start], t[ins_stop]], [0,0], 'k')  # zero line

    mark_inset(f_ax, f_ins_ax, loc1=2, loc2=4, fc="none", ec="0.5")

    s_ins_ax = f_ins_ax.twinx()
    s_ins_ax._label = 's_ins'
    s_ins_ax.set_yticks([])
    s_ins_ax.set_xticks([])

    s_ins_ax.step(t[ins_start:ins_stop], s_sig[ins_start:ins_stop], 'b')

    s_ins_ax.set_ylim(-1,1)
    f_ins_ax.set_ylim(-0.5, 2)
    f_ins_ax.set_xlim(t[ins_start], t[ins_stop])
    align_yaxis(f_ins_ax, 0, s_ins_ax, 0)

    s_ins_ax.plot(pulse_data.pulse_start, s_sig[pulse_data.pulse_start], 'ob')

    # pstart = peak_starts_inwin[0]
    # peak_start_t=t[pstart]-2
    # peak_start_f=f_sig[pstart]
    # peak_start_s=s_sig[pstart]
    #
    # f_ins_ax.plot(peak_start_t,peak_start_f,'ro')
    # s_ins_ax.plot(peak_start_t,peak_start_s,'bo')
    #
    # f_trans = f_ins_ax.transData
    # s_trans = s_ins_ax.transData.inverted()
    # trans = s_trans+f_trans
    # f_point=f_trans.transform((peak_start_t,peak_start_f))
    # s_point=s_trans.transform((f_point[0],f_point[1]))
    #
    # s_ins_ax.plot([peak_start_t,peak_start_t],[peak_start_s, s_point[1]],'k')
    #
    # s_ax.plot([t[start],t[stop]],[s_threshold,s_threshold],ls='dashed')

    return fig


def plot_slice(sl, time_scale=4, voltage_scale=1.0/math.pow(2, 14)*1000):

    x = np.arange(sl.bounds[0], sl.bounds[1])

    fig = plt.figure()

    f_ax = host_subplot(111, label='f_ax')
    s_ax = f_ax.twinx()
    s_ax._label = 's_ax'

    f_sig = sl.trace['filtered']*voltage_scale
    s_sig = sl.trace['slope']*voltage_scale/time_scale

    f_ax.plot([x[0]*time_scale, x[-1]*time_scale], [0, 0], 'k')  # zero line

    f_ax.step(x*time_scale, f_sig, 'r', lw=2, label='filtered')
    s_ax.step(x*time_scale, s_sig, 'b', lw=1, label='slope')
    #s_ax.set_ylim(-15, 50)

    plt.xlim(sl.bounds[0]*time_scale, sl.bounds[1]*time_scale)
    align_yaxis(f_ax, 0, s_ax, 0)
    return fig
