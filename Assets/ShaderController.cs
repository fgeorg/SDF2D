using UnityEngine;

[ExecuteInEditMode]
public class ShaderController : MonoBehaviour {

    private static ComputeBuffer pointsBuffer;
    private static ComputeBuffer shapesBuffer;
    private bool _shouldRegenerate;

    struct Shape {
        public int type;
        public Vector2 pointA;
        public Vector2 pointB;
    }
    public void MarkDirty() {
        _shouldRegenerate = true;
    }

    protected void OnValidate() {
        _shouldRegenerate = true;
    }

    // Update is called once per frame
    protected void Update() {
        Material material = GetComponent<Renderer>().sharedMaterial;
        if (_shouldRegenerate) {
            Regenerate();
        }
    }

    protected void Regenerate() {
        _shouldRegenerate = false;

        Material material = GetComponent<Renderer>().sharedMaterial;
        Vector2[] points = new Vector2[100];
        for (int i = 0; i < points.Length; i++) {
            points[i] = new Vector2(i * 5, Mathf.Sin(i * 0.05f) * 200 + 200);
        }
        {
            int stride = System.Runtime.InteropServices.Marshal.SizeOf(typeof(Vector2));
            pointsBuffer?.Dispose();
            pointsBuffer = new ComputeBuffer(points.Length, stride, ComputeBufferType.Default);
            pointsBuffer.SetData(points);
            material.SetBuffer("points", pointsBuffer);
            material.SetInt("nPoints", points.Length);
        }

        {
            Shape[] shapes = new Shape[3];
            shapes[0].type = 0; // line
            shapes[0].pointA = new Vector2(0,30);
            shapes[0].pointB = new Vector2(600,200);
            
            shapes[1].type = 0; // line
            shapes[1].pointA = new Vector2(300,30);
            shapes[1].pointB = new Vector2(700,600);

            
            shapes[2].type = 1; // box
            shapes[2].pointA = new Vector2(600,200);
            shapes[2].pointB = new Vector2(700,600);
            int stride = System.Runtime.InteropServices.Marshal.SizeOf(typeof(Shape));
            shapesBuffer?.Dispose();
            shapesBuffer = new ComputeBuffer(shapes.Length, stride, ComputeBufferType.Default);
            shapesBuffer.SetData(shapes);
            material.SetBuffer("shapes", shapesBuffer);
            material.SetInt("nShapes", shapes.Length);
        }
        Debug.Log("regenerate");
    }

    void OnDestroy() {
        pointsBuffer?.Release();
    }
}