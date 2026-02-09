//********************************************
//## Commensal Radar Project ##
//
//Filename:
//	SharedPRCFPointer.h
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

#ifndef SHARED_PRCF_POINTER_H
#define SHARED_PRCF_POINTER_H

#include <boost/thread/condition_variable.hpp>
#include <boost/thread/mutex.hpp>
#include <boost/thread/shared_mutex.hpp>

#include <vector>
#include <map>
#include <ctime>

#include "PipelinedRCF.h"

//Pipeline control variables struct
struct cPipelineControlVariables
{
	unsigned int m_uiNextSegmentToProcess; //The number of the next unprocessed PRCF segement (based on segments allocated to threads)
	unsigned int m_uiSegmentsProcessed; //The number of segments processed
	unsigned int m_uiSegmentsAvailableForProcessing; //The number of segments current available for processing

	//Boost mutex and condition variables are not copyable. We need to make a vector of this struct
	//so we use scope pointers to allow it to be copyable.
	boost::mutex m_oPipelineControlMutex; //Locks access for above 3 variables
	boost::condition_variable m_oSegmentToProcessAvailabledCV; //Signalled when the the number of available segement to process goes from 0
															   //to some postive number
	boost::condition_variable m_oAllSegmentsProcessedCV; //Signalled when all segments have been processed.
	
	//Default constructor
	inline cPipelineControlVariables()
	{	
		m_uiNextSegmentToProcess = 0;
		m_uiSegmentsProcessed = 0;
		m_uiSegmentsAvailableForProcessing = 0;
	}

	//Define the assignment operator because the implicit one fails
	//as a result of the mutex abd condtion variable not being copyable
	inline cPipelineControlVariables& operator=(const cPipelineControlVariables& rhs)
	{
		//This class contains boost mutexes and condition variables which are not copyiable
		//We therefore define and explicit copy constructor which omits the mutex copies.
		//Note this copy is not thread safe. It cannot lock the mutexes as it has to 
		//be const. It is inteded for use at the beginning of the application before multiple
		//threads start accessing data

		//Copy values
		m_uiNextSegmentToProcess = rhs.m_uiNextSegmentToProcess;
		m_uiSegmentsProcessed = rhs.m_uiSegmentsProcessed;
		m_uiSegmentsAvailableForProcessing = rhs.m_uiSegmentsAvailableForProcessing;

		return *this;
	}

	//Also define default constructor
	inline cPipelineControlVariables(const cPipelineControlVariables& rhs)
	{
		//This class contains boost mutexes and condition variables which are not copyiable
		//We therefore define and explicit assignment operator which omits the mutex copies.
		//Note this copy is not thread safe. It cannot lock the mutexes as it has to 
		//be const. It is inteded for use at the beginning of the application before multiple
		//threads start accessing data

		//Copy values
		m_uiNextSegmentToProcess = rhs.m_uiNextSegmentToProcess;
		m_uiSegmentsProcessed = rhs.m_uiSegmentsProcessed;
		m_uiSegmentsAvailableForProcessing = rhs.m_uiSegmentsAvailableForProcessing;
	}
};

class cSharedPRCFPointer
{
public:
	cSharedPRCFPointer(unsigned int uiNPipelinedStages);
	cSharedPRCFPointer(const cSharedPRCFPointer &rhs);
	cSharedPRCFPointer& operator=(const cSharedPRCFPointer& rhs);
	~cSharedPRCFPointer(void);

	void setNewPointer(cPipelinedRCF* const pNewPipelinedRCF); 
	cPipelinedRCF* getPointer();
	void deletePointer();
	//Accessing and changing the PipelinedRCF pointer
	//Note this are not inherently thread safe. Use the shared mutex either in a shared lock for getPointer
	//or upgrade_to_unique lock for setNew and delete pointer.

	//The following are call by producer and consumer threads to determine when they can start 
	//working with the shared pointer. They are not thread safe and should be used along with 
	//m_oPRCFPointerSharedMutex and the condition variable when isAvailableFor___() functions return false.
	bool isAvailableForProducer();
	bool isAvailableForConsumer();
	void setAvailableForProducer();
	void setAvailableForConsumer();

	//The following functions provide pipe control an encapsulated thread safe way
	void segmentProcessed(unsigned int uiPipelineStageNo); 
	//Signal that a segment has been processed for this pipeline stage.
	//Increment m_uiNUnprocessedAvailableSegements for the next stage no if it exists
	//If m_uiNUnprocessedAvailableSegements was 0 signal the SegmentToProcessAvaialble condition variable
	//Decrement this stages m_uiNUnprocessedAvailableSegements.

	void waitForSegmentToProcess(unsigned int uiPipelineStageNo);
	//Blocks until there is a segment available to process.

	void waitForAllSegmentsProcessed(unsigned int uiPipelineStageNo);
	//Blocks until all segments in the specified pipeline stage have been processed

	int getNextSegmentNoToProcess(unsigned int uiPipelineStageNo);
	//Once at least one new segment is available in the PRCF
	//determined using waitForSegmentToProcess() we get the number of the next segment to process.
	//This function automatically increments its return value when called. 
	//Returns -1 if there is no more work to allocate.

	//Reference access to variables for thread safety
	boost::shared_mutex& getPointerSharedMutex();
	boost::condition_variable_any& getAvailableForProducerCV();
	boost::condition_variable_any& getAvailableForConsumerCV();

	//Access and set storedTime variable
	void addStoredTime(const std::string& strLabel, const clock_t newStoredTime); //Push a stored time back on to the vector
	clock_t getStoredTime(const std::string& strLabel); //Get a stored time at the specified label if it exists in the map
	void clearStoredTimes(); //clear the map

	void resetPipelineControlVariables();
	//resets the pipeline control variables for each stage in the pipeline.
	//This is used when the PRCF pointer is changed or recycled and used with new data from the begnining of the pipeline.

private:
	//Shared pointer variables
	cPipelinedRCF *m_pPRCF; //The Pipelined RCF pointer which is shared between threads
	boost::shared_mutex m_oPRCFPointerSharedMutex; //Shared mutex lock for above pointer (can be upgraded to unique lock with boost locks)
	boost::condition_variable_any m_oAvailableForProducerCV; //Signaled when the pointer is ready to be passed to a producer thread.
	boost::condition_variable_any m_oAvailableForConsumerCV; //Signaled when the pointer is ready to be passed to a consumer thread.
	//We need to use condition_variable_any because of the shared mutex

	bool m_bAvailableForProducerNotConsumer; //Is the pointer ready to be pass to a producer thread also not ready for consumer thread

	std::vector<cPipelineControlVariables> m_vPipelineControlVariables;
	//A vector of pipeline control variables resized to the number of pipeline stages

	unsigned int m_uiNPipelineStages; //The number of pipeline stages that this Pipelined RCF will be processed over.

	std::map<std::string, clock_t> m_storedTimesMap; //A map to to store a time label and the corresponding time.
	//This can be use to measure the performance of the processing chain. The programmer can decide how this is to be used.
	boost::mutex m_oStoredTimesMutex;
};

#endif //SHARED_PRCF_POINTER_H
