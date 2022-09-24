using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
[RequireComponent(typeof(Slider))]
public class ControlFPSSlider : MonoBehaviour
{
    [SerializeField] PencilPostEffecter _effecter;
    Slider _slider;
    float _beforeValue;

    void Start()
    {
        _slider = GetComponent<Slider>();
        _beforeValue = _slider.value;
    }

    public void ChangeFPS()
    {
        if (Mathf.Abs(_slider.value - _beforeValue) > 0.1f)
        {
            _effecter._fps = Mathf.FloorToInt(_slider.value * 20);
            _effecter.InitializeThresholdTime();
            _beforeValue = _slider.value;
        }
    }

}
