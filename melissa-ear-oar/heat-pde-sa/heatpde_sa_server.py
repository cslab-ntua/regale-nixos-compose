import logging
import random

from melissa.server.sensitivity_analysis import SensitivityAnalysisServer

logger = logging.getLogger("melissa")
random.seed(123)


class HeatPDEServerSA(SensitivityAnalysisServer):
    """
    Use-case specific server
    """
    def draw_parameters(self):
        Tmin, Tmax = self.study_options['parameter_range']
        param_set = []
        for _ in range(self.study_options['nb_parameters']):
            param_set.append(random.uniform(Tmin, Tmax))
        return param_set
