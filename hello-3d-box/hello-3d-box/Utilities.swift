//
//  Utilities.swift
//  hello-3d-box
//
//  Created by Rhys Balevicius.
//

import simd

struct Vertex
{
    var position: vector_float4
    var colour: vector_float4
    
    init(_ position: vector_float4, _ colour: vector_float4)
    {
        self.position = position
        self.colour = colour
    }
}

struct Uniforms
{
    var modelViewProjectionMatrix: matrix_float4x4
}

struct Matrix
{
    static func scalingMatrix(_ scale: Float) -> matrix_float4x4
    {
     
        let col0 = SIMD4<Float>(scale, 0,    0,   0)
        let col1 = SIMD4<Float>(0,   scale,  0,   0)
        let col2 = SIMD4<Float>(0,     0,  scale, 0)
        let col3 = SIMD4<Float>(0,     0,    0,   1)
        
        return matrix_float4x4(col0, col1, col2, col3)
    }
    
    static func translationMatrix(_ position: SIMD3<Float>) -> matrix_float4x4
    {
        let x = position.x
        let y = position.y
        let z = position.z
        
        let col0 = SIMD4<Float>(1, 0, 0, 0)
        let col1 = SIMD4<Float>(0, 1, 0, 0)
        let col2 = SIMD4<Float>(0, 0, 1, 0)
        let col3 = SIMD4<Float>(x, y, z, 1)
        
        return matrix_float4x4(col0, col1, col2, col3)
    }
    
    static func rotationMatrix(_ angle: Float, _ axis: vector_float3) -> matrix_float4x4
    {
        var X = vector_float4(0, 0, 0, 0)
        X.x = axis.x * axis.x + (1 - axis.x * axis.x) * cos(angle)
        X.y = axis.x * axis.y * (1 - cos(angle)) - axis.z * sin(angle)
        X.z = axis.x * axis.z * (1 - cos(angle)) + axis.y * sin(angle)
        X.w = 0.0
        
        var Y = vector_float4(0, 0, 0, 0)
        Y.x = axis.x * axis.y * (1 - cos(angle)) + axis.z * sin(angle)
        Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * cos(angle)
        Y.z = axis.y * axis.z * (1 - cos(angle)) - axis.x * sin(angle)
        Y.w = 0.0
        
        var Z = vector_float4(0, 0, 0, 0)
        Z.x = axis.x * axis.z * (1 - cos(angle)) - axis.y * sin(angle)
        Z.y = axis.y * axis.z * (1 - cos(angle)) + axis.x * sin(angle)
        Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * cos(angle)
        Z.w = 0.0
        
        let W = vector_float4(0, 0, 0, 1)
        
        return matrix_float4x4(X, Y, Z, W)
    }
    
    // object space -> world space
//    static func modelMatrix() -> matrix_float4x4
//    {
//        let scaled = scalingMatrix(0.5)
//        let rotateX = rotationMatrix(SIMD3<Float>(1, 0, 0))
//        let rotateY = rotationMatrix(SIMD3<Float>(0, 1, 0))
        
//        return matrix_multiply(matrix_multiply(rotateX, rotateY), scaled)
//    }
    
    // world space -> camera space
    static func viewMatrix() -> matrix_float4x4
    {
        let cameraPosition = vector_float3(0, 0, -3)
        
        return translationMatrix(cameraPosition)
    }
    
    // camera space -> clip space
    static func projectionMatrix(near: Float, far: Float, aspect: Float, fovy: Float) -> matrix_float4x4
    {
        let scaleY = 1 / tan(fovy * 0.5)
        let scaleX = scaleY / aspect
        let scaleZ = -(far + near) / (far - near)
        let scaleW = -2 * far * near / ( far - near)
        
        let X = vector_float4(scaleX, 0,    0,     0)
        let Y = vector_float4(0,    scaleY, 0,     0)
        let Z = vector_float4(0,      0,  scaleZ, -1)
        let W = vector_float4(0,      0,  scaleW,  0)
        
        return matrix_float4x4(X, Y, Z, W)
    }
}
