//********************************************
//## Commensal Radar Project ##
//
//Filename:
//	RCF.h
//Description
//	A block 2 channel of phase coherent data intended to feed the processing channel of a commensal radar for a single transmitter/receiver pair.
//
//Author:
//	Craig Tong
//	Radar Remote Sensing Group
//	Department of Electrical Engineering
//	University of Cape Town
//	craig.tong@uct.ac.za
//********************************************

#ifndef RCF_H
#define RCF_H

#ifndef __unix__
#include <WinSock2.h>
typedef __int64 int64_t;
typedef unsigned __int64 uint64_t;
#else
#include <sys/socket.h>
#include <inttypes.h>
#include <unistd.h>
#endif

#include <fstream>
#include <complex>

class cRCF
{
protected:
	char m_cpFileType[4]; //string to confirm filetype
	int64_t m_i64TimeStamp_us; //time at which file was captured at the first sample (specified in micro seconds from epoc)
	unsigned int m_uiFc_Hz; //centre frequency of signal (Hz)
	unsigned int m_uiFs_Hz; //sampling frequency that signal was captured at (Hz)
	unsigned int m_uiBw_Hz; //bandwidth content of signal (Hz)
	uint64_t m_u64NSamples; //number of samples contained in the file
	uint64_t m_u64CommentOffset_B; //byte offset of the comment string in the file
	unsigned int m_uiCommentLength; //length of comment string
	uint64_t m_u64FileSize_B; //size of the file in bytes

	float* m_fpReferenceData; //reference channel data float ordered reference I, reference Q etc.
	float* m_fpSurveillanceData; //surveillance channel data type float ordered surveillance I, surveillance Q etc.

	//Complex pointer types pointing to the same memory as the the float types
	std::complex<float>* m_cfpReferenceData;
	std::complex<float>* m_cfpSurveillanceData;

	std::string m_strComment; //some comments about this data
	std::string m_strFilename;

	bool m_bAllocated;
	uint64_t m_u64AllocatedSize_nSamp; //The number of samples that was allocated for

	char* serialiseHeader();
	void deserialiseHeader(char* cpSerialisedHeader);

public:
	static const int HEADER_SIZE = 52;
	static const int DEFAULT_TCP_PORT = 5002;

    enum HeaderOffsets
    {
        FILE_TYPE = 0,
        TIME_STAMP = 4,
        FC_HZ = 12,
        FS_HZ = 16,
        BW_HZ = 20,
        N_SAMPLES =  24,
        COMMENT_OFFSET = 32,
        COMMENT_LENGTH = 40,
        FILE_SIZE = 44
    };

	cRCF();
	cRCF(uint64_t u6NSamples);
	cRCF(const cRCF&);
	~cRCF();

	void allocateArrays();
	void deallocateArrays();
	void reAllocateArrays();
	uint64_t getAllocatedSize_nSamp(); //Return the number of samples that the RCF was allocated for.
	void copyHeader(const cRCF&);
	void updateSizes();

	//Accessors:
    const char* getFileType() const;
    int64_t getTimeStamp_us() const;
    unsigned int getFc_Hz() const;
    unsigned int getFs_Hz() const;
    unsigned int getBw_Hz() const;
    uint64_t getNSamples() const;
    uint64_t getCommentOffset_B() const;
    unsigned int getCommentLength() const;
    uint64_t getFileSize_B() const;
    std::string getInfoString() const;
    float getSurveillanceDataPoint(uint64_t) const;
    float getReferenceDataPoint(uint64_t) const;
    float* getSurveillanceArrayFloatPointer() const;
    float* getReferenceArrayFloatPointer() const;
    std::complex<float>* getSurveillanceArrayComplexFloatPointer() const;
    std::complex<float>* getReferenceArrayComplexFloatPointer() const;
    std::string getFilename() const;
    std::string stringFromTimeStamp() const;
    static std::string stringFromTimeStamp(int64_t i64TimeStamp_us);
    std::string stringFromTimeStampAtSampleOffset(uint64_t u64SampleOffset)const;
    std::string getComment() const;
    bool isAllocated() const;
    int64_t getTimeStampAtSampleOffset_us(uint64_t u64SampleOffset) const;
    uint64_t getFileOffsetAtRefSampleOffset(uint64_t u64RefSampleOffset) const;
    uint64_t getFileOffsetAtSurvSampleOffset(uint64_t u64SurvSampleOffset) const;

	//mutators
	void setTimeStamp_us(int64_t i64TimeStamp_us);
	void setFc_Hz(unsigned int uiFc_Hz); 
	void setFs_Hz(unsigned int uiFs_Hz); 
	void setBw_Hz(unsigned int uiBw_Hz); 
	void setNSamples(uint64_t u64NSamples);
	void setComment(std::string strComment);
	void setFilename(std::string strFilename);
	void remix(std::complex<float> *pcfData, unsigned uiLength, unsigned &uiIndex, double dFrequencyShift_Hz);

	//File IO
	bool readHeader(std::string strFilename, bool bReadCommentString = true);
	bool readHeader(std::ifstream& ifs, bool bReadCommentString = true);

	uint64_t readData(std::string strFilename, uint64_t u64StartSample, uint64_t u64NSamples);
	uint64_t readData(std::ifstream& ifs, uint64_t u64StartSample, uint64_t u64NSamples);

	uint64_t readHeaderAndData(std::string strFilename, uint64_t u64StartSample, uint64_t u64NSamples, bool bReadCommentString = true);

	bool writeHeader(std::string strFilename, bool bWriteCommentString = true);
	bool writeHeader(std::ofstream& ofs, bool bWriteCommentString = true);

	friend std::ifstream& operator>>(std::ifstream& ifs, cRCF& rhs);
	friend std::ofstream& operator<<(std::ofstream& ofs, cRCF& rhs);

	//Sockets
#ifndef __unix__
	void sendFilename(SOCKET &socket);
	void recvFilename(SOCKET &socket);
	friend SOCKET& operator<<(SOCKET& socket, cRCF& rhs);
	friend SOCKET& operator>>(SOCKET& socket, cRCF& rhs);
#else
	void sendFilename(int &socket);
	void recvFilename(int &socket);
	friend int& operator<<(int& socket, cRCF& rhs );
	friend int& operator>>(int& socket, cRCF& rhs );
#endif

};

#endif // RCF_H

