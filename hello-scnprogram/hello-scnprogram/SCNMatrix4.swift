//
//  SCNMatrix4.swift
//  hello-scnprogram
//

import SceneKit

/*
 
 [ a  b  0 ]     [ a  b  0  0 ]
 [ c  d  0 ]  -> [ c  d  0  0 ]
 [ e  f  1 ]     [ 0  0  1  0 ]
                 [ e  f  0  1 ]
 
 */
extension SCNMatrix4
{
    init(_ affineTransform: CGAffineTransform)
    {
        self.init()
        m11 = Float(affineTransform.a)
        m12 = Float(affineTransform.b)
        m21 = Float(affineTransform.c)
        m22 = Float(affineTransform.d)
        m41 = Float(affineTransform.tx)
        m42 = Float(affineTransform.ty)
        m33 = 1
        m44 = 1
    }
}
