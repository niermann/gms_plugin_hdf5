#ifndef HDF5_PLUGIN_INC
#define HDF5_PLUGIN_INC

#define _GATANPLUGIN_USES_LIBRARY_VERSION 2
#define _GATAN_USE_STL_STRING
#include "DMPlugInBasic.h"

#include <string.h>
#include <hdf5.h>
#include <boost/cstdint.hpp>
#include "autohandle.h"
#include <vector>

// GMS version defined?
#ifndef GMS_VERSION_MAJOR
#   error "GMS_VERSION_MAJOR not defined."
#endif

// Plugin version string
#define HDF5_PLUGIN_VERSION     "1.2.0"

// Uncomment for debug output
//#define ENABLE_DEBUG

// Undocumented data types
enum {
    undocumented_SIGNED_INT64_DATA   = 39,
    undocumented_UNSIGNED_INT64_DATA = 40
};

//----------------------------------------------------------------------------------------
// Plugin (plugin.cpp)

class HDF5Plugin : public GatanPlugIn::PlugInMain
{
private:
    virtual void Start();
    virtual void Run();
    virtual void Cleanup();
    virtual void End();
};

//----------------------------------------------------------------------------------------
// Exported functions

DM_TagGroupToken_1Ref h5_info_root(const char* filename);
DM_TagGroupToken_1Ref h5_info_location(const char* filename, DM_StringToken location);
bool                  h5_delete(const char* filename, DM_StringToken location);
bool                  h5_exists(const char* filename, DM_StringToken location);

DM_TagGroupToken_1Ref h5_read_attr(const char* filename, DM_StringToken location);
bool                  h5_delete_attr(const char* filename, DM_StringToken location, DM_StringToken name);
bool                  h5_exists_attr(const char* filename, DM_StringToken location, DM_StringToken name);

bool                  h5_create_dataset_from_image(const char* filename, DM_StringToken location, DM_ImageToken image_token);
bool                  h5_create_dataset_simple(const char* filename, DM_StringToken location, long datatype, DM_TagGroupToken size_token);
DM_ImageToken_1Ref    h5_read_dataset_all(const char* filename, DM_StringToken location);
DM_ImageToken_1Ref    h5_read_dataset_slice1(const char* filename, DM_StringToken location, DM_TagGroupToken offset_token, long dim0, long count0, long stride0);
DM_ImageToken_1Ref    h5_read_dataset_slice2(const char* filename, DM_StringToken location, DM_TagGroupToken offset_token, long dim0, long count0, long stride0, long dim1, long count1, long stride1);
DM_ImageToken_1Ref    h5_read_dataset_slice3(const char* filename, DM_StringToken location, DM_TagGroupToken offset_token, long dim0, long count0, long stride0, long dim1, long count1, long stride1, long dim2, long count2, long stride2);
DM_StringToken_1Ref   h5_read_string_dataset(const char* filename, DM_StringToken location);

//----------------------------------------------------------------------------------------
// Utility functions (utils.cpp)

/** Dump debug output.  */
void debug(const char* fmt, ...);

/** Write warning to Results. */
void warning(const char* fmt, ...);

/** Debug dump HDF error stack. */
void dump_HDF_error_stack();

/** Convert UTF8 string to DM string. */
Gatan::DM::String from_UTF8(const std::string &input);

/** Convert UTF8 string to DM string. */
Gatan::DM::String from_UTF8(const char* input);

/** Convert DM string to UTF8. */
std::string to_UTF8(const Gatan::DM::String& input);

/** 
 * Returns HDF compound type for complex type. 
 * Caller is responsible for releasing the type.
 * @param size Size of complex type in bytes (8 or 16) 
 * @param realName Name of real field (If NULL the default name is used).
 * @param imagName Name of imag field (If NULL the default name is used).
 * @returns <0 on error.
 * Never throws.
 */
type_handle_t create_complex_type(int size, const char* realName = 0, const char* imagName = 0) throw();

/** 
 * Returns compatible HDF compound type for complex type. 
 * Caller is responsible for releasing the type.
 * @param type_id Type to create compatible type for 
 * @param realName Name of real field.
 * @param imagName Name of imag field.
 * @returns <0 on error (i.e. type_id does not like a complex type).
 * Never throws.
 */
type_handle_t create_compatible_complex_type(hid_t type_id) throw();

/**
 * Creates DataSpace and Type for DM image. @p type_id and @p space_id are only
 * valid, if @c true is returned. The caller is responsible for releasing them in that case.
 * @param image Image to convert.
 * @param type OUT: HDF Type. Caller is responsible for closing it.
 * @param space OUT: HDF DataSpace. Caller is responsible for closing it.
 * @returns Whether succeeded.
 */
bool image_to_HDF(Gatan::DM::Image image, type_handle_t& type, space_handle_t& space);

/**
 * Converts HDF data type to DM data type.
 * @param type_id HDF Type. 
 * @returns Data type on success, <0 on failure.
 */
long datatype_from_HDF(hid_t type_id);

/**
 * Converts DM data typ to HDF data type.
 * @param datatype DM Data Type 
 * @returns Data type on success, invalid type on failure.
 */
type_handle_t datatype_to_HDF(long datatype);

/**
 * Creates DM image from dimension list and data type.
 * @param datatype DM Datatype. 
 * @param rank Number of dimensions
 * @param dims Extents of the individual dimensions (HDF5 order)
 * @returns Image on success.
 */
Gatan::DM::Image create_image(long datatype, int rank, const hsize_t* dims);

/**
 * Reads space descriptor into hsize array.
 * @param space_id HDF Dataspace. 
 * @param dims OUT: Extents of the individual dimensions
 * @return Number of dimensions (rank), <0 on failure
 */
int hsize_array_from_HDF5(int space_id, std::vector<hsize_t>& dims);

/** 
 * Convert hsize_t[] array to DM tag list. Reverses order of entries, since
 * DM is column-major and HDF is row-major.
 * @returns TagGroup which stores the taglist
 * @param ptr Pointer to first item of array
 * @param size Number of items
 */
Gatan::DM::TagGroup taglist_from_hsize_array(const hsize_t* ptr, int size);

/**
 * Create hsize_t vector from DM tag list. Reverses order of entries, since
 * DM is column-major and HDF is row-major.
 * @param list TagList to create vector from
 * @returns Vector with contents of array, empty on error.
 */
std::vector<hsize_t> hsize_array_from_taglist(const Gatan::DM::TagGroup& list);

/** 
 * Open file for writing, if fails, create it.
 */
file_handle_t open_always(const char* filename);

#ifndef ENABLE_DEBUG

inline void debug(const char* fmt, ...)
{
    // NOP
}

inline void dump_HDF_error_stack()
{
    // NOP
}

#endif // ENABLE_DEBUG

#endif // HDF5_PLUGIN_INC
