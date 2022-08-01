# Generates a macro to auto-configure everything
@PACKAGE_INIT@

# Setting these here so they're accessible after install.
# Might be useful for some users to check which settings were used.
set(HTTPLIB_IS_USING_OPENSSL @HTTPLIB_IS_USING_OPENSSL@)
set(HTTPLIB_IS_USING_ZLIB @HTTPLIB_IS_USING_ZLIB@)
set(HTTPLIB_IS_COMPILED @HTTPLIB_COMPILE@)
set(HTTPLIB_IS_USING_BROTLI @HTTPLIB_IS_USING_BROTLI@)
set(HTTPLIB_VERSION @PROJECT_VERSION@)

include(CMakeFindDependencyMacro)

# We add find_dependency calls here to not make the end-user have to call them.
find_dependency(Threads REQUIRED)
if(@HTTPLIB_IS_USING_OPENSSL@)
	# OpenSSL COMPONENTS were added in Cmake v3.11
	if(CMAKE_VERSION VERSION_LESS "3.11")
		find_dependency(OpenSSL @_HTTPLIB_OPENSSL_MIN_VER@ REQUIRED)
	else()
		# Once the COMPONENTS were added, they were made optional when not specified.
		# Since we use both, we need to search for both.
		find_dependency(OpenSSL @_HTTPLIB_OPENSSL_MIN_VER@ COMPONENTS Crypto SSL REQUIRED)
	endif()
endif()
if(@HTTPLIB_IS_USING_ZLIB@)
	find_dependency(ZLIB REQUIRED)
endif()

if(@HTTPLIB_IS_USING_BROTLI@)
	# Needed so we can use our own FindBrotli.cmake in this file.
	# Note that the FindBrotli.cmake file is installed in the same dir as this file.
	list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")
	set(BROTLI_USE_STATIC_LIBS @BROTLI_USE_STATIC_LIBS@)
	find_dependency(Brotli COMPONENTS common encoder decoder REQUIRED)
endif()

# Mildly useful for end-users
# Not really recommended to be used though
set_and_check(HTTPLIB_INCLUDE_DIR "@PACKAGE_CMAKE_INSTALL_FULL_INCLUDEDIR@")
# Lets the end-user find the header path with the header appended
# This is helpful if you're using Cmake's pre-compiled header feature
set_and_check(HTTPLIB_HEADER_PATH "@PACKAGE_CMAKE_INSTALL_FULL_INCLUDEDIR@/httplib.h")

# Brings in the target library
include("${CMAKE_CURRENT_LIST_DIR}/httplibTargets.cmake")

# Ouputs a "found httplib /usr/include/httplib.h" message when using find_package(httplib)
include(FindPackageMessage)
if(TARGET httplib::httplib)
	set(HTTPLIB_FOUND TRUE)

	# Since the compiled version has a lib, show that in the message
	if(@HTTPLIB_COMPILE@)
		# The list of configurations is most likely just 1 unless they installed a debug & release
		get_target_property(_httplib_configs httplib::httplib "IMPORTED_CONFIGURATIONS")
		# Need to loop since the "IMPORTED_LOCATION" property isn't want we want.
		# Instead, we need to find the IMPORTED_LOCATION_RELEASE or IMPORTED_LOCATION_DEBUG which has the lib path.
		foreach(_httplib_conf "${_httplib_configs}")
			# Grab the path to the lib and sets it to HTTPLIB_LIBRARY
			get_target_property(HTTPLIB_LIBRARY httplib::httplib "IMPORTED_LOCATION_${_httplib_conf}")
			# Check if we found it
			if(HTTPLIB_LIBRARY)
				break()
			endif()
		endforeach()

		unset(_httplib_configs)
		unset(_httplib_conf)

		find_package_message(httplib "Found httplib: ${HTTPLIB_LIBRARY} (found version \"${HTTPLIB_VERSION}\")" "[${HTTPLIB_LIBRARY}][${HTTPLIB_HEADER_PATH}]")
	else()
		find_package_message(httplib "Found httplib: ${HTTPLIB_HEADER_PATH} (found version \"${HTTPLIB_VERSION}\")" "[${HTTPLIB_HEADER_PATH}]")
	endif()
endif()