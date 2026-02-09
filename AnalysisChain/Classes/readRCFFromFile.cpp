//********************************************
//## Commensal Radar Project ##
//
//Filename:
//	readRCFFromFile.cpp
//Description
//	
//
//Author:
//	Craig Tong
//	Radar Remote Sensing Group
//	Department of Electrical Engineering
//	University of Cape Town
//	craig.tong@uct.ac.za+
//	Copyright (C) 2014 Craig Tong
//********************************************

#include "mex.h"
#include "matrix.h"
#include "C++Includes/CRDataTypes/RCF/RCF.cpp"
#include <fstream>

/* the gateway function */
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if(nrhs!=3)
        mexErrMsgIdAndTxt( "MATLAB:readRCFFromFile:invalidNumInputs", "4 inputs required. [Filename, sampleOffset, nSamples] (sampleOffset starts at 0)");
    
    if(nlhs!=1)
        mexErrMsgIdAndTxt( "MATLAB:readRCFFromFile:invalidNumOutput", "1 output required. [oRCF]");
    
    //Get input filename
    int iFilenameLength = mxGetN(prhs[0]) * sizeof(mxChar)+1;
    char* cpFilename = new char[iFilenameLength];
    mxGetString(prhs[0], cpFilename, iFilenameLength);
  
    //Create C++ cRCF object
    cRCF *pRCF = new cRCF();
    pRCF->setFilename(string(cpFilename));
    //mexPrintf("Filename = %s\n", cpFilename);
    
    //Now read header and data for specified number of samples from specified sample offset.
    //This calls the C++ RCF code (awesomely fast) and the data ends up in the C++ cRCF object
    if(!pRCF->readHeaderAndData(cpFilename, mxGetScalar(prhs[1]), mxGetScalar(prhs[2])) )
        mexErrMsgIdAndTxt( "MATLAB:readRCFFromFile:unableToReadFile", "Reading from the specified file failed. Make sure that the file exists and is readable.");
    
    //Create Matlab cRCF object as the output 
    //We do this my calling the Matlab cRCF constructor in a mexCallMATLAB call
    //and saving the address of the return object in plhs[0]
    if(mexCallMATLAB(1, &plhs[0], 0, NULL, "cRCF"))
        mexErrMsgIdAndTxt( "MATLAB:readRCFFromFile:unableToCreateRCFObject", "Unable to create cRCF object in Matlab environment.");
    
    //Check the object we have created is of correct class type
    //mexPrintf("Class type = %s\n", mxGetClassName(plhs[0]));
    
    //mxArray* val = mxGetProperty(plhs[0], 0, "m_Fc_Hz");
    mxSetProperty(plhs[0], 0, "m_TimeStamp_us", mxCreateDoubleScalar((double)pRCF->getTimeStamp_us()));
    mxSetProperty(plhs[0], 0, "m_Fc_Hz", mxCreateDoubleScalar((double)pRCF->getFc_Hz()));
    mxSetProperty(plhs[0], 0, "m_Fs_Hz", mxCreateDoubleScalar((double)pRCF->getFs_Hz()));
    mxSetProperty(plhs[0], 0, "m_Bw_Hz", mxCreateDoubleScalar((double)pRCF->getBw_Hz()));
    mxSetProperty(plhs[0], 0, "m_NSamples", mxCreateDoubleScalar((double)pRCF->getNSamples()));
    mxSetProperty(plhs[0], 0, "m_CommentOffset_B", mxCreateDoubleScalar((double)pRCF->getCommentOffset_B()));
    mxSetProperty(plhs[0], 0, "m_CommentLength", mxCreateDoubleScalar((double)pRCF->getCommentLength()));
    mxSetProperty(plhs[0], 0, "m_FileSize_B", mxCreateDoubleScalar((double)pRCF->getFileSize_B()));
    mxSetProperty(plhs[0], 0, " m_strComment", mxCreateString(pRCF->getComment().c_str()));
    mxSetProperty(plhs[0], 0, "m_strFilename", mxCreateString(cpFilename));
    
    delete[] cpFilename;

    //Allocate space for Matlab data arrays
    mxArray* pRefMatlab = mxCreateNumericMatrix(pRCF->getNSamples(), 1, mxSINGLE_CLASS, mxCOMPLEX);
    mxArray* pSurvMatlab = mxCreateNumericMatrix(pRCF->getNSamples(), 1, mxSINGLE_CLASS, mxCOMPLEX);
    
    //Get pointers to the Matlab data
    float* fpRealRefMatlab = (float*)mxGetData(pRefMatlab);
    float* fpImagRefMatlab = (float*)mxGetImagData(pRefMatlab);
    float* fpRealSurvMatlab = (float*)mxGetData(pSurvMatlab);
    float* fpImagSurvMatlab = (float*)mxGetImagData(pSurvMatlab);
    
    //Get pointers to C++ object data arrays
    float* fpRefCpp = pRCF->getReferenceArrayFloatPointer();
    float* fpSurvCpp = pRCF->getSurveillanceArrayFloatPointer();
    
    for(int i = 0; i < pRCF->getNSamples(); i++)
    {
        *fpRealRefMatlab = *fpRefCpp;
        fpRefCpp++;
        
        *fpImagRefMatlab = *fpRefCpp;
        fpRefCpp++;
        
        *fpRealSurvMatlab = *fpSurvCpp;
        fpSurvCpp++;
                
        *fpImagSurvMatlab = *fpSurvCpp;
        fpSurvCpp++;

        fpRealRefMatlab++;
        fpImagRefMatlab++;
        fpRealSurvMatlab++;
        fpImagSurvMatlab++;
    }
    
    //There are a lot of memory copies going on here.
    //Delete RCF objec there to minimise the maximum memory foot bring
    delete pRCF;
    
    mxSetProperty(plhs[0], 0, "m_fvReferenceData", pRefMatlab);
    mxSetProperty(plhs[0], 0, "m_fvSurveillanceData", pSurvMatlab);  
}
