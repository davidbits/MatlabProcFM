//********************************************
//## Commensal Radar Project ##
//
//Filename:
//	RCF.cpp
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

//rcf.cpp (raw capture format)
#define _USE_MATH_DEFINES
#include <cmath>
#include <iostream>
#include <time.h>
#include <sstream>
#include <string.h>
#include "RCF.h"

using namespace std;

cRCF::cRCF()
{    
    strncpy(m_cpFileType, "rcf\0", 4);

    m_i64TimeStamp_us = 0;
    m_uiFc_Hz = 0;
    m_uiFs_Hz = 0;
    m_uiBw_Hz = 0;
    m_u64NSamples = 0;
    m_u64CommentOffset_B = 0;
    m_uiCommentLength = 0;
    m_u64FileSize_B = 0;
    m_fpSurveillanceData = NULL;
    m_fpReferenceData = NULL;
    m_cfpReferenceData = NULL;
    m_cfpSurveillanceData = NULL;

    m_strComment = "";
    m_strFilename = "";

    m_bAllocated = false;
    m_u64AllocatedSize_nSamp = 0;
}

cRCF::cRCF(uint64_t u64NSamples)
{
    //Initialised and allocate space for a N samples.
    m_u64NSamples = u64NSamples;

    m_i64TimeStamp_us = 0;
    m_uiFc_Hz = 0;
    m_uiFs_Hz = 0;
    m_uiBw_Hz = 0;
    m_u64CommentOffset_B = 0;
    m_uiCommentLength = 0;
    m_u64FileSize_B = 0;
    m_fpSurveillanceData = NULL;
    m_fpReferenceData = NULL;
    m_cfpReferenceData = NULL;
    m_cfpSurveillanceData = NULL;

    m_strComment = "";
    m_strFilename = "";

    m_bAllocated = false;
    m_u64AllocatedSize_nSamp = 0;

    allocateArrays();
}

cRCF::cRCF(const cRCF& rhs)
{	
    copyHeader(rhs);

    if(rhs.m_bAllocated)
    {
        allocateArrays();

        memcpy (m_fpSurveillanceData, rhs.m_fpSurveillanceData, 8 * m_u64NSamples);
        memcpy (m_fpReferenceData, rhs.m_fpReferenceData, 8 * m_u64NSamples);
    }
    else
    {
        m_bAllocated = false;
        m_fpSurveillanceData = NULL;
        m_fpReferenceData = NULL;
        m_cfpReferenceData = NULL;
        m_cfpSurveillanceData = NULL;
        m_u64AllocatedSize_nSamp = 0;
    }
}

cRCF::~cRCF()
{
    deallocateArrays();
}

void cRCF::allocateArrays()
{
    if(m_bAllocated)
    {
        //Deallocate first
        deallocateArrays();
    }

    //Allocate array space
    m_fpReferenceData = new float[m_u64NSamples * 2]; //x2 for I and Q values
    m_fpSurveillanceData = new float[m_u64NSamples * 2];

    //Set the complex float pointers to the same space
    m_cfpReferenceData = reinterpret_cast<complex<float>* >(m_fpReferenceData);
    m_cfpSurveillanceData = reinterpret_cast<complex<float>* >(m_fpSurveillanceData);

    m_u64AllocatedSize_nSamp = m_u64NSamples;
    m_bAllocated = true;
}

void cRCF::reAllocateArrays()
{
    //Allocates if unallocated.
    //Deallocates and allocates if nSamples is different to current allocation size.
    //Does nothing if nSamples is the same as current allocation size.

    if(m_bAllocated)
    {
        if(m_u64NSamples == m_u64AllocatedSize_nSamp)
            return;
        else
            deallocateArrays(); //Deallocate first
    }

    //Allocate array space
    m_fpReferenceData = new float[m_u64NSamples * 2]; //x2 for I and Q values
    m_fpSurveillanceData = new float[m_u64NSamples * 2];

    //Set the complex float pointers to the same space
    m_cfpReferenceData = reinterpret_cast<complex<float>* >(m_fpReferenceData);
    m_cfpSurveillanceData = reinterpret_cast<complex<float>* >(m_fpSurveillanceData);

    m_u64AllocatedSize_nSamp = m_u64NSamples;
    m_bAllocated = true;
}

void cRCF::deallocateArrays()
{
    if(!m_bAllocated)
    {
        return;
    }

    {
        delete [] m_fpSurveillanceData;
        delete [] m_fpReferenceData;
    }

    m_fpReferenceData = NULL;
    m_fpSurveillanceData = NULL;
    m_cfpReferenceData = NULL;
    m_cfpSurveillanceData = NULL;

    m_u64AllocatedSize_nSamp = 0;
    m_bAllocated = false;
}

uint64_t cRCF::getAllocatedSize_nSamp()
{
    //Return the number of samples that the RCF was allocated for.
    //If unallocated return 0.

    if(m_bAllocated)
        return m_u64AllocatedSize_nSamp;
    else
        return 0;
}

void cRCF::copyHeader(const cRCF& rhs)
{
    strncpy (m_cpFileType, rhs.m_cpFileType, 4);
    m_i64TimeStamp_us = rhs.m_i64TimeStamp_us;
    m_uiFc_Hz = rhs.m_uiFc_Hz;
    m_uiFs_Hz = rhs.m_uiFs_Hz;
    m_uiBw_Hz = rhs.m_uiBw_Hz;
    m_u64NSamples = rhs.m_u64NSamples;
    m_u64CommentOffset_B = rhs.m_u64CommentOffset_B;
    m_uiCommentLength = rhs.m_uiCommentLength;
    m_u64FileSize_B = rhs.m_u64FileSize_B;
    m_strComment = rhs.m_strComment;
}
void cRCF::updateSizes()
{
    m_uiCommentLength = m_strComment.length() + 1; //+1 to include null terminating character
    m_u64CommentOffset_B = (uint64_t)HEADER_SIZE + m_u64NSamples * 4 * sizeof(float);
    m_u64FileSize_B = m_u64CommentOffset_B + m_uiCommentLength;
}

string cRCF::getInfoString() const
{
    stringstream ss;

    ss << "File Info:" << endl;
    ss << "--------------------------------------------------" << endl << endl;

    ss << "File type =                " << m_cpFileType << endl;
    ss << "Time stamp at 1st sample = " << stringFromTimeStamp() << endl;
    ss << "Centre frenquency =        " << m_uiFc_Hz << " Hz" << endl;
    ss << "Sample rate =              " << m_uiFs_Hz << " Hz" << endl;
    ss << "Analogue bandwidth =       " << m_uiBw_Hz << " Hz" << endl;
    ss << "No of samples =            " << m_u64NSamples << endl;
    ss << "Comment string offset =    " << m_u64CommentOffset_B << " bytes" << endl;
    ss << "Comment string length =    " << m_uiCommentLength << " characters" << endl;
    ss << "Total file size =          " << m_u64FileSize_B << " bytes" << endl << endl;

    ss << "Comment string:" << endl;
    ss << "--------------------------------------------------" << endl << endl;
    ss <<  m_strComment << endl << endl;
    ss << "--------------------------------------------------" << endl << endl;

    return ss.str();
}

//-----------------------------------------------------------------------------
//Accessors:
//-----------------------------------------------------------------------------

const char* cRCF::getFileType() const
{
    return m_cpFileType;
}

int64_t cRCF::getTimeStamp_us() const
{
    return m_i64TimeStamp_us;
}

unsigned int cRCF::getFc_Hz() const
{
    return m_uiFc_Hz;
}

unsigned int cRCF::getFs_Hz() const
{
    return m_uiFs_Hz;
}

unsigned int cRCF::getBw_Hz() const
{
    return m_uiBw_Hz;
}

uint64_t cRCF::getNSamples() const
{
    return m_u64NSamples;
}

uint64_t cRCF::getCommentOffset_B() const
{
    return m_u64CommentOffset_B;
}

unsigned int cRCF::getCommentLength() const
{
    return m_uiCommentLength;
}

uint64_t cRCF::getFileSize_B() const
{
    return m_u64FileSize_B;
}

float cRCF::getReferenceDataPoint(uint64_t x) const
{
    return m_fpReferenceData[x];
}

float cRCF::getSurveillanceDataPoint(uint64_t x) const
{
    return m_fpSurveillanceData[x];
}


float* cRCF::getSurveillanceArrayFloatPointer() const
{
    return m_fpSurveillanceData;
}

float* cRCF::getReferenceArrayFloatPointer() const
{
    return m_fpReferenceData;
}

complex<float>* cRCF::getSurveillanceArrayComplexFloatPointer() const
{
    return m_cfpSurveillanceData;
}

complex<float>* cRCF::getReferenceArrayComplexFloatPointer() const
{
    return m_cfpReferenceData;
}

string cRCF::getFilename() const
{
    return m_strFilename;
}

string cRCF::stringFromTimeStamp() const
{
    //make string from timestamp in header
    return stringFromTimeStamp(m_i64TimeStamp_us);
}

string cRCF::stringFromTimeStamp(int64_t i64TimeStamp_us)
{
    //make string from specified timestamp
    time_t ztime = i64TimeStamp_us / 1000000;
    struct tm* timeInfo;
    timeInfo = localtime ( &ztime );

    char timeStrA[21];

    strftime ( timeStrA, 21, "%Y-%m-%dT%H.%M.%S.", timeInfo );

    char timeStrB[31];
    sprintf(timeStrB, "%s%.6llu", timeStrA, (long long unsigned int)i64TimeStamp_us % 1000000 );

    return string(timeStrB, 26);
}

string cRCF::stringFromTimeStampAtSampleOffset(uint64_t u64SampleOffset) const
{
    return stringFromTimeStamp(getTimeStampAtSampleOffset_us(u64SampleOffset));
}

string cRCF::getComment() const
{
    return m_strComment;
}

bool cRCF::isAllocated() const
{
    return m_bAllocated;
}

//Return the time stamp at a given offset where the time stamp at offset 0 is the time
//contained in the header.
int64_t cRCF::getTimeStampAtSampleOffset_us(uint64_t u64SampleOffset) const
{
    //Header time stamp + sample offset * sampling period
    return  m_i64TimeStamp_us + u64SampleOffset * 1000000 / m_uiFs_Hz;
}

//Return the file offset of the specified sample offset for the reference channel.
//Note samples consist of an in-phase float followed by a quadrature float forming an IQ pair.
//This returns the offset to the beginning of that 8 byte IQ pair.
uint64_t cRCF::getFileOffsetAtRefSampleOffset(uint64_t u64RefSampleOffset) const
{
    return HEADER_SIZE + (u64RefSampleOffset * sizeof(float) * 4);
}

//Return the file offset of the specified sample offset for the surveillance channel.
//Note samples consist of an in-phase float followed by a quadrature float forming an IQ pair.
//This returns the offset to the beginning of that 8 byte IQ pair.
uint64_t cRCF::getFileOffsetAtSurvSampleOffset(uint64_t u64SurvSampleOffset) const
{
    return HEADER_SIZE + (u64SurvSampleOffset * sizeof(float) * 4) + sizeof(float) * 2;
    //*4 is 2 floats (I and Q) and 2 channels (reference and surveillance)
    //+8 is because the surveillance IQ pair follows the reference pair
}

//-----------------------------------------------------------------------------
//Mutators:
//-----------------------------------------------------------------------------

void cRCF::setTimeStamp_us(int64_t i64TimeStamp_us)
{
    m_i64TimeStamp_us = i64TimeStamp_us;
}

void cRCF::setFc_Hz(unsigned int uiFc_Hz)
{
    m_uiFc_Hz = uiFc_Hz;
}

void cRCF::setFs_Hz(unsigned int uiFs_Hz) 
{
    m_uiFs_Hz = uiFs_Hz;
}

void cRCF::setBw_Hz(unsigned int uiBw_Hz)
{
    m_uiBw_Hz = uiBw_Hz;
}

void cRCF::setNSamples(uint64_t u64NSamples)
{
    m_u64NSamples  = u64NSamples;
}

void cRCF::setComment(string strComment)
{
    m_strComment = strComment;
}
void cRCF::setFilename(string strFilename)
{
    m_strFilename = strFilename;
}

void cRCF::remix(complex<float> *pcfData, unsigned uiLength, unsigned &uiIndex, double dFrequencyShift_Hz)
{
    double cdW = dFrequencyShift_Hz * -2 * M_PI / (double)m_uiFs_Hz;
    complex<float> j = complex<float> (0,1);

    for(unsigned i = 0; i < uiLength; i++)
    {
        pcfData[i] *= exp(j * complex<float> (cdW * uiIndex++, 0));
    }
}

//-----------------------------------------------------------------------------
//File IO:
//-----------------------------------------------------------------------------

bool cRCF::readHeader(string strFilename, bool bReadCommentString)
{
    //This method sets this objects members according according to the file header specified by strFilename
    //It will sets m_strComment to the comment stored at the end of the file depend on the second argument (true by default).

    ifstream ifs;
    ifs.open(strFilename.c_str(), ifstream::binary);

    bool bReadSuccess = readHeader(ifs, bReadCommentString);

    ifs.close();

    return bReadSuccess;
}

bool cRCF::readHeader(ifstream& ifs, bool bReadCommentString)
{
    //This method sets this objects members according according to the file object ifs. It is useful if moreinformation is going
    //to be read from the file after this function call.
    //It will sets m_strComment to the comment stored at the end of the file depend on the second argument (true by default).

    if(!ifs.is_open())
    {
        return false;
    }

    //Go to beginning of the file
    ifs.seekg(0);

    //Read the header as a continous char array
    char* cpHeader = new char[HEADER_SIZE];
    ifs.read(cpHeader, HEADER_SIZE);

    //Deserialise the array and assign to members
    deserialiseHeader(cpHeader);

    delete [] cpHeader;

    if(bReadCommentString)
    {
        //Read the comment string at the end of the file.
        char *cpComment = new char[m_uiCommentLength];
        ifs.seekg(m_u64CommentOffset_B); //go to comments offset in file
        ifs.read(cpComment, m_uiCommentLength);
        m_strComment = string(cpComment, m_uiCommentLength - 1); //-1 to remove null terminating character in C string

        delete [] cpComment;
    }

    return true;
}


uint64_t cRCF::readData(string strFilename, uint64_t u64StartSample, uint64_t u64NSamples)
{
    //This function reads data into the object arrays from a file specified by the filename
    //The number of samples read is returned.

    ifstream ifs;
    ifs.open(strFilename.c_str(), ifstream::binary);

    uint64_t nSamplesRead = readData(ifs, u64StartSample, u64NSamples);

    ifs.close();

    return nSamplesRead;
}

uint64_t cRCF::readData(ifstream& ifs, uint64_t u64StartSample, uint64_t u64NSamples)
{
    //This function reads data into the object arrays from a file specified an ifstream object
    //This is useful if there is a file that is already open for example if readHeader was called
    //first.
    //The number of samples read is returned.

    if(!ifs.is_open())
    {
        cout << "cRCF::readData() Error ifstream object is not open to file" << endl;
        return 0;
    }

    //Get the number of samples as specified in the file header
    ifs.seekg(N_SAMPLES);
    uint64_t u64NSamplesInFile;
    ifs.read((char*)&u64NSamplesInFile, sizeof(u64NSamplesInFile));

    //check that request number of samples does not excede the number contained in the file
    if(u64StartSample + u64NSamples > u64NSamplesInFile)
    {
        cout << "Rcf::readData() Warning requested nSamp excedes end of file. Trimming range to EOF" << endl;
        u64NSamples = u64NSamplesInFile - u64StartSample;
        m_u64NSamples = u64NSamples;
    }
    else
    {
        //Otherwise adjust header values to comply with sample selection in header
        m_u64NSamples = u64NSamples;
        m_u64FileSize_B = u64NSamples * 16 + HEADER_SIZE + m_uiCommentLength;
    }

    //Get the number of samples as specified in the file header
    ifs.seekg(TIME_STAMP);
    int64_t i64FileTimeStamp_us;
    ifs.read((char*)&i64FileTimeStamp_us, sizeof(i64FileTimeStamp_us));

    //Set timestamp
    m_i64TimeStamp_us =  i64FileTimeStamp_us + u64StartSample * 1e6 / m_uiFs_Hz;

    allocateArrays();

    //go to the beginning of the data block
    ifs.seekg(HEADER_SIZE + u64StartSample * 4 * sizeof(float));
    for(unsigned int x = 0; x < m_u64NSamples; x++)
    {
        ifs.read((char*) &(m_fpReferenceData[2 * x]), 8);
        ifs.read((char*) &(m_fpSurveillanceData[2 * x]), 8);
    }

    return m_u64NSamples; //return the number of samples read
}

uint64_t cRCF::readHeaderAndData(string sFilename, uint64_t u64StartSample, uint64_t u64NSamples, bool bReadCommentString)
{
    //read header
    if(!readHeader(sFilename, bReadCommentString))
        return 0;

    //read data
    return readData(sFilename, u64StartSample, u64NSamples);
}

bool cRCF::writeHeader(string strFilename, bool bWriteCommentString)
{
    //This funtion writes the header and optionally the comment string to a file specicied by a filename.
    //If the file is likely to be appended with samples then the comment string option should disabled as
    //it must exist at the end of the file.

    ofstream ofs;
    //Open file in binary mode and truncate (remove any data in a pre-existing file)
    ofs.open(strFilename.c_str(), ofstream::binary | ofstream::trunc);

    bool bWriteSuccess = writeHeader(ofs, bWriteCommentString);

    ofs.close();

    return bWriteSuccess;
}

bool cRCF::writeHeader(ofstream& ofs, bool bWriteCommentString)
{
    //This funtion writes the header and optionally the comment string to a file pointed to by the already opened file object ofs.
    //This is intended for when a ofstream object already exists for example when data has been written to the file and the header
    //must be added.
    //If the file is likely to be appended with samples then the comment string option should disabled as it must exist at the end
    //of the file.

    if(!ofs.is_open())
        return false;

    //Go to beginning of the file
    ofs.seekp(0);

    //Recalculate comment length, offset and filesize
    updateSizes();

    //Serialise the header into a char array
    char* cpSerialisedHeader = serialiseHeader();

    //Write the header to file
    ofs.write(cpSerialisedHeader, HEADER_SIZE);

    //Write the comment string if required.
    if(bWriteCommentString)
    {
        //Go to the end of the IQ sample block
        ofs.seekp(m_u64CommentOffset_B);

        ofs.write(m_strComment.c_str(), m_uiCommentLength);
        //Note m_uiCommentLength is m_strComment.length() + 1 to include the null terminated character (see updateSizes())
    }

    return true;
}

//-----------------------------------------------------------------------------
//Friend Functions:
//-----------------------------------------------------------------------------

ifstream& operator>>(ifstream& ifs, cRCF& rhs)
{
    //This shift operator will pack a cRCF object with information from a ifstream file object
    //opened to an RCF file. Note opening a non RCF file could be problem as large amounts of
    //memory could be allocated. Fail safes for this still need to be implemented.

    if(!ifs.is_open())
    {
        cout << "cRCF::operator>>() Error: ifstream file object is not open to file." << endl;
        return ifs;
    }

    //Go to beginning of the file
    ifs.seekg(0);

    //Read the header as a continous char array
    char* cpHeader = new char[cRCF::HEADER_SIZE];
    ifs.read(cpHeader, cRCF::HEADER_SIZE);

    //Deserialise the array and assign to members
    rhs.deserialiseHeader(cpHeader);

    delete [] cpHeader;

    //Allocate array space for the samples
    //Note this must be done after the file header values have been read specifically nSamples
    rhs.allocateArrays();

    //Read the data
    for(uint64_t x = 0; x < rhs.m_u64NSamples; x++)
    {
        ifs.read((char*) &(rhs.m_fpReferenceData[2 * x]), 8);
        ifs.read((char*) &(rhs.m_fpSurveillanceData[2 * x]), 8);
    }

    //Read the comment string at the end of the file.
    char *cpComment = new char[rhs.m_uiCommentLength];
    ifs.seekg(rhs.m_u64CommentOffset_B); //go to comments offset in file
    ifs.read(cpComment, rhs.m_uiCommentLength);
    rhs.m_strComment = string(cpComment, rhs.m_uiCommentLength - 1); //-1 to remove null terminating character in C string

    delete [] cpComment;

    return ifs;
}

ofstream& operator<<(ofstream& ofs, cRCF& rhs)
{
    //This shift operator will write a RCF file using the open ofstream file object argument
    //opened to an RCF file.

    if(!ofs.is_open())
    {
        cout << "cRCF::operator>>() Error: ofsteam object is not open to file." << endl;
        return ofs;
    }

    //Go to beginning of the file
    ofs.seekp(0);

    //Recalculate comment length, offset and filesize
    rhs.updateSizes();

    //Serialise the header into a char array
    char* cpSerialisedHeader = rhs.serialiseHeader();

    //Write the header to file
    ofs.write(cpSerialisedHeader, cRCF::HEADER_SIZE);

    //Write Data
    char* cpRefPtr = (char*)rhs.m_fpReferenceData;
    char* cpSurvPtr = (char*)rhs.m_fpSurveillanceData;

    for(unsigned int x = 0; x < rhs.m_u64NSamples; x++)
    {
        //Write IQ pairs of reference and surveillance channel alternatively starting with reference
        ofs.write(cpRefPtr, 2 * sizeof(float));
        cpRefPtr += 2 * sizeof(float);

        ofs.write(cpSurvPtr, 2 * sizeof(float));
        cpSurvPtr += 2 * sizeof(float);
    }

    //Write comment string
    ofs.write(rhs.m_strComment.c_str(), rhs.m_uiCommentLength);
    //Note m_uiCommentLength is m_strComment.length() + 1 to include the null terminated character (see updateSizes())

    return ofs;
}

#ifndef __unix__
SOCKET& operator>>(SOCKET& socket, cRCF& rhs)
#else
int& operator>>(int& socket, cRCF& rhs )
#endif
{
    unsigned int uiReadTotal = 0;

    char cpSerialisedHeader[cRCF::HEADER_SIZE];
    char *cPtr = cpSerialisedHeader;
    unsigned int uiBytesLeft = cRCF::HEADER_SIZE;
    int iBytesRead;

    //read header to char array
    while (uiBytesLeft)
    {
        iBytesRead = recv(socket, cPtr, uiBytesLeft, MSG_WAITALL);
        cPtr += iBytesRead;
        uiReadTotal += iBytesRead;
        uiBytesLeft -= iBytesRead;
    }

    rhs.deserialiseHeader(cpSerialisedHeader);

    rhs.allocateArrays();

    char* cpRefPtr = (char*)rhs.m_fpReferenceData;
    char* cpSurvPtr = (char*)rhs.m_fpSurveillanceData;

    //read data
    for(unsigned int x = 0; x < rhs.m_u64NSamples; x++)
    {
        uiBytesLeft = 2 * sizeof(float);
        while (uiBytesLeft)
        {
            iBytesRead = recv(socket, cpRefPtr, uiBytesLeft, MSG_WAITALL);
            cpRefPtr += iBytesRead;
            uiReadTotal += iBytesRead;
            uiBytesLeft -= iBytesRead;
        }

        uiBytesLeft = 2 * sizeof(float);
        while (uiBytesLeft)
        {
            iBytesRead = recv(socket, cpSurvPtr, uiBytesLeft, MSG_WAITALL);
            cpSurvPtr += iBytesRead;
            uiReadTotal += iBytesRead;
            uiBytesLeft -= iBytesRead;
        }
    }

    char* cpCommentString = new char[rhs.m_uiCommentLength];
    uiBytesLeft = rhs.m_uiCommentLength;
    cPtr = cpCommentString;
    while (uiBytesLeft)
    {
        iBytesRead = recv(socket, cPtr, uiBytesLeft, MSG_WAITALL);
        cPtr += iBytesRead;
        uiReadTotal += iBytesRead;
        uiBytesLeft -= iBytesRead;
    }

    rhs.m_strComment = string(cpCommentString, rhs.m_uiCommentLength - 1); //-1 to remove null terminating character

    delete [] cpCommentString;
    return socket;
}

#ifndef __unix__
SOCKET& operator<<(SOCKET& socket, cRCF& rhs)
#else
int& operator<<(int& socket, cRCF& rhs )
#endif
{
    rhs.updateSizes();

    unsigned int uiWriteTotal = 0;

    //Serialise header and write to socket
    char *cpSerialisedHeader = rhs.serialiseHeader(); //Note this function allocates space. The pointer must be deleted.
    char *cPtr = cpSerialisedHeader;
    unsigned int uiBytesLeft = cRCF::HEADER_SIZE;
    int iBytesWritten;

    while (uiBytesLeft)
    {
        iBytesWritten = send(socket, cPtr, uiBytesLeft, 0);
        cPtr += iBytesWritten;
        uiWriteTotal += iBytesWritten;
        uiBytesLeft -= iBytesWritten;
    }

    delete[] cpSerialisedHeader;

    //Write Data
    char* cpRefPtr = (char*)rhs.m_fpReferenceData;
    char* cpSurvPtr = (char*)rhs.m_fpSurveillanceData;

    for(unsigned int x = 0; x < rhs.m_u64NSamples; x++)
    {
        uiBytesLeft = 2 * sizeof(float);
        while (uiBytesLeft)
        {
            iBytesWritten = send(socket, cpRefPtr, uiBytesLeft, 0);
            cpRefPtr += iBytesWritten;
            uiWriteTotal += iBytesWritten;
            uiBytesLeft -= iBytesWritten;
        }

        uiBytesLeft = 2 * sizeof(float);
        while (uiBytesLeft)
        {
            iBytesWritten = send(socket, cpSurvPtr, uiBytesLeft, 0);
            cpSurvPtr += iBytesWritten;
            uiWriteTotal += iBytesWritten;
            uiBytesLeft -= iBytesWritten;
        }
    }


    char *cpCommentString = new char[rhs.m_uiCommentLength];
    strncpy(cpCommentString, rhs.m_strComment.c_str(), rhs.m_uiCommentLength);
    cPtr = cpCommentString;
    uiBytesLeft = rhs.m_uiCommentLength;

    while (uiBytesLeft)
    {
        iBytesWritten = send(socket, cPtr, uiBytesLeft, 0);
        cPtr += iBytesWritten;
        uiWriteTotal += iBytesWritten;
        uiBytesLeft -= iBytesWritten;
    }

    delete [] cpCommentString;
    return socket;
}

#ifndef __unix__
void cRCF::sendFilename(SOCKET &socket)
#else
void cRCF::sendFilename(int &socket)
#endif
{
    unsigned int uiFilenameLength = m_strFilename.length() + 1; //+1 for '\0'
    unsigned int uiBytesLeft = sizeof(unsigned int);
    int iBytesWritten;
    char* cPtr = (char*)&uiFilenameLength;

    while(uiBytesLeft)
    {
        iBytesWritten = send(socket, cPtr, uiBytesLeft, 0);
        cPtr += iBytesWritten;
        uiBytesLeft -= iBytesWritten;

        if(iBytesWritten == -1)
        {
            cout << "Ard::operator<<(): Error: can't write to socket client has likely closed the connection" << endl;
            return;
        }

    }

    char* cpFilename = new char[uiFilenameLength];
    strncpy(cpFilename, m_strFilename.c_str(), uiFilenameLength);
    cPtr = cpFilename;
    uiBytesLeft = uiFilenameLength;

    while(uiBytesLeft)
    {
        iBytesWritten = send(socket, cPtr, uiBytesLeft, 0);
        cPtr += iBytesWritten;
        uiBytesLeft -= iBytesWritten;

        if(iBytesWritten == -1)
        {
            cout << "Ard::operator<<(): Error: can't write from socket client has likely closed the connection" << endl;
            return;
        }

    }

    delete [] cpFilename;
}

#ifndef __unix__
void cRCF::recvFilename(SOCKET &socket)
#else
void cRCF::recvFilename(int &socket)
#endif
{
    unsigned int uiFilenameLength;
    char* cPtr = (char*)&uiFilenameLength;
    unsigned int uiBytesLeft = sizeof(unsigned int);
    int iBytesRead;

    while(uiBytesLeft)
    {
        iBytesRead = recv(socket, cPtr, uiBytesLeft, MSG_WAITALL);
        cPtr += iBytesRead;
        uiBytesLeft -= iBytesRead;

        if(iBytesRead == -1)
        {
            cout << "Ard::operator<<(): Error: can't read from socket client has likely closed the connection" << endl;
            return;
        }

    }

    char* cpFilename = new char[uiFilenameLength];
    cPtr = cpFilename;
    uiBytesLeft = uiFilenameLength;

    while(uiBytesLeft)
    {
        iBytesRead = recv(socket, cPtr, uiBytesLeft, MSG_WAITALL);
        cPtr += iBytesRead;
        uiBytesLeft -= iBytesRead;

        if(iBytesRead == -1)
        {
            cout << "Ard::operator<<(): Error: can't read from socket client has likely closed the connection" << endl;
            return;
        }

    }
    m_strFilename = string(cpFilename, uiFilenameLength - 1); //-1 to remove null terminating character
    delete [] cpFilename;
}

char* cRCF::serialiseHeader()
{
    //serialise header
    char* cpSerialisedHeader = new char[HEADER_SIZE];
    memcpy(cpSerialisedHeader, &m_cpFileType, 4);
    if(strncmp(m_cpFileType, "rcf\0", 4))
    {
        //file type invalid
        cout << "Rcf::operator>>() Warning received file is not of known RCF type: Got '" << m_cpFileType << "' expected 'rcf'."<< endl;
    }

    memcpy(cpSerialisedHeader + TIME_STAMP, &m_i64TimeStamp_us, sizeof(m_i64TimeStamp_us));
    memcpy(cpSerialisedHeader + FC_HZ, &m_uiFc_Hz, sizeof(m_uiFc_Hz));
    memcpy(cpSerialisedHeader + FS_HZ, &m_uiFs_Hz, sizeof(m_uiFs_Hz));
    memcpy(cpSerialisedHeader + BW_HZ, &m_uiBw_Hz, sizeof(m_uiBw_Hz));
    memcpy(cpSerialisedHeader + N_SAMPLES, &m_u64NSamples, sizeof(m_u64NSamples));
    memcpy(cpSerialisedHeader + COMMENT_OFFSET, &m_u64CommentOffset_B, sizeof(m_u64CommentOffset_B));
    memcpy(cpSerialisedHeader + COMMENT_LENGTH, &m_uiCommentLength, sizeof(m_uiCommentLength));
    memcpy(cpSerialisedHeader + FILE_SIZE, &m_u64FileSize_B, sizeof(m_u64FileSize_B));

    return cpSerialisedHeader; //this needs to be deleted where it is return to
}

void cRCF::deserialiseHeader(char* cpSerialisedHeader)
{
    //deserialise header
    memcpy(&m_cpFileType, cpSerialisedHeader, 4);
    if(strncmp(m_cpFileType, "rcf\0", 4))
    {
        //file type invalid
        cout << "Rcf::operator>>() Warning received file is not of known RCF type: Got '" << m_cpFileType << "' expected 'rcf'."<< endl;
    }

    memcpy(&m_i64TimeStamp_us, cpSerialisedHeader + TIME_STAMP, sizeof(m_i64TimeStamp_us));
    memcpy(&m_uiFc_Hz, cpSerialisedHeader + FC_HZ, sizeof(m_uiFc_Hz));
    memcpy(&m_uiFs_Hz, cpSerialisedHeader + FS_HZ, sizeof(m_uiFs_Hz));
    memcpy(&m_uiBw_Hz, cpSerialisedHeader + BW_HZ, sizeof(m_uiBw_Hz));
    memcpy(&m_u64NSamples, cpSerialisedHeader + N_SAMPLES, sizeof(m_u64NSamples));
    memcpy(&m_u64CommentOffset_B, cpSerialisedHeader + COMMENT_OFFSET, sizeof(m_u64CommentOffset_B));
    memcpy(&m_uiCommentLength, cpSerialisedHeader + COMMENT_LENGTH, sizeof(m_uiCommentLength));
    memcpy(&m_u64FileSize_B, cpSerialisedHeader + FILE_SIZE, sizeof(m_u64FileSize_B));

    //cpSerialisedHeader must be cleaned up by calling code.
}
