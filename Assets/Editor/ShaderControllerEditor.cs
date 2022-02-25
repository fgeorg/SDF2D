using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;


[CustomEditor(typeof(ShaderController))]
public class ShaderControllerEditor : Editor {
    public override void OnInspectorGUI() {
        if (GUILayout.Button("Refresh")) {
            var controller = target as ShaderController;
            controller.MarkDirty();
            EditorUtility.SetDirty(controller);
        }
        DrawDefaultInspector();
    }
}