import os

import pytest

from CPAC.image_utils import spatial_smoothing
from CPAC.pipeline import nipype_pipeline_engine as pe
import CPAC.utils.test_init as test_utils
from CPAC.utils.test_mocks import configuration_strategy_mock


@pytest.mark.skip(reason="needs refactoring")
def test_smooth():
    test_name = "test_smooth_nodes"

    c, strat = configuration_strategy_mock(method="FSL")
    num_strat = 0

    # build the workflow
    workflow = pe.Workflow(name=test_name)
    workflow.base_dir = c.workingDirectory
    workflow.config["execution"] = {
        "hash_method": "timestamp",
        "crashdump_dir": os.path.abspath(c.crashLogDirectory),
    }

    spatial_smoothing(
        workflow,
        "mean_functional",
        "functional_brain_mask",
        "mean_functional_smooth".format(),
        strat,
        num_strat,
        c,
    )

    func_node, func_output = strat["mean_functional"]
    mask_node, mask_output = strat["functional_brain_mask"]

    spatial_smoothing(
        workflow,
        (func_node, func_output),
        (mask_node, mask_output),
        "mean_functional_smooth_nodes".format(),
        strat,
        num_strat,
        c,
    )

    workflow.run()

    correlations = []

    for fwhm in c.fwhm:
        out_name1 = os.path.join(
            c.workingDirectory,
            test_name,
            f"_fwhm_{fwhm}/mean_functional_smooth_0/",
            "sub-M10978008_ses-NFB3_task-test_bold_calc_tshift_resample_volreg_calc_tstat_maths.nii.gz",
        )

        out_name2 = os.path.join(
            c.workingDirectory,
            test_name,
            f"_fwhm_{fwhm}/mean_functional_smooth_nodes_0/",
            "sub-M10978008_ses-NFB3_task-test_bold_calc_tshift_resample_volreg_calc_tstat_maths.nii.gz",
        )

        correlations.append(test_utils.pearson_correlation(out_name1, out_name2) > 0.99)

    assert all(correlations)


@pytest.mark.skip(reason="needs refactoring")
def test_smooth_mapnode():
    test_name = "test_smooth_mapnode"

    c, strat = configuration_strategy_mock(method="FSL")
    num_strat = 0

    # build the workflow
    workflow = pe.Workflow(name=test_name)
    workflow.base_dir = c.workingDirectory
    workflow.config["execution"] = {
        "hash_method": "timestamp",
        "crashdump_dir": os.path.abspath(c.crashLogDirectory),
    }

    spatial_smoothing(
        workflow,
        "dr_tempreg_maps_files",
        "functional_brain_mask",
        "dr_tempreg_maps_smooth".format(),
        strat,
        num_strat,
        c,
        input_image_type="func_derivative_multi",
    )

    func_node, func_output = strat["dr_tempreg_maps_files"]
    mask_node, mask_output = strat["functional_brain_mask"]

    spatial_smoothing(
        workflow,
        (func_node, func_output),
        (mask_node, mask_output),
        "dr_tempreg_maps_smooth_nodes".format(),
        strat,
        num_strat,
        c,
        input_image_type="func_derivative_multi",
    )

    workflow.run()

    correlations = []

    for fwhm in c.fwhm:
        dr_spatmaps_after_smooth1 = [
            os.path.join(
                c.workingDirectory,
                test_name,
                f"_fwhm_{fwhm}/dr_tempreg_maps_smooth_multi_0/mapflow",
                f"_dr_tempreg_maps_smooth_multi_0{n}/temp_reg_map_000{n}_maths.nii.gz",
            )
            for n in range(0, 10)
        ]

        dr_spatmaps_after_smooth2 = [
            os.path.join(
                c.workingDirectory,
                test_name,
                f"_fwhm_{fwhm}/dr_tempreg_maps_smooth_nodes_multi_0/mapflow",
                f"_dr_tempreg_maps_smooth_nodes_multi_0{n}/temp_reg_map_000{n}_maths.nii.gz",
            )
            for n in range(0, 10)
        ]

        correlations += [
            test_utils.pearson_correlation(file1, file2) > 0.99
            for file1, file2 in zip(
                dr_spatmaps_after_smooth1, dr_spatmaps_after_smooth2
            )
        ]

    assert all(correlations)
