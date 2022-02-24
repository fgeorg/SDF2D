using UnityEngine;

[ExecuteInEditMode]
public class ShaderController : MonoBehaviour {

    private ComputeBuffer buffer;
    private bool _shouldRegenerate;
    public void MarkDirty() {
        _shouldRegenerate = true;
    }

    protected void OnValidate() {
        _shouldRegenerate = true;
    }

    // Update is called once per frame
    protected void Update() {
        if (_shouldRegenerate) {
            Regenerate();
        }
    }

    protected void Regenerate() {
        _shouldRegenerate = false;
        
        Material material = GetComponent<Renderer>().sharedMaterial;
        Vector2[] points = new Vector2[100];
        for (int i = 0; i < points.Length; i++) {
            points[i] = new Vector2(i * 50, Mathf.Sin(i * 0.5f) * 200 + 200);
        }
        int stride = System.Runtime.InteropServices.Marshal.SizeOf(typeof(Vector2));
        buffer = new ComputeBuffer(points.Length, stride, ComputeBufferType.Default);
        buffer.SetData(points);
        material.SetBuffer("points", buffer);
        material.SetInt("nPoints", points.Length);
    }

    void OnDestroy() {
        buffer.Release();
    }
}