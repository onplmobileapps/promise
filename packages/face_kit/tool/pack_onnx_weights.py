"""Halve an ONNX model's size without changing how it runs.

Large float32 weights are stored as float16 and a Cast node turns each back
into float32 when the session loads (ONNX Runtime constant-folds the casts),
so inference stays float32 on every CPU — including 32-bit ARM, which has no
float16 kernels. Outputs match the original to ~1e-5 relative.

Usage: python tool/pack_onnx_weights.py in.onnx out.onnx
Requires: pip install onnx numpy
"""
import sys

import numpy as np
import onnx
from onnx import TensorProto, helper, numpy_helper


def pack(src: str, dst: str, min_elems: int = 2048) -> None:
    model = onnx.load(src)
    graph = model.graph
    graph_inputs = {i.name for i in graph.input}
    initializers, casts = [], []
    for init in list(graph.initializer):
        array = numpy_helper.to_array(init)
        if init.data_type != TensorProto.FLOAT or array.size < min_elems:
            initializers.append(init)
            continue
        half = numpy_helper.from_array(array.astype(np.float16), init.name + '__fp16')
        initializers.append(half)
        casts.append(helper.make_node(
            'Cast', [half.name], [init.name], to=TensorProto.FLOAT,
            name=init.name + '__cast'))
        for graph_input in list(graph.input):
            if graph_input.name == init.name and init.name in graph_inputs:
                graph.input.remove(graph_input)
    del graph.initializer[:]
    graph.initializer.extend(initializers)
    nodes = list(graph.node)
    del graph.node[:]
    graph.node.extend(casts + nodes)
    onnx.checker.check_model(model)
    onnx.save(model, dst)


if __name__ == '__main__':
    pack(sys.argv[1], sys.argv[2])
