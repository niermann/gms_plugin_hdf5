#include "plugin.h"
#include "scopedptr.h"
#include <vector>

using namespace Gatan;

static void read_scalar_attr(const char* attr_name, hid_t attr_id, hid_t type_id, DM::TagGroup& tags)
{
    switch (H5Tget_class(type_id)) {
    case H5T_FLOAT:
        if (H5Tget_size(type_id) <= 4) {
            float value;
            if (H5Aread(attr_id, H5T_NATIVE_FLOAT, &value) >= 0)
                tags.SetTagAsFloat(attr_name, value);
        } else {
            double value;
            if (H5Aread(attr_id, H5T_NATIVE_DOUBLE, &value) >= 0)
                tags.SetTagAsDouble(attr_name, value);
        }
        break;

    case H5T_INTEGER:
        if (H5Tget_sign(type_id)) {
            long value;
            if (H5Aread(attr_id, H5T_NATIVE_LONG, &value) >= 0)
                tags.SetTagAsLong(attr_name, value);
        } else {
            uint32_t value;
            if (H5Aread(attr_id, H5T_NATIVE_UINT32, &value) >= 0)
                tags.SetTagAsUInt32(attr_name, value);
        }
        break;

    case H5T_STRING:
        if (H5Tis_variable_str(type_id)) {
            // variable length string
            scoped_ptr<char, free> data;

            type_handle_t strtype(H5Tcopy(H5T_C_S1));
            H5Tset_size(strtype.get(), H5T_VARIABLE);
            H5Tset_cset(strtype.get(), H5T_CSET_UTF8);

            // Hack: scoped_ptr has same memory layout as pointer.
            if (H5Aread(attr_id, strtype.get(), &data) < 0)
                return;

            tags.SetTagAsString(attr_name, from_UTF8(data.get()));
        } else {
            // Fixed size string
            size_t size = H5Tget_size(type_id);
            type_handle_t strtype(H5Tcopy(H5T_C_S1));
            H5Tset_strpad(strtype.get(), H5T_STR_NULLTERM);
            H5Tset_size(strtype.get(), size + 1);
            H5Tset_cset(strtype.get(), H5T_CSET_UTF8);
            std::vector<char> data(size+1);
            if (H5Aread(attr_id, strtype.get(), &data[0]) < 0)
                return;

            tags.SetTagAsString(attr_name, from_UTF8(&data[0]));
        }
        break;

    case H5T_COMPOUND:
        {
            type_handle_t memtype = create_compatible_complex_type(type_id);
            if (!memtype.valid())
                 return;

            if (H5Tget_size(memtype.get()) <= 8) {
                complex64 value;
                if (H5Aread(attr_id, memtype.get(), &value) >= 0)
                    tags.SetTagAsFloatComplex(attr_name, complex128(value));
            } else {
                complex128 value;
                if (H5Aread(attr_id, memtype.get(), &value) >= 0)
                    tags.SetTagAsDoubleComplex(attr_name, value);
            }
        }
        break;

    default:
        break;
    }
}

static void read_string_array_attr(const char* attr_name, hid_t attr_id, hid_t type_id, hid_t space_id, DM::TagGroup& tags)
{
    if (H5Tget_class(type_id) != H5T_STRING)
        return;
    hssize_t count = H5Sget_simple_extent_npoints(space_id);
    if (count < 0)
        return;
    size_t elemsize = H5Tget_size(type_id);
    if (elemsize < 0)
        return;

    type_handle_t strtype(H5Tcopy(H5T_C_S1));
    H5Tset_strpad(strtype.get(), H5T_STR_NULLTERM);
    H5Tset_size(strtype.get(), elemsize + 1);
    H5Tset_cset(strtype.get(), H5T_CSET_UTF8);

    std::vector<char> data((elemsize + 1) * (size_t)count);
    if (H5Aread(attr_id, strtype.get(), &data[0]) < 0)
        return;

    // Create tag list
    DM::TagGroup list = tags.CreateNewLabeledList(attr_name);
    for (hssize_t i = 0; i < count; i++)
        list.InsertTagAsString((long)i, from_UTF8(&data[(elemsize + 1) * (unsigned)i]));
}

static void read_array_attr(const char* attr_name, hid_t attr_id, hid_t type_id, hid_t space_id, DM::TagGroup& tags)
{
    hssize_t size = H5Sget_simple_extent_npoints(space_id);
    if (size <= 0)
        return;

    int rank = H5Sget_simple_extent_ndims(space_id);
    if (rank <= 0 || rank > 4)
        return;

    hsize_t dims[4], ct[4];
    if (H5Sget_simple_extent_dims(space_id, dims, NULL) < 0)
        return;

    DM::TagGroup list[4];
#define ITERATE_ARRAY(_insert_method, _defer_iter, _advance_iter) do {\
        list[0] = DM::NewTagList(); \
        ct[0] = 0; \
        int n = 0; \
        while (n >= 0) { \
            if (n < (rank - 1)) { \
                list[n + 1] = list[n].CreateListTagAtEnd();  \
                ct[n + 1] = 0; \
                ++n; \
            } else { \
                for (int m = 0; m < dims[n]; ++m, _advance_iter) \
                    list[n]._insert_method(m, _defer_iter); \
                --n; \
                while (n >= 0) { \
                    if (++ct[n] < dims[n]) \
                        break; \
                    --n; \
                } \
            } \
        } \
    } while(0)

    switch (H5Tget_class(type_id)) {
    case H5T_FLOAT:
        if (H5Tget_size(type_id) <= 4) {
            std::vector<float> data(std::size_t(size), 0.0);
            if (H5Aread(attr_id, H5T_NATIVE_FLOAT, &data[0]) < 0)
                return;

            std::vector<float>::const_iterator iter = data.begin();
            ITERATE_ARRAY(InsertTagAsFloat, *iter, ++iter);
        } else {
            std::vector<double> data(std::size_t(size), 0.0);
            if (H5Aread(attr_id, H5T_NATIVE_DOUBLE, &data[0]) < 0)
                return;

            std::vector<double>::const_iterator iter = data.begin();
            ITERATE_ARRAY(InsertTagAsDouble, *iter, ++iter);
        }
        break;

    case H5T_INTEGER:
        if (H5Tget_sign(type_id)) {
            std::vector<long> data(std::size_t(size), 0);
            if (H5Aread(attr_id, H5T_NATIVE_LONG, &data[0]) < 0)
                return;

            std::vector<long>::const_iterator iter = data.begin();
            ITERATE_ARRAY(InsertTagAsLong, *iter, ++iter);
        } else {
            std::vector<uint32_t> data(std::size_t(size), 0);
            if (H5Aread(attr_id, H5T_NATIVE_UINT32, &data[0]) < 0)
                return;

            std::vector<uint32_t>::const_iterator iter = data.begin();
            ITERATE_ARRAY(InsertTagAsUInt32, *iter, ++iter);
        }
        break;

    case H5T_STRING:
        if (H5Tis_variable_str(type_id)) {
            // Read variable length array (untested)
            type_handle_t strtype(H5Tcopy(H5T_C_S1));
            H5Tset_size(strtype.get(), H5T_VARIABLE);
            H5Tset_cset(strtype.get(), H5T_CSET_UTF8);

            scoped_ptr_array<char, free> data(static_cast<std::size_t>(size));
            if (H5Aread(attr_id, strtype.get(), data.unsafe_data()) < 0)
                return;

            std::size_t iter = 0;
            ITERATE_ARRAY(InsertTagAsString, from_UTF8(data.get(iter)), ++iter);
        } else {
            // Read fixed size array
            size_t elemsize = H5Tget_size(type_id);
            if (elemsize < 0)
                return;
            elemsize += 1;  // For NUL character

            type_handle_t strtype(H5Tcopy(H5T_C_S1));
            H5Tset_strpad(strtype.get(), H5T_STR_NULLTERM);
            H5Tset_size(strtype.get(), elemsize);
            H5Tset_cset(strtype.get(), H5T_CSET_UTF8);

            std::vector<char> data(elemsize * (size_t)size);
            if (H5Aread(attr_id, strtype.get(), &data[0]) < 0)
                return;

            const char* iter = &data[0];
            ITERATE_ARRAY(InsertTagAsString, from_UTF8(iter), iter += elemsize);
        }
        break;

    case H5T_COMPOUND:
        {
            type_handle_t memtype = create_compatible_complex_type(type_id);
            if (!memtype.valid())
                 return;

            if (H5Tget_size(memtype.get()) <= 8) {
                std::vector<complex64> data(std::size_t(size), 0);
                if (H5Aread(attr_id, memtype.get(), &data[0]) < 0)
                    return;

                std::vector<complex64>::const_iterator iter = data.begin();
                ITERATE_ARRAY(InsertTagAsFloatComplex, complex128(*iter), ++iter);
            } else {
                std::vector<complex128> data(std::size_t(size), 0);
                if (H5Aread(attr_id, memtype.get(), &data[0]) < 0)
                    return;

                std::vector<complex128>::const_iterator iter = data.begin();
                ITERATE_ARRAY(InsertTagAsDoubleComplex, *iter, ++iter);
            }
        }
        break;

    default:
        break;
    }

    // If we made it here, list[0] is the array we want to insert
    tags.SetTagAsTagGroup(attr_name, list[0]);
}

static void read_array_attr_old(const char* attr_name, hid_t attr_id, hid_t type_id, hid_t space_id, DM::TagGroup& tags)
{
    type_handle_t memtype;
    DM::Image image = image_from_HDF(type_id, space_id, memtype);
    if (!image.IsValid())
        return;

    herr_t err;
    {
        PlugIn::ImageDataLocker imageLock(image, PlugIn::ImageDataLocker::lock_data_WONT_READ
                                               | PlugIn::ImageDataLocker::lock_data_CONTIGUOUS);
        err = H5Aread(attr_id, memtype.get(), imageLock.get());
        image.DataChanged();
    }

    if (err >= 0) {
        DM::TagGroup dataTags = tags.CreateNewLabeledGroup(attr_name);
        dataTags.SetTagAsLong("DataType", image.GetDataType());

        DM::TagGroup dimTags = dataTags.CreateNewLabeledList("Dimensions");
        for (unsigned i = 0; i < image.GetNumDimensions(); ++i)
            dimTags.InsertTagAsLong(0x7ffffffful, image.GetDimensionSize(i));

        dataTags.SetTagAsArray("Data", image);
    }
}

static herr_t attr_iterator(hid_t loc_id, const char *attr_name, const H5A_info_t *ainfo, DM::TagGroup *tags)
{
    // Open attribute
    attr_handle_t attr(H5Aopen(loc_id, attr_name, H5P_DEFAULT));
    if (!attr.valid()) {
        debug("get_attr_operator: Error opening attribute \"%s\".\n", attr_name);
        return 0;
    }

    space_handle_t space(H5Aget_space(attr.get()));
    if (!space.valid())
        return 0;

    int rank = H5Sget_simple_extent_ndims(space.get());
    if (rank < 0)
        return 0;

    // Dump type info
    type_handle_t type(H5Aget_type(attr.get()));
    if (!type.valid())
        return 0;

    try {
        if (rank == 0)
            read_scalar_attr(attr_name, attr.get(), type.get(), *tags);
        else
            read_array_attr(attr_name, attr.get(), type.get(), space.get(), *tags);
    } catch (...) {
        // pass
    }

    return 0;
}

DM_TagGroupToken_1Ref h5_read_attr(const char* filename, DM_StringToken location)
{
    DM::TagGroup tags;

    PLUG_IN_ENTRY

        file_handle_t file(H5Fopen(filename, H5F_ACC_RDONLY, H5P_DEFAULT));
        if (!file.valid()) {
            warning("h5_read_attr: Can't open file '%s'.", filename);
            return NULL;
        }

        std::string loc_name = to_UTF8(DM::String(location));
        object_handle_t loc(H5Oopen(file.get(), loc_name.c_str(), H5P_DEFAULT));
        if (!loc.valid()) {
            warning("h5_read_attr: Invalid location '%s'.", loc_name.c_str());
            return NULL;
        }
        
        tags = DM::NewTagGroup();
        hsize_t index = 0;
        H5Aiterate(loc.get(), H5_INDEX_NAME, H5_ITER_NATIVE, &index, (H5A_operator2_t)attr_iterator, &tags);

    PLUG_IN_EXIT

    return tags.release();
}

bool h5_exists_attr(const char* filename, DM_StringToken location, DM_StringToken attr)
{
    htri_t result;

    PLUG_IN_ENTRY

        file_handle_t file(H5Fopen(filename, H5F_ACC_RDONLY, H5P_DEFAULT));
        if (!file.valid()) {
            warning("h5_attr_exists: Can't open file '%s'.", filename);
            return NULL;
        }

        std::string loc_name = to_UTF8(DM::String(location));
        object_handle_t loc(H5Oopen(file.get(), loc_name.c_str(), H5P_DEFAULT));
        if (!loc.valid()) {
            warning("h5_attr_exists: Invalid location '%s'.", loc_name.c_str());
            return NULL;
        }

        std::string attr_name = to_UTF8(DM::String(attr));
        result = H5Aexists_by_name(loc.get(), ".", attr_name.c_str(), H5P_DEFAULT);
        if (result < 0) {
            warning("h5_attr_exists: Error checking existance of attribute '%s'.", attr_name.c_str());
            return false;
        }

    PLUG_IN_EXIT

    return result;
}

bool h5_delete_attr(const char* filename, DM_StringToken location, DM_StringToken attr)
{
    PLUG_IN_ENTRY

        file_handle_t file(H5Fopen(filename, H5F_ACC_RDWR, H5P_DEFAULT));
        if (!file.valid()) {
            warning("h5_delete_attr: Can't open file '%s'.", filename);
            return false;
        }

        std::string loc_name = to_UTF8(DM::String(location));
        object_handle_t loc(H5Oopen(file.get(), loc_name.c_str(), H5P_DEFAULT));
        if (!loc.valid()) {
            warning("h5_delete_attr: Invalid location '%s'.", loc_name.c_str());
            return false;
        }

        std::string attr_name = to_UTF8(DM::String(attr));
        if (H5Adelete_by_name(loc.get(), ".", attr_name.c_str(), H5P_DEFAULT) < 0) {
            warning("h5_delete_attr: Error deleting attribute '%s'.", attr_name.c_str());
            return false;
        }

    PLUG_IN_EXIT

    return true;
}
