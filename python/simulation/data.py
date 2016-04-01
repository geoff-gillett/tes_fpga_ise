import numpy as np
from enum import Enum
import os

DEFAULT_REPO_PATH = 'c:\\TES_project\\fpga_ise\\'


# dataset = dict() Describes what files should be read using np.fromfile
# dict contains tuples (file, np.dtype, indexed (boolean) ) the key is the name of the attribute to use.
# indexed indicates that region should search for values in bounds rather than slicing


class HeightType(Enum):
    @staticmethod
    def from_int(value):
        if value == 0:
            return HeightType.peak_height
        elif value == 1:
            return HeightType.cfd_high
        elif value == 2:
            return HeightType.slope_integral
        else:
            raise AttributeError()

    peak_height = 0
    cfd_high = 1
    slope_integral = 2


class TriggerType(Enum):
    @staticmethod
    def from_int(value):
        if value == 0:
            return TriggerType.pulse_threshold
        elif value == 1:
            return TriggerType.slope_threshold
        elif value == 2:
            return TriggerType.cfd_low
        else:
            raise AttributeError()

    pulse_threshold = 0
    slope_threshold = 1
    cfd_low = 2


class PayloadType(Enum):

    @staticmethod
    def from_int(value):
        if value == 0:
            return PayloadType.peak
        elif value == 1:
            return PayloadType.area
        elif value == 2:
            return PayloadType.pulse
        elif value == 3:
            return PayloadType.trace
        elif value == 4:
            return PayloadType.tick
        elif value == 5:
            return PayloadType.mca
        else:
            raise AttributeError()

    peak = 0
    area = 1
    pulse = 2
    trace = 3
    tick = 4
    mca = 5


class McaValueType(Enum):

    @staticmethod
    def from_int(value):
        if value == 0:
            return McaValueType.filtered_signal
        elif value == 1:
            return McaValueType.filtered_area
        elif value == 2:
            return McaValueType.filtered_extrema
        elif value == 3:
            return McaValueType.slope_signal
        elif value == 4:
            return McaValueType.slope_area
        elif value == 5:
            return McaValueType.slope_extrema
        elif value == 6:
            return McaValueType.pulse_area
        elif value == 7:
            return McaValueType.pulse_extrema
        elif value == 8:
            return McaValueType.pulse_time
        elif value == 9:
            return McaValueType.raw_signal
        elif value == 10:
            return McaValueType.raw_area
        elif value == 11:
            return McaValueType.raw_extrema
        else:
            raise AttributeError()

    filtered_signal = 0
    filtered_area = 1
    filtered_extrema = 2
    slope_signal = 3
    slope_area = 4
    slope_extrema = 5
    pulse_area = 6
    pulse_extrema = 7
    pulse_time = 8
    raw_signal = 9
    raw_area = 10
    raw_extrema = 11


class McaTriggerType(Enum):

    @staticmethod
    def from_int(value):
        if value == 0:
            return McaTriggerType.disabled
        elif value == 1:
            return McaTriggerType.clock
        elif value == 2:
            return McaTriggerType.filtered_xing
        elif value == 3:
            return McaTriggerType.filtered_0xing
        elif value == 4:
            return McaTriggerType.slope_0xing
        elif value == 5:
            return McaTriggerType.slope_xing
        elif value == 6:
            return McaTriggerType.cfd_high
        elif value == 7:
            return McaTriggerType.cfd_low
        elif value == 8:
            return McaTriggerType.maxima
        elif value == 9:
            return McaTriggerType.mimima
        elif value == 10:
            return McaTriggerType.raw_0xing
        else:
            raise AttributeError()

    disabled = 0
    clock = 1
    filtered_xing = 2
    filtered_0xing = 3
    slope_0xing = 4
    slope_xing = 5
    cfd_high = 6
    cfd_low = 7
    maxima = 8
    mimima = 9
    raw_0xing = 10


def get_registers(project, testbench, file='settings', repo=DEFAULT_REPO_PATH):
    registers = dict()
    settings = Data.fromfile(file, np.int32, project, testbench, repo)
    registers['baseline'] = dict()
    registers['baseline']['offset'] = settings[0]
    registers['baseline']['subtraction'] = settings[1] != 0
    registers['baseline']['time_constant'] = settings[2]
    registers['baseline']['threshold'] = settings[3]
    registers['baseline']['count_threshold'] = settings[4]
    registers['generic'] = dict()
    registers['baseline']['average_order'] = settings[5]
    registers['capture'] = dict()
    registers['capture']['cfd_relative'] = settings[6] != 0
    registers['capture']['constant_fraction'] = settings[7]
    registers['capture']['pulse_threshold'] = settings[8]
    registers['capture']['slope_threshold'] = settings[9]
    registers['capture']['pulse_area_threshold'] = settings[10]
    registers['capture']['height_type'] = HeightType.from_int(settings[11])
    registers['capture']['threshold_rel2min'] = settings[12] != 0
    registers['capture']['trigger_type'] = TriggerType.from_int(settings[13])
    registers['capture']['event_type'] = PayloadType.from_int(settings[14])
    registers['capture']['height_rel2min'] = settings[15] != 0

    return registers


class EventStream:
    def __init__(self, project, testbench, file='eventstream', repo=DEFAULT_REPO_PATH):
        self._stream64 = Data.fromfile(file, np.uint64, project, testbench, repo)

    def _index_stream(self, event_type):
        pass


class Data:
    @staticmethod
    def fromfile(file, dt, project, testbench, repo=DEFAULT_REPO_PATH):
        path = repo + project + '\\PlanAhead\\' + project + '.sim\\' + testbench + '\\'
        if os.path.isfile(path + file):
            return np.fromfile(path + file, dt)
        else:
            return None

    @staticmethod
    def read_dataset(dataset, project, testbench, repo=DEFAULT_REPO_PATH):
        data_dict = dict()
        for attribute in dataset.keys():
            data_dict[attribute] = (
                Data.fromfile(dataset[attribute][0], dataset[attribute][1], project, testbench, repo),
                dataset[attribute][2]
            )

        return data_dict

    @staticmethod
    def parse_settings(settings):
        registers = dict()
        registers['baseline'] = dict()
        registers['baseline']['offset'] = settings[0]
        registers['baseline']['subtraction'] = settings[1] != 0
        registers['baseline']['time_constant'] = settings[2]
        registers['baseline']['threshold'] = settings[3]
        registers['baseline']['count_threshold'] = settings[4]
        registers['generic'] = dict()
        registers['baseline']['average_order'] = settings[5]
        registers['capture'] = dict()
        registers['capture']['cfd_relative'] = settings[6] != 0
        registers['capture']['constant_fraction'] = settings[7]
        registers['capture']['pulse_threshold'] = settings[8]
        registers['capture']['slope_threshold'] = settings[9]
        registers['capture']['pulse_area_threshold'] = settings[10]
        registers['capture']['height_type'] = HeightType.from_int(settings[11])
        registers['capture']['threshold_rel2min'] = settings[12] != 0
        registers['capture']['trigger_type'] = TriggerType.from_int(settings[13])
        registers['capture']['event_type'] = PayloadType.from_int(settings[14])
        registers['capture']['height_rel2min'] = settings[15] != 0
        return registers

    @staticmethod
    def parse_mcasettings(settings):
        mca_registers = dict()
        mca_registers['channel'] = settings[0]
        mca_registers['bin_n'] = settings[1]
        mca_registers['last_bin'] = settings[2]
        mca_registers['value'] = McaValueType.from_int(settings[3])
        mca_registers['trigger'] = McaTriggerType.from_int(settings[4])
        mca_registers['ticks'] = settings[5]
        return mca_registers

    def __init__(self, dataset, project, testbench, repo=DEFAULT_REPO_PATH):
        self._data = self.read_dataset(dataset, project, testbench, repo)
        for attribute in self._data.keys():
            setattr(
                self,
                attribute,
                self._data[attribute][0]
            )
        #self.registers = get_registers(project, testbench, repo=repo)

    def slice(self, bounds):
        return self.Slice(self._data, bounds)

    def region(self, point, pre, length):
        return self.slice((point - pre, point - pre + length))

    class Slice:
        @staticmethod
        def index_slice(array, bounds):
            if bounds == 'all':
                return array
            # assumes array (indexs) are sorted
            return array[np.searchsorted(array, bounds[0]):np.searchsorted(array, bounds[1])]

        def apply_bounds(self):
            for attribute in self._data.keys():
                if self._bounds == 'all':
                    setattr(
                        self,
                        attribute,
                        self._data[attribute][0]
                    )
                else:
                    if self._data[attribute][1]:
                        setattr(
                            self,
                            attribute,
                            self.index_slice(self._data[attribute][0], self.bounds) - self.bounds[0]
                        )
                    else:
                        setattr(
                            self,
                            attribute,
                            self._data[attribute][0][self.bounds[0]:self.bounds[1]]
                        )

        def __init__(self, data, bounds='all'):
            self._bounds = bounds
            self._data = data
            self.apply_bounds()

        @property
        def bounds(self):
            return self._bounds

        @bounds.setter
        def bounds(self, value):
            self._bounds = value
            self.apply_bounds()


class Packet:
    def __init__(self, byte_stream):
        self.bytes = byte_stream
        self.ethertype = byte_stream[12:14].view(np.uint16).byteswap()[0]
        self.length = byte_stream[14:16].view(np.uint16)[0]
        self.payload = byte_stream[24:]

        if self.ethertype == 0x88B5:
            if np.bitwise_and(self.payload[5], 0x02):
                self.payload_type = PayloadType.tick
            else:
                self.payload_type = PayloadType.from_int(np.bitwise_and(self.payload[5], 0x0C))
        elif self.ethertype == 0x88B6:
            self.payload_type = PayloadType.mca

        self.frame_sequence = byte_stream[16:18].view(np.int16)[0]
        self.protocol_sequence = byte_stream[18:20].view(np.int16)[0]

    def __repr__(self):
        return 'ethertype:{:X} length:{:d} {:s} frame:{:d} protocol:{:d}'.format(
            self.ethertype, self.length, self.payload_type, self.frame_sequence, self.protocol_sequence)


class EthernetStream:
    def __init__(self, project, testbench, repo=DEFAULT_REPO_PATH):
        dt = np.dtype([('data', np.uint64), ('last', np.int32)])
        enet = Data.fromfile('ethernet', dt, project, testbench, repo)
        lasts = enet['last'].nonzero()[0] + 1
        prev = 0
        end = 0
        self.packets = []
        self.byte_stream = None

        for last in lasts:
            if prev == 0:
                self.byte_stream = np.copy(enet['data'][prev:last]).view(np.uint8)
            else:
                self.byte_stream = np.append(self.byte_stream, np.copy(enet['data'][prev:last]).view(np.uint8))
            prev = last
            start = end
            end = len(self.byte_stream)
            self.packets.append(Packet(self.byte_stream[start:end]))
