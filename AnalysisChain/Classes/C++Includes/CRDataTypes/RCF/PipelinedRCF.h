//********************************************
//## Commensal Radar Project ##
//
//Filename:
//	PipelinedRCF.h
//Description
//	A derivative of the cRCF class which adds functionilty for using a single RCF block in a pipelined manner.
//
//Author:
//	Craig Tong
//	Radar Remote Sensing Group
//	Department of Electrical Engineering
//	University of Cape Town
//	craig.tong@uct.ac.za
//********************************************

#ifndef PIPELINED_RCF_H
#define PIPELINED_RCF_H

#include "RCF.h"
#include <complex>

class cPipelinedRCF : public cRCF
{

public:
	cPipelinedRCF();
	~cPipelinedRCF();
	cPipelinedRCF(uint64_t u64NSamples, uint64_t u64SegmentSize_nSamp);
	cPipelinedRCF(uint64_t u64NSamples, unsigned int uiNSegments);

	void setNSegments(unsigned int uiNSegments);
	void setSegmentSize(uint64_t u64SegmentSize_nSamp);

	unsigned int getNSegments();
	uint64_t getSegmentSize_nSamp();

	//Return the float pointer to the I sample of the reference channel at the beginning of the uiSegmentNo'th segment
	float* getRefSegmentFloatPointer(unsigned int uiSegmentNo);
	//Return the float pointer to the I sample of the surveillance channel at the beginning of the uiSegmentNo'th segment
	float* getSurvSegmentFloatPointer(unsigned int uiSegmentNo);

	//Return the complex<float> pointer to the sample of the reference channel at the beginning of the uiSegmentNo'th segment
	std::complex<float>* getRefSegmentComplexFloatPointer(unsigned int uiSegmentNo);
	//Return the complex<float> pointer to the sample of the surveillance channel at the beginning of the uiSegmentNo'th segment
	std::complex<float>* getSurvSegmentComplexFloatPointer(unsigned int uiSegmentNo);

protected:
	unsigned int m_uiNSegments; //The number of setments
	uint64_t m_u64SegmentSize_nSamp; //The number of samples in the a segment
};

#endif //PIPELINED_RCF_H