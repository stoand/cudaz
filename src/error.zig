const std = @import("std");
const Type = std.builtin.Type;

const c = @import("c.zig");
const cuda = c.cuda;
const nvrtc = c.nvrtc;
const curand = c.curand;
const utils = @import("utils.zig");

const CudaErrorEnum: type = ErrorsToEnum(u32, cuda);
const NvrtcErrorEnum: type = ErrorsToEnum(u32, nvrtc);
const CurandErrorEnum: type = ErrorsToEnum(u32, curand);
pub const CudaError = utils.EnumToError(CudaErrorEnum);
pub const NvrtcError = utils.EnumToError(NvrtcErrorEnum);
pub const CurandError = utils.EnumToError(CurandErrorEnum);

fn ErrorsToEnum(comptime tag_type: type, comptime cimport: type) type {
    const prefix = switch (cimport) {
        cuda => "CUDA_ERROR",
        curand => "CURAND_STATUS",
        nvrtc => "NVRTC_ERROR",
        else => @compileError("Can either be cuda / nvrtc type"),
    };
    switch (@typeInfo(cimport)) {
        .@"struct" => |x| {
            const null_decls: []const Type.Declaration = &.{};
            var errors: [100]Type.EnumField = undefined;
            var counter: usize = 0;
            @setEvalBranchQuota(100000);
            for (x.decls) |declaration| {
                if (std.mem.startsWith(u8, declaration.name, prefix)) {
                    errors[counter] = .{ .name = declaration.name, .value = @field(cimport, declaration.name) };
                    counter += 1;
                }
            }

            return @Type(Type{ .@"enum" = .{ .tag_type = tag_type, .fields = errors[0..counter], .decls = null_decls, .is_exhaustive = false } });
        },
        else => @compileError("Cannot generate error type"),
    }
}

pub fn fromCudaErrorCode(error_code: u32) CudaError.Error!void {
    if (error_code == 0) return;
    const val = CudaError.from_error_code(error_code).?;
    return val;
}
pub fn fromNvrtcErrorCode(error_code: u32) NvrtcError.Error!void {
    if (error_code == 0) return;
    const val = NvrtcError.from_error_code(error_code).?;
    return val;
}

pub fn fromCurandErrorCode(error_code: u32) CurandError.Error!void {
    if (error_code == 0) return;
    const val = CurandError.from_error_code(error_code).?;
    return val;
}

test "Test_Gen_Errors_Cuda" {
    //zig test error.zig -lcuda -I /usr/local/cuda-12.2/targets/x86_64-linux/include
    const test_cuda_error_enums = ErrorsToEnum(u32, cuda);
    const test_some_struct = utils.EnumToError(test_cuda_error_enums);
    try std.testing.expect(test_some_struct.from_error_code(1) orelse unreachable == error.CUDA_ERROR_INVALID_VALUE);
}

test "Test_Gen_Errors_NVRTC" {
    //zig test error.zig -lcuda -I /usr/local/cuda-12.2/targets/x86_64-linux/include
    const test_cuda_error_enums = ErrorsToEnum(u32, nvrtc);
    const test_some_struct = utils.EnumToError(test_cuda_error_enums);
    try std.testing.expect(test_some_struct.from_error_code(1) orelse unreachable == error.NVRTC_ERROR_OUT_OF_MEMORY);
}

test "Test_Gen_Errors_Curand" {
    //zig test error.zig -lcuda -I /usr/local/cuda-12.2/targets/x86_64-linux/include
    const test_cuda_error_enums = ErrorsToEnum(u32, curand);
    const test_some_struct = utils.EnumToError(test_cuda_error_enums);
    try std.testing.expect(test_some_struct.from_error_code(100) orelse unreachable == error.CURAND_STATUS_VERSION_MISMATCH);
}
