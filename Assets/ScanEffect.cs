using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ScanEffect : MonoBehaviour
{
    public Material postEffectMat;
    [Range(5, 15)]
    public int speed = 5;

    RaycastHit hitInfo;
    float progress;
    bool isScanning;

    void Start()
    {
        Camera.main.depthTextureMode = Camera.main.depthTextureMode | DepthTextureMode.Depth;
        progress = 0f;
        isScanning = false;
    }

    void Update()
    {
        if (Input.GetMouseButtonDown(0) == true)
        {
            var ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            if (Physics.Raycast(ray, out hitInfo, 2000) == true)
            {
                if (isScanning == true)
                    return;

                postEffectMat.SetVector("_ClickPosition", hitInfo.point);
                StartCoroutine(StartScan());
                //Debug.Log(hitInfo.point);
            }
        }
       
        //var PV = Camera.main.projectionMatrix * Camera.main.worldToCameraMatrix;
        //PV = PV.inverse;
        //var p = Camera.main.projectionMatrix;
        //var v = Camera.main.worldToCameraMatrix;

        //var pvR = p.inverse * v.inverse;
        //Debug.Log((p * v).inverse);
        //Debug.Log(v.inverse * p.inverse);
    }

    IEnumerator StartScan()
    {
        isScanning = true;
        progress = 0f;

        float scanTime = 0f;
        
        while(scanTime <= 3.0f)
        {
            progress += speed * Time.deltaTime;
            scanTime += Time.deltaTime;
            yield return null;
        }
        
        isScanning = false;
        progress = 0f;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        var PV = Camera.main.projectionMatrix * Camera.main.worldToCameraMatrix;
        PV = PV.inverse;
        postEffectMat.SetMatrix("_InverseVPMatrix", PV);
        postEffectMat.SetMatrix("_InversePMatrix", Camera.main.projectionMatrix.inverse);
        postEffectMat.SetMatrix("_InverseWMatrix", Camera.main.worldToCameraMatrix.inverse);
        postEffectMat.SetFloat("_Progress", progress);
        
        Graphics.Blit(source, destination, postEffectMat);
    }
}
