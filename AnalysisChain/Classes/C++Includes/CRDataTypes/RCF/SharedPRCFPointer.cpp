//********************************************
//## Commensal Radar Project ##
//
//Filename:
//	SharedPRCFPointer.cpp
//  Description
//	A class which encapsulates a cPipelinedRCF pointer and has mechanisms for safe shared access of the pointer across threads.
//  *Note: requires classes from Boost.Thread. (Written using version 1.46.1)
//
//Author:
//	Craig Tong
//	Radar Remote Sensing Group
//	Department of Electrical Engineering
//	University of Cape Town
//	craig.tong@uct.ac.za
//********************************************

#include "SharedPRCFPointer.h"
#include <boost/thread/locks.hpp>

#include <iostream>

using namespace std;

cSharedPRCFPointer::cSharedPRCFPointer(unsigned int uiNPipelinedStages)
{
	m_pPRCF = NULL;

	//To start with the producer will have to produce RCF data so set available for producer
	m_bAvailableForProducerNotConsumer = true;

	//Resize the PipeControlVariables vector to the number of pipeline stages
	m_vPipelineControlVariables.resize(uiNPipelinedStages);
}

cSharedPRCFPointer::cSharedPRCFPointer(const cSharedPRCFPointer &rhs)
{
	//This class contains boost mutexes and condition variables which are not copyiable
	//We therefore define and explicit copy constructor which omits the mutex copies.
	//Note this copy is not thread safe. It cannot lock the mutexes as it has to 
	//be const. It is inteded for use at the beginning of the application before multiple
	//threads start accessing data

	m_pPRCF = rhs.m_pPRCF;
	m_uiNPipelineStages = rhs.m_uiNPipelineStages;
	m_storedTimesMap = rhs.m_storedTimesMap;
	m_bAvailableForProducerNotConsumer = rhs.m_bAvailableForProducerNotConsumer;

	//Copy the PipeControlVariables vector
	m_vPipelineControlVariables = rhs.m_vPipelineControlVariables;
}

cSharedPRCFPointer& cSharedPRCFPointer::operator=(const cSharedPRCFPointer& rhs)
{
	//This class contains boost mutexes and condition variables which are not copyiable
	//We therefore define and explicit assignment operator which omits the mutex copies.
	//Note this assignment is not thread safe. It cannot lock the mutexes as it has to 
	//be const. It is inteded for use at the beginning of the application before multiple
	//threads start accessing data

	m_pPRCF = rhs.m_pPRCF;
	m_uiNPipelineStages = rhs.m_uiNPipelineStages;
	m_storedTimesMap = rhs.m_storedTimesMap;
	m_bAvailableForProducerNotConsumer = rhs.m_bAvailableForProducerNotConsumer;

	//Copy the PipeControlVariables vector
	m_vPipelineControlVariables = rhs.m_vPipelineControlVariables;

	return *this;
}

cSharedPRCFPointer::~cSharedPRCFPointer(void)
{
	//delete the pointer on destruction
	deletePointer();
}

void cSharedPRCFPointer::resetPipelineControlVariables()
{
	//Reset the variables that control the pipeline flow to an initial state for every pipeline stage
	for(vector<cPipelineControlVariables>::iterator itr = m_vPipelineControlVariables.begin(); itr < m_vPipelineControlVariables.end(); itr++)
	{
		boost::unique_lock<boost::mutex> oLock(itr->m_oPipelineControlMutex);//lock the mutex to alter variables
		itr->m_uiNextSegmentToProcess = 0; //Before processing starts the next segment to process is zero
		itr->m_uiSegmentsAvailableForProcessing = 0; //Because no processing has happened yet there are 0 segments available for processing
		itr->m_uiSegmentsProcessed = 0; //No segments have been processed yet.
	}
}

void cSharedPRCFPointer::setNewPointer(cPipelinedRCF* const pNewPipelinedRCF)
{
	//Delete the pointer if it exists to avoid memory leaks
	if(m_pPRCF)
		delete m_pPRCF;

	//The pointer is now clear so set the new pointer
	m_pPRCF = pNewPipelinedRCF;

	//Reset the pipeline control variables as there is totally new data in this element now.
	resetPipelineControlVariables();
}

cPipelinedRCF* cSharedPRCFPointer::getPointer()
{
	//Return pointer
	return m_pPRCF;
}

void cSharedPRCFPointer::deletePointer()
{
	//Delete and set to null.
	delete m_pPRCF;
	m_pPRCF = NULL;
}

bool cSharedPRCFPointer::isAvailableForProducer()
{
	return m_bAvailableForProducerNotConsumer;
}

bool cSharedPRCFPointer::isAvailableForConsumer()
{
	return !m_bAvailableForProducerNotConsumer;
}

void cSharedPRCFPointer::setAvailableForProducer()
{
	//Notify all threads waiting on the PointerCleared condition variable
	m_bAvailableForProducerNotConsumer = true;
	m_oAvailableForProducerCV.notify_all();
}

void cSharedPRCFPointer::setAvailableForConsumer()
{
	//Notify all threads waiting on PointerSet condition variable
	m_bAvailableForProducerNotConsumer = false;
	m_oAvailableForConsumerCV.notify_all();
}

boost::shared_mutex& cSharedPRCFPointer::getPointerSharedMutex()
{
	//Return reference to the shared mutex for the PRCF pointer
	return m_oPRCFPointerSharedMutex;
}

boost::condition_variable_any& cSharedPRCFPointer::getAvailableForProducerCV()
{
	//Return reference to the pointer set condition variable
	return m_oAvailableForProducerCV;
}

boost::condition_variable_any& cSharedPRCFPointer::getAvailableForConsumerCV()
{
	//Return reference to the pointer cleared condition variable
	return m_oAvailableForConsumerCV;
}

//The following functions provide pipe control 
void cSharedPRCFPointer::segmentProcessed(unsigned int uiPipelineStageNo)
{
	//Signal that a segment has been processed for this pipeline stage.
	//Increment m_uiNUnprocessedAvailableSegements for the next stage no if it exists
	//If m_uiNUnprocessedAvailableSegements was 0 signal the SegmentToProcessAvaialble condition variable
	//Decrement this stages m_uiNUnprocessedAvailableSegements.

	{//Begin scope for lock of this pipeline stag
		boost::unique_lock<boost::mutex> oLock(m_vPipelineControlVariables[uiPipelineStageNo].m_oPipelineControlMutex);
		//Increment the number of segments processing
		m_vPipelineControlVariables[uiPipelineStageNo].m_uiSegmentsProcessed++;

	}//End scope for lock of this pipeline stage

	//If a next processing stage exists signal that there is a new segment available
	try
	{
		//Lock its mutex
		boost::unique_lock<boost::mutex> oLock(m_vPipelineControlVariables.at(uiPipelineStageNo + 1).m_oPipelineControlMutex);

		//Increment the number of segments available for processing in that pipeline stage
		m_vPipelineControlVariables.at(uiPipelineStageNo + 1).m_uiSegmentsAvailableForProcessing++;

		//If there were no segments available before this increment then signal the condition variable
		//Note we call notify 1 because only 1 segment has been made available and so only 1 proc thread can 
		//start processing that segment.
		if(m_vPipelineControlVariables.at(uiPipelineStageNo + 1).m_uiSegmentsAvailableForProcessing == 1)
			m_vPipelineControlVariables.at(uiPipelineStageNo + 1).m_oSegmentToProcessAvailabledCV.notify_one();
	}
	catch(...){}

	//If all segments are processed notify the condition variable for that
	if(m_vPipelineControlVariables[uiPipelineStageNo].m_uiSegmentsProcessed == m_pPRCF->getNSegments())
		m_vPipelineControlVariables[uiPipelineStageNo].m_oAllSegmentsProcessedCV.notify_all();
}

void cSharedPRCFPointer::waitForSegmentToProcess(unsigned int uiPipelineStageNo)
{
	//Blocks until there is a segment available to process.
	//isWorkLeft should be called first to ensure that there are segments left in the PRCF.
	boost::unique_lock<boost::mutex> oLock(m_vPipelineControlVariables[uiPipelineStageNo].m_oPipelineControlMutex);

	if(m_vPipelineControlVariables[uiPipelineStageNo].m_uiSegmentsAvailableForProcessing)
	{
		//If there are segments available return immediately

		//A segment will be allocated to a thread on the return of this function so decrement the number of segments available for processing
		m_vPipelineControlVariables[uiPipelineStageNo].m_uiSegmentsAvailableForProcessing--;

		return;
	}
	else
	{
		//Otherwise wait on the condition variable
		m_vPipelineControlVariables[uiPipelineStageNo].m_oSegmentToProcessAvailabledCV.wait(oLock);

		//A segment will be allocated to a thread on the return of this function so decrement the number of segments available for processing
		m_vPipelineControlVariables[uiPipelineStageNo].m_uiSegmentsAvailableForProcessing--;
	}
}

void cSharedPRCFPointer::waitForAllSegmentsProcessed(unsigned int uiPipelineStageNo)
{
	//Blocks until all segments in the specified pipeline stage have been processed

	boost::unique_lock<boost::mutex> oLock(m_vPipelineControlVariables[uiPipelineStageNo].m_oPipelineControlMutex);

	//If the pipelined RCF pointer has been cleared this doesn't really make sense so just return
	if(!m_pPRCF)
		return;

	//If all segments are processed return immediately
	if(m_vPipelineControlVariables[uiPipelineStageNo].m_uiSegmentsProcessed == m_pPRCF->getNSegments())
		return;

	//Otherwise wait on the condition variable
	m_vPipelineControlVariables[uiPipelineStageNo].m_oAllSegmentsProcessedCV.wait(oLock);
}

int cSharedPRCFPointer::getNextSegmentNoToProcess(unsigned int uiPipelineStageNo)
{
	//Once at least one new segment is available in the PRCF
	//determined using waitForSegmentsPacked() we get the number of the next segment to process.
	//This function automatically increments its return value when called. 
	//Returns -1 if there is no more work to be done on this PipelinedRCF

	boost::unique_lock<boost::mutex> oLock(m_vPipelineControlVariables[uiPipelineStageNo].m_oPipelineControlMutex);

	//In some cases another thread or this thread may have cleared the pointer.
	//If this is the case then return -1 as there is no PRCF to process
	if(!m_pPRCF)
		return -1;

	//Otherwise check if we have allocated all possible work in the PRCF
	if(m_vPipelineControlVariables[uiPipelineStageNo].m_uiNextSegmentToProcess >= m_pPRCF->getNSegments())
	{
		//If true return -1 to indicate to the worker thread that there is no more work for this
		//RCF.
		return -1;
	}

	//Otherwise return the number of the next segment to process:

	//Store the value to be returned
	unsigned int uiReturnValue = m_vPipelineControlVariables[uiPipelineStageNo].m_uiNextSegmentToProcess;

	//Increment the counter
	m_vPipelineControlVariables[uiPipelineStageNo].m_uiNextSegmentToProcess++;
	//The counter now stores the value that will be given to the next thread to call this function

	//return the value before the increment.
	return uiReturnValue;
}

void cSharedPRCFPointer::addStoredTime(const std::string& strLabel, const clock_t newStoredTime)
{
	boost::unique_lock<boost::mutex> oLock(m_oStoredTimesMutex);

	//This used operator[] of the map template class. If the key (strLabel) already exists in the map then
	//the element pair is updated to the new time. If the key does not exist then a new element is created.
	m_storedTimesMap[strLabel] = newStoredTime;
}

clock_t cSharedPRCFPointer::getStoredTime(const std::string& strLabel)
{
	boost::unique_lock<boost::mutex> oLock(m_oStoredTimesMutex);

	//Find the the key in the map and store in itr
	map<string, clock_t>::iterator itr = m_storedTimesMap.find(strLabel);

	//Check that the key was found, i.e. itr != the end iterator
	if(itr != m_storedTimesMap.end())
	{
		//Return the time
		return itr->second;
	}
	else
	{
		//Otherwise return 0;
		return 0;
	}
}

void cSharedPRCFPointer::clearStoredTimes()
{
	boost::unique_lock<boost::mutex> oLock(m_oStoredTimesMutex);

	//Clear the map.
	m_storedTimesMap.clear();
}