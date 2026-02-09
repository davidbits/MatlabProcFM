//********************************************
//## Commensal Radar Project ##
//
//Filename:
//	PipelinedRCF.cpp
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

#include "PipelinedRCF.h"

using namespace std;

cPipelinedRCF::cPipelinedRCF()
{
	//Default is to have 1 segment just like normal RCF.
	//On construction there are total of 0 samples in the RCF so
	//the segment size is also 0.
	m_uiNSegments = 1;
	m_u64SegmentSize_nSamp = 0;
}

cPipelinedRCF::~cPipelinedRCF()
{
}

cPipelinedRCF::cPipelinedRCF(uint64_t u64NSamples, uint64_t u64SegmentSize_nSamp) : cRCF(u64NSamples)
{
	m_u64SegmentSize_nSamp = u64SegmentSize_nSamp;
	
	//Note the caller is resposible for ensuring that nSamples of the RCF block size is an integer multiple of the segment size
	m_uiNSegments = m_u64NSamples / u64SegmentSize_nSamp;
}

cPipelinedRCF::cPipelinedRCF(uint64_t u64NSamples, unsigned int uiNSegments): cRCF(u64NSamples)
{
	m_uiNSegments = uiNSegments;

	//Note the caller is resposible for ensuring that nSegments in equally divisible into nSamples of the RCF block
	m_u64SegmentSize_nSamp = m_u64NSamples / uiNSegments;	
}

void cPipelinedRCF::setNSegments(unsigned int uiNSegments)
{
	m_uiNSegments = uiNSegments;

	//Note the caller is resposible for ensuring that nSegments in equally divisible into nSamples of the RCF block
	if(uiNSegments)
		m_u64SegmentSize_nSamp = m_u64NSamples / uiNSegments;	
}

void cPipelinedRCF::setSegmentSize(uint64_t u64SegmentSize_nSamp)
{
	m_u64SegmentSize_nSamp = u64SegmentSize_nSamp;
	
	//Note the caller is resposible for ensuring that nSamples of the RCF block size is an integer multiple of the segment size
	if(u64SegmentSize_nSamp)
		m_uiNSegments = m_u64NSamples / u64SegmentSize_nSamp;
}

unsigned int cPipelinedRCF::getNSegments()
{
	return m_uiNSegments;
}

uint64_t cPipelinedRCF::getSegmentSize_nSamp()
{
	return m_u64SegmentSize_nSamp;
}


float* cPipelinedRCF::getRefSegmentFloatPointer(unsigned int uiSegmentNo)
{
	//Return the float pointer to the I sample of the reference channel at the beginning of the uiSegmentNo'th segment

	//size of float * 2 for I and Q samples. Offset is then the size of the segment * segment number
	return m_fpReferenceData + sizeof(float) * 2 * uiSegmentNo * m_u64SegmentSize_nSamp;
}


float* cPipelinedRCF::getSurvSegmentFloatPointer(unsigned int uiSegmentNo)
{
	//Return the float pointer to the I sample of the surveillance channel at the beginning of the uiSegmentNo'th segment

	//size of float * 2 for I and Q samples. Offset is then the size of the segment * segment number
	return m_fpSurveillanceData + sizeof(float) * 2 * uiSegmentNo * m_u64SegmentSize_nSamp;
}

complex<float>* cPipelinedRCF::getRefSegmentComplexFloatPointer(unsigned int uiSegmentNo)
{
	//Return the complex<float> pointer to the sample of the reference channel at the beginning of the uiSegmentNo'th segment

	//Offset is then the size of the segment * segment number
	return m_cfpReferenceData + sizeof(complex<float>) * 2 * uiSegmentNo * m_u64SegmentSize_nSamp;
}

complex<float>* cPipelinedRCF::getSurvSegmentComplexFloatPointer(unsigned int uiSegmentNo)
{
	//Return the complex<float> pointer to the sample of the surveillance channel at the beginning of the uiSegmentNo'th segment

	//Offset is then the size of the segment * segment number
	return m_cfpSurveillanceData + sizeof(complex<float>) * 2 * uiSegmentNo * m_u64SegmentSize_nSamp;
}
