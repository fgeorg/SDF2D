using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ShaderController : MonoBehaviour {
    [SerializeField] float _smoothness = 40;
    private static ComputeBuffer pointsBuffer;
    private static ComputeBuffer shapesBuffer;
    private bool _shouldRegenerate;

    struct Shape {
        public int type;
        public Vector2 vecA;
        public Vector2 vecB;
        public Vector3 color;
    }
    public void MarkDirty() {
        _shouldRegenerate = true;
    }

    protected void OnValidate() {
        _shouldRegenerate = true;
    }

    // Update is called once per frame
    protected void Update() {
        _shouldRegenerate = true;
        Material material = GetComponent<Renderer>().sharedMaterial;
        if (_shouldRegenerate) {
            Regenerate();
        }
    }

    protected void Regenerate() {
        _shouldRegenerate = false;

        Material material = GetComponent<Renderer>().sharedMaterial;
        List<Shape> shapes = new List<Shape>();
        foreach (Transform child in transform) {
            var color = child.GetComponent<SpriteRenderer>()?.color ?? Color.white;
            shapes.Add(new Shape {
                type = 1, // box
                vecA = child.position,
                vecB = child.lossyScale,
                color = new Vector3(color.r, color.g, color.b),
            });
        }

        int stride = System.Runtime.InteropServices.Marshal.SizeOf(typeof(Shape));
        shapesBuffer?.Dispose();
        shapesBuffer = new ComputeBuffer(shapes.Count, stride, ComputeBufferType.Default);
        shapesBuffer.SetData(shapes);
        material.SetBuffer("shapes", shapesBuffer);
        material.SetInt("nShapes", shapes.Count);
        material.SetFloat("smoothness", _smoothness);
    }

    void OnDestroy() {
        pointsBuffer?.Release();
    }
}