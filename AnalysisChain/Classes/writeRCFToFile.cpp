#include "mex.h"
#include "matrix.h"
#include "C++Includes/CRDataTypes/RCF/RCF.cpp"
#include <fstream>

/* the gateway function */
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if(nrhs!=2)
        mexErrMsgIdAndTxt( "MATLAB:writeRCFToFile:invalidNumInputs", "Two inputs required.");
    
    if(strncmp(mxGetClassName(prhs[0]), "cRCF", 4))
        mexErrMsgIdAndTxt( "MATLAB:writeRCFToFile:invalidClassType", "Class type is not cRCF.");
    
     //mexPrintf("class name = %s\n",mxGetClassName(prhs[0]));
    
    //Get output filename
    int iFilenameLength = mxGetN(prhs[1])*sizeof(mxChar)+1;
    char* cpFilename = new char[iFilenameLength];
    mxGetString(prhs[1], cpFilename, iFilenameLength);
    
    //mexPrintf("Filename = %s\n",cpFilename);
  
    cRCF *pRCF = new cRCF();
    pRCF->setFilename(string(cpFilename));
    
    pRCF->setTimeStamp_us(mxGetScalar(mxGetProperty(prhs[0], 0, "m_TimeStamp_us")));
    pRCF->setFc_Hz(mxGetScalar(mxGetProperty(prhs[0], 0, "m_Fc_Hz")));
    pRCF->setFs_Hz(mxGetScalar(mxGetProperty(prhs[0], 0, "m_Fs_Hz")));
    pRCF->setBw_Hz(mxGetScalar(mxGetProperty(prhs[0], 0, "m_Bw_Hz")));
    pRCF->setNSamples(mxGetScalar(mxGetProperty(prhs[0], 0, "m_NSamples")));

    int iCommentLength = (mxGetN(mxGetProperty(prhs[0], 0, "m_strComment")) + 1);
    char* cpComment = new char[iCommentLength];
    //mexPrintf("Comment length = %i\n", iCommentLength);
    
    mxGetString(mxGetProperty(prhs[0], 0, "m_strComment"), cpComment, iCommentLength); 
    //mexPrintf("Comment = %s\n", cpComment);
    pRCF->setComment(string(cpComment));
    
    pRCF->updateSizes();
    //mexPrintf("Fileinfo = %s\n",pRCF->getInfoString().c_str());
    
    pRCF->allocateArrays();
    
    float* fpRef = pRCF->getReferenceArrayFloatPointer();
    float* fpSurv = pRCF->getSurveillanceArrayFloatPointer();
    
    if(!mxIsSingle(mxGetProperty(prhs[0], 0, "m_fvReferenceData")) || !mxIsSingle(mxGetProperty(prhs[0], 0, "m_fvSurveillanceData")) )
        mexErrMsgIdAndTxt( "MATLAB:writeRCFToFile:incorrectSampleDataFormat", "Sample data is not in single precision complex float form.");
    
    float* fpRealRefData = (float*)mxGetData(mxGetProperty(prhs[0], 0, "m_fvReferenceData"));
    float* fpImagRefData = (float*)mxGetImagData(mxGetProperty(prhs[0], 0, "m_fvReferenceData"));
    float* fpRealSurvData = (float*)mxGetData(mxGetProperty(prhs[0], 0, "m_fvSurveillanceData"));
    float* fpImagSurvData = (float*)mxGetImagData(mxGetProperty(prhs[0], 0, "m_fvSurveillanceData"));
    
    for(int i = 0; i < pRCF->getNSamples(); i++)
    {
        *fpRef = *fpRealRefData;
        fpRef++;
        
        *fpRef = *fpImagRefData;
        fpRef++;
        
        *fpSurv = *fpRealSurvData;
        fpSurv++;
                
        *fpSurv = *fpImagSurvData;
        fpSurv++;

        fpRealRefData++;
        fpImagRefData++;
        fpRealSurvData++;
        fpImagSurvData++;
    }

    ofstream ofs;
    ofs.open(cpFilename, ofstream::binary | ofstream::trunc);
    if(!ofs.is_open())
    {
        mexErrMsgIdAndTxt( "MATLAB:writeRCFToFile:unableToOpenFile", "Unable to open specified file.");
    }

    ofs << (*pRCF);
    
    delete pRCF;
    delete[] cpFilename;
    delete[] cpComment;
    
    ofs.close();
}
