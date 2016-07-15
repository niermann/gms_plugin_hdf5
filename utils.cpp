#include "plugin.h"
#include <stdio.h>
#include <stdarg.h>
#include <utf8.h>
#include <cmath>
#include <boost/static_assert.hpp>

using namespace Gatan;

#ifdef ENABLE_DEBUG

void debug(const char* fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    char message[2048];
    int size = _vsnprintf(message, sizeof(message)-1, fmt, args);
    va_end(args);

    if (size < 0)
        message[sizeof(message)-1] = 0;

    char* ptr = message;
    char end;
    do {
        char* next = strchr(ptr, '\n');
        if (!next)
            next = ptr + strlen(ptr);
        end = *next;
        *next = '\0';

        if (next > ptr) {
#if GMS_VERSION_MAJOR >= 2
            DM::Debug("Debug(HDF5_Plugin): ");
            DM::Debug(ptr);
            DM::Debug("\n");
#else
            DM::Result("Debug(HDF5_Plugin): ");
            DM::Result(ptr);
            DM::Result("\n");
#endif
        }

        ptr = next + 1;
    } while (end != 0);
}

#endif // ENABLE_DEBUG

void warning(const char* fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    char message[2048];
    int size = _vsnprintf(message, sizeof(message)-1, fmt, args);
    va_end(args);

    if (size < 0)
        message[sizeof(message)-1] = 0;

    char* ptr = message;
    char end;
    do {
        char* next = strchr(ptr, '\n');
        if (!next)
            next = ptr + strlen(ptr);
        end = *next;
        *next = '\0';

        if (next > ptr) {
#if GMS_VERSION_MAJOR >= 2
            DM::Debug("Warning(HDF5_Plugin): ");
            DM::Debug(ptr);
            DM::Debug("\n");
#else
            DM::Result("Warning(HDF5_Plugin): ");
            DM::Result(ptr);
            DM::Result("\n");
#endif
        }

        ptr = next + 1;
    } while (end != 0);
}

#ifdef ENABLE_DEBUG

static herr_t dumpCallback(unsigned n, const H5E_error2_t *err_desc, void* /*client_data*/)
{
    debug("\t[%d] %s(%d): %s\n", n, err_desc->file_name, err_desc->line, err_desc->desc ? err_desc->desc : "");
    return 0;
}

void dump_HDF_error_stack()
{
    H5Ewalk(H5E_DEFAULT, H5E_WALK_DOWNWARD, dumpCallback, NULL);
    H5Eclear(H5E_DEFAULT);
}

#endif // ENABLE_DEBUG

BOOST_STATIC_ASSERT(sizeof(wchar_t) == 2);       // Else replace utf16 by utf32

DM::String from_UTF8(const std::string &input)
{
    std::wstring output;
    if (!utf8::is_valid(input.begin(), input.end())) {
        std::string replaced;
        utf8::replace_invalid(input.begin(), input.end(), std::back_inserter(replaced), 0xfffd);
        utf8::unchecked::utf8to16(replaced.begin(), replaced.end(), std::back_inserter(output));
    } else
        utf8::unchecked::utf8to16(input.begin(), input.end(), std::back_inserter(output));

    return output;
}

DM::String from_UTF8(const char* input)
{
    if (!input)
         return DM::String();
    const char* end = input + strlen(input);

    std::wstring output;
    if (!utf8::is_valid(input, end)) {
        std::string replaced;
        utf8::replace_invalid(input, end, std::back_inserter(replaced), 0xfffd);
        utf8::unchecked::utf8to16(replaced.begin(), replaced.end(), std::back_inserter(output));
    } else
        utf8::unchecked::utf8to16(input, end, std::back_inserter(output));

    return output;
}

std::string to_UTF8(const DM::String& input)
{
    std::wstring input_wstr;
    input.copy(input_wstr);

    std::string result;
    utf8::utf16to8(input_wstr.begin(), input_wstr.end(), std::back_inserter(result));
    return result;
}

static const char* default_real = "r";
static const char* default_imag = "i";

type_handle_t create_complex_type(int size, const char* realName, const char* imagName) throw()
{
    if (!realName)
        realName = default_real;
    if (!imagName)
        imagName = default_imag;

    if (size != 8 && size != 16) {
        warning("Invalid size in create_complex_type()\n");
        return type_handle_t();
    }

    type_handle_t type(H5Tcreate(H5T_COMPOUND, size));
    if (!type.valid()) {
        warning("H5Tcreate failed\n");
        dump_HDF_error_stack();
        return type_handle_t();
    }

    if (H5Tinsert(type.get(), realName, 0, size == 8 ? H5T_NATIVE_FLOAT : H5T_NATIVE_DOUBLE) < 0
    ||  H5Tinsert(type.get(), imagName, size / 2, size == 8 ? H5T_NATIVE_FLOAT : H5T_NATIVE_DOUBLE) < 0) {
        warning("H5Tinsert failed\n");
        dump_HDF_error_stack();
        return type_handle_t();
    }

    return type;
}

type_handle_t create_compatible_complex_type(hid_t type_id) throw()
{
    if (H5Tget_class(type_id) != H5T_COMPOUND)
        return type_handle_t();
    if (H5Tget_nmembers(type_id) != 2)
        return type_handle_t();
    if (H5Tget_member_class(type_id, 0) != H5T_FLOAT || H5Tget_member_class(type_id, 1) != H5T_FLOAT)
        return type_handle_t();

    char* field0 = H5Tget_member_name(type_id, 0);
    char* field1 = H5Tget_member_name(type_id, 1);
    if ((_stricmp("r", field0) != 0 || _stricmp("i", field1) != 0) 
    &&  (_stricmp("re", field0) != 0 || _stricmp("im", field1) != 0)
    &&  (_stricmp("real", field0) != 0 || _stricmp("imag", field1) != 0)) {
        free(field0);
        free(field1);
        return type_handle_t();
    }

    type_handle_t memtype;
    if (H5Tget_size(type_id) <= 8)
        memtype = create_complex_type(8, field0, field1);
    else
        memtype = create_complex_type(16, field0, field1);

    free(field0);
    free(field1);
    return memtype;
}

bool image_to_HDF(DM::Image image, type_handle_t& type, space_handle_t& space)
{
    type = datatype_to_HDF(image.GetDataType());
    if (!type.valid()) {
        debug("Unsupported image type.");
        return false;
    }

    // Reverse order of dimenesions, HDF uses row-major indices, while DM uses column-major
    int rank = image.GetNumDimensions();
    std::vector<hsize_t> dims(rank);
    for (int i = 0; i < rank; i++) 
        dims[rank - 1 - i] = image.GetDimensionSize(i);

    space.reset(H5Screate_simple(rank, &dims[0], NULL));
    if (!space.valid()) {
        warning("Creation of dataspace failed.");
        dump_HDF_error_stack();
        type.reset();
        return false;
    }

    return true;
}

long datatype_from_HDF(hid_t type_id, type_handle_t& memtype)
{
    if (type_id < 0)
        return -1;

    size_t elemsize = H5Tget_size(type_id);
    
    switch (H5Tget_class(type_id)) {
    case H5T_FLOAT:
        if (elemsize <= 4) {
            memtype.reset(H5Tcopy(H5T_NATIVE_FLOAT));
            return ImageData::REAL4_DATA;
        } else {
            memtype.reset(H5Tcopy(H5T_NATIVE_DOUBLE));
            return ImageData::REAL8_DATA;
        }
        break;

    case H5T_INTEGER:
        if (H5Tget_sign(type_id)) {
            if (elemsize == 1) {
                memtype.reset(H5Tcopy(H5T_NATIVE_INT8));
                return ImageData::SIGNED_INT8_DATA;
            } else if (elemsize == 2) {
                memtype.reset(H5Tcopy(H5T_NATIVE_INT16));
                return ImageData::SIGNED_INT16_DATA;
#if GMS_VERSION_MAJOR >= 2
            } else if (elemsize <= 4) {
                memtype.reset(H5Tcopy(H5T_NATIVE_INT32));
                return ImageData::SIGNED_INT32_DATA;
            } else {
                memtype.reset(H5Tcopy(H5T_NATIVE_INT64));
                return undocumented_SIGNED_INT64_DATA;
#else // GMS_VERSION_MAJOR < 2
            } else {
                memtype.reset(H5Tcopy(H5T_NATIVE_INT32));
                return ImageData::SIGNED_INT32_DATA;
#endif // GMS_VERSION_MAJOR
            }
        } else {
            if (elemsize == 1) {
                memtype.reset(H5Tcopy(H5T_NATIVE_UINT8));
                return ImageData::UNSIGNED_INT8_DATA;
            } else if (elemsize == 2) {
                memtype.reset(H5Tcopy(H5T_NATIVE_UINT16));
                return ImageData::UNSIGNED_INT16_DATA;
#if GMS_VERSION_MAJOR >= 2
            } else if (elemsize <= 4) {
                memtype.reset(H5Tcopy(H5T_NATIVE_UINT32));
                return ImageData::UNSIGNED_INT32_DATA;
            } else {
                memtype.reset(H5Tcopy(H5T_NATIVE_UINT64));
                return undocumented_UNSIGNED_INT64_DATA;
#else // GMS_VERSION_MAJOR < 2
            } else {
                memtype.reset(H5Tcopy(H5T_NATIVE_UINT32));
                return ImageData::UNSIGNED_INT32_DATA;
#endif // GMS_VERSION_MAJOR
            }
        }
        break;

    case H5T_COMPOUND:
        memtype = create_compatible_complex_type(type_id);
        if (!memtype.valid())
            return -1;

        switch (H5Tget_size(memtype.get())) {
        case 8:  
            return ImageData::COMPLEX8_DATA;
        case 16: 
            return ImageData::COMPLEX16_DATA;
        default:
            warning("datatype_from_HDF: You should never get here.");
            memtype.reset();
            return -1;
        }

    default:
        break;
    }

    return -1;
}

type_handle_t datatype_to_HDF(long datatype)
{
    switch (datatype) {
    case ImageData::SIGNED_INT8_DATA:       return type_handle_t(H5Tcopy(H5T_NATIVE_INT8));
    case ImageData::SIGNED_INT16_DATA:      return type_handle_t(H5Tcopy(H5T_NATIVE_INT16));
    case ImageData::SIGNED_INT32_DATA:      return type_handle_t(H5Tcopy(H5T_NATIVE_INT32));
    case undocumented_SIGNED_INT64_DATA:    return type_handle_t(H5Tcopy(H5T_NATIVE_INT64));
    case ImageData::UNSIGNED_INT8_DATA:     return type_handle_t(H5Tcopy(H5T_NATIVE_UINT8));
    case ImageData::UNSIGNED_INT16_DATA:    return type_handle_t(H5Tcopy(H5T_NATIVE_UINT16));
    case ImageData::UNSIGNED_INT32_DATA:    return type_handle_t(H5Tcopy(H5T_NATIVE_UINT32));
    case undocumented_UNSIGNED_INT64_DATA:  return type_handle_t(H5Tcopy(H5T_NATIVE_UINT64));
    case ImageData::REAL4_DATA:             return type_handle_t(H5Tcopy(H5T_NATIVE_FLOAT));
    case ImageData::REAL8_DATA:             return type_handle_t(H5Tcopy(H5T_NATIVE_DOUBLE));
    case ImageData::COMPLEX8_DATA:          return create_complex_type(8);
    case ImageData::COMPLEX16_DATA:         return create_complex_type(16);
    default:                                return type_handle_t();
    }
}

DM::Image image_from_HDF(hid_t type_id, hid_t space_id, type_handle_t& memtype)
{
    if (type_id < 0 || space_id < 0)
        return DM::Image();
    if (H5Sis_simple(space_id) <= 0)
        return DM::Image();

    long dm_type = datatype_from_HDF(type_id, memtype);
    if (dm_type < 0)
        return DM::Image();

    int rank = H5Sget_simple_extent_ndims(space_id);
    if (rank == 0) {
        // Scalar: read as one element image.
        return DM::NewImage("", dm_type, (uint32)1);
    } else if (rank < 0 || rank > 4)
        return DM::Image();

    hsize_t dims[4];
    if (H5Sget_simple_extent_dims(space_id, dims, NULL) < 0)
        return DM::Image();

    switch (rank) {
        case 1: return DM::NewImage("", dm_type, (uint32)dims[0]);
        case 2: return DM::NewImage("", dm_type, (uint32)dims[1], (uint32)dims[0]);
        case 3: return DM::NewImage("", dm_type, (uint32)dims[2], (uint32)dims[1], (uint32)dims[0]);
        case 4: return DM::NewImage("", dm_type, (uint32)dims[3], (uint32)dims[2], (uint32)dims[1], (uint32)dims[0]);
        default:
            warning("image_from_HDF: You should never get here.");
            memtype.reset();
            return DM::Image();
    }
}

Gatan::DM::TagGroup taglist_from_hsize_array(const hsize_t* ptr, int size)
{
    Gatan::DM::TagGroup list = DM::NewTagList();

    for (int i = size - 1; i >= 0; --i)
        list.InsertTagAsLong(-1, long(ptr[i]));

    return list;
}

std::vector<hsize_t> hsize_array_from_taglist(const Gatan::DM::TagGroup &list)
{
    if (!list.IsValid() || !list.IsList())
        return std::vector<hsize_t>();

    long size = list.CountTags();
    std::vector<hsize_t> result(size);

    for (long i = 0; i < size; ++i) {
        long dim;
        if (!list.GetIndexedTagAsLong(i, &dim))
            return std::vector<hsize_t>();
        result[size - 1 - i] = dim;
    }

    return result;
}

file_handle_t open_always(const char* filename)
{
    file_handle_t file(H5Fopen(filename, H5F_ACC_RDWR, H5P_DEFAULT));
    if (!file.valid())
        file.reset(H5Fcreate(filename, H5F_ACC_EXCL, H5P_DEFAULT, H5P_DEFAULT));

    return file;
}
