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


class EventType(Enum):
    @staticmethod
    def from_int(value):
        if value == 0:
            return EventType.peak
        elif value == 1:
            return EventType.area
        elif value == 2:
            return EventType.pulse
        elif value == 3:
            return EventType.trace
        else:
            raise AttributeError()

    peak = 0
    area = 1
    pulse = 2
    trace = 3


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
    registers['capture']['event_type'] = EventType.from_int(settings[14])
    return registers


class EventStream:
    def __init__(self, project, testbench, file='eventstream', repo=DEFAULT_REPO_PATH):
        self._stream64 = Data.fromfile(file, np.int64, project, testbench, repo)

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

    def __init__(self, dataset, project, testbench, repo=DEFAULT_REPO_PATH):
        self._data = self.read_dataset(dataset, project, testbench, repo)
        for attribute in self._data.keys():
            setattr(
                self,
                attribute,
                self._data[attribute][0]
            )
        self.registers = get_registers(project, testbench, repo=repo)

    def slice(self, bounds):
        return self.Slice(self._data, bounds)

    def region(self, point, pre, length):
        return self.slice((point-pre, point-pre+length))

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
                            self.index_slice(self._data[attribute][0], self.bounds)-self.bounds[0]
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
