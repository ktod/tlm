#
# This is the toplevel CMakeLists.txt that is used to build Couchbase
#
CMAKE_MINIMUM_REQUIRED(VERSION 2.8.10)
PROJECT("Couchbase")

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/tlm/cmake/Modules/")
SET(COUCHBASE_SERVER_BUILD True CACHE BOOL "Indicating this is a server build")

# Try to download the prebuilt 3rd-party dependencies by default
IF (NOT DEFINED CB_DOWNLOAD_DEPS)
   SET(CB_DOWNLOAD_DEPS True
       CACHE BOOL "Download prebuilt dependencies by default")
ENDIF (NOT DEFINED CB_DOWNLOAD_DEPS)

# Have to add deps first, before any other part of the build tries to
# FIND anything
ADD_SUBDIRECTORY(tlm/deps)

INCLUDE(CouchbaseDefaultValues)

MESSAGE(STATUS "Using cmake version: ${CMAKE_VERSION}")
MESSAGE(STATUS "Installing to ${CMAKE_INSTALL_PREFIX}")
MESSAGE(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

INCLUDE(CouchbaseMemoryAllocator)

INCLUDE(FindCouchbaseOpenSSL)
INCLUDE(FindCouchbaseLibevent)
INCLUDE(FindCouchbaseCurl)
INCLUDE(FindCouchbaseIcu)
INCLUDE(FindCouchbaseSnappy)
INCLUDE(FindCouchbaseV8)
INCLUDE(FindCouchbaseLua)
INCLUDE(FindCouchbasePythonInterp)
INCLUDE(FindCouchbaseErlang)
INCLUDE(FindCouchbaseDtrace)
INCLUDE(FindCouchbaseGo)
INCLUDE(FindCouchbaseBreakpad)

IF (WIN32)
   SET(COUCHBASE_NETWORK_LIBS "Ws2_32")
ELSEIF ("${CMAKE_SYSTEM_NAME}" STREQUAL "SunOS")
   SET(COUCHBASE_NETWORK_LIBS socket nsl)
ENDIF (WIN32)
MESSAGE(STATUS "Linking with network libraries: ${COUCHBASE_NETWORK_LIBS}")

IF (NOT WIN32)
   SET(COUCHBASE_MATH_LIBS m)
ENDIF(NOT WIN32)

INCLUDE(CouchbaseCompilerOptions)
INCLUDE(CouchbaseCodeCoverage)

ENABLE_TESTING()
# When performing memory checking with ctest we need to include the CTest
# module to ensure CMake variables to define the memory checker
# (e.g. MEMORYCHECK_COMMAND) are propogated to CTest.
INCLUDE(CTest)


INCLUDE_DIRECTORIES(BEFORE ${CMAKE_BINARY_DIR}/platform/include)

# Add a quick (and safe) way to nuke everything
ADD_CUSTOM_TARGET(reset
                  COMMAND repo forall -c "git clean -dfx"
                  VERBATIM)

IF (IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/flatbuffers")
    SET(FLATBUFFERS_INSTALL OFF CACHE BOOL "Don't install flatbuffers")
    ADD_SUBDIRECTORY(flatbuffers)
ENDIF (IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/flatbuffers")

ADD_SUBDIRECTORY(platform)
ADD_SUBDIRECTORY(memcached)
ADD_SUBDIRECTORY(couchstore)
ADD_SUBDIRECTORY(ep-engine)
ADD_SUBDIRECTORY(couchbase-cli)
ADD_SUBDIRECTORY(couchbase-examples)
ADD_SUBDIRECTORY(healthchecker)
ADD_SUBDIRECTORY(couchbase-python-client)
ADD_SUBDIRECTORY(sigar)
ADD_SUBDIRECTORY(moxi)
ADD_SUBDIRECTORY(couchdb)
ADD_SUBDIRECTORY(geocouch)
ADD_SUBDIRECTORY(ns_server ${CMAKE_CURRENT_SOURCE_DIR}/ns_server/build)


# There is currently a build break for Windows, but we'd still like to build
# with the sherlock manfest.

IF (NOT (WIN32 OR "${CMAKE_SYSTEM_NAME}" STREQUAL "SunOS"))
   # Preparing for Sherlock!
   IF (IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/forestdb")
      ADD_SUBDIRECTORY (forestdb)
   ENDIF (IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/forestdb")

   IF (IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/goproj")
      SET (GODEPSDIR "${CMAKE_CURRENT_SOURCE_DIR}/godeps")

      ADD_SUBDIRECTORY (goproj/src/github.com/couchbaselabs/query)

      SET (FORESTDB_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/forestdb/include")
      GET_PROPERTY (_dir TARGET forestdb PROPERTY LOCATION)
      GET_FILENAME_COMPONENT (FORESTDB_LIBRARY_DIR "${_dir}" PATH)
      SET (FORESTDB_TARGET forestdb)
      ADD_SUBDIRECTORY (goproj/src/github.com/couchbase/indexing)
      ADD_SUBDIRECTORY (goproj/src/github.com/couchbase/goxdcr)
      ADD_SUBDIRECTORY (goproj/src/github.com/couchbase/gometa)

      GoInstall(TARGET saslauthd-port PACKAGE github.com/couchbase/cbauth/cmd/saslauthd-port
          GOPATH "${CMAKE_CURRENT_SOURCE_DIR}/goproj" "${GODEPSDIR}"
          INSTALL_PATH bin OUTPUT saslauthd-port)
   ENDIF (IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/goproj")
ENDIF (NOT (WIN32 OR "${CMAKE_SYSTEM_NAME}" STREQUAL "SunOS"))
