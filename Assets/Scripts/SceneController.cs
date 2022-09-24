using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class SceneController : MonoBehaviour
{
    enum Scene
    {
        Raymarching,
        Sketch,
        PostSketch,
        PostSketchAnim,
    }

    public void ToRaymarchigScene()
    {
        ChangeScene(Scene.Raymarching);
    }

    public void ToSketchScene()
    {
        ChangeScene(Scene.Sketch);
    }

    public void ToPostSketchScene()
    {
        ChangeScene(Scene.PostSketch);
    }

    public void ToPostSketchAnimScene()
    {
        ChangeScene(Scene.PostSketchAnim);
    }


    void ChangeScene(Scene next)
    {
        switch (next)
        {
            case Scene.Raymarching:
                SceneManager.LoadScene("Raymating1");
                break;
            case Scene.Sketch:
                SceneManager.LoadScene("Sketch");
                break;
            case Scene.PostSketch:
                SceneManager.LoadScene("PostSketch");
                break;
            case Scene.PostSketchAnim:
                SceneManager.LoadScene("PostSketchFlip");
                break;
        }
    }
}
