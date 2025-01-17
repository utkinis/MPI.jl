using Test
using MPI

if get(ENV,"JULIA_MPI_TEST_ARRAYTYPE","") == "CuArray"
    import CUDA
    ArrayType = CUDA.CuArray
    synchronize() = CUDA.synchronize()
elseif get(ENV,"JULIA_MPI_TEST_ARRAYTYPE","") == "ROCArray"
    import AMDGPU
    ArrayType = AMDGPU.ROCArray
    function synchronize()
        # TODO: AMDGPU synchronization story is complicated. HSA does not provide a consistent notion of global queues. We need a mechanism for all GPUArrays.jl provided kernels to be synchronized.
        queue = AMDGPU.default_queue()
        barrier = AMDGPU.barrier_and!(queue, AMDGPU.active_kernels(queue))
        # AMDGPU.HIP.hipDeviceSynchronize() # Sync all HIP kernels e.g. BLAS. N.B. this is blocking Julia progress
        wait(barrier)
    end
else
    ArrayType = Array
    synchronize() = nothing
end

# those are the tested MPI types, don't remove !
const MPITestTypes = [
    Char,
    Int8, Int16, Int32, Int64,
    UInt8, UInt16, UInt32, UInt64,
    Float32, Float64, ComplexF32, ComplexF64
]
