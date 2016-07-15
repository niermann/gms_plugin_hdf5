#include "plugin.h"

using namespace Gatan;

bool h5_create_dataset_from_image(const char* filename, DM_StringToken location, DM_ImageToken image_token)
{
    PLUG_IN_ENTRY

        DM::Image image(image_token);

        type_handle_t memtype = datatype_to_HDF(image.GetDataType());
        if (!memtype.valid()) {
            warning("h5_create_dataset: Unsupported image type.");
            return false;
        }

        int rank = DM::ImageGetNumDimensions(image);
        std::vector<hsize_t> dims(rank);
        for (int i = 0; i < rank; i++) 
             dims[rank - 1 - i] = DM::ImageGetDimensionSize(image, i);

        space_handle_t space(H5Screate_simple(rank, &dims[0], NULL));
        if (!space.valid()) {
            warning("h5_create_dataset: Creation of dataspace failed.");
            dump_HDF_error_stack();
            return false;
        }

        file_handle_t file = open_always(filename);
        if (!file.valid()) {
            warning("h5_create_dataset: Can't open file '%s'.", filename);
            return false;
        }

        std::string loc_name = to_UTF8(DM::String(location));
        dataset_handle_t data(H5Dcreate(file.get(), loc_name.c_str(), memtype.get(), space.get(), H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT));
        if (!data.valid()) {
            warning("h5_create_dataset: Creation of dataset '%s' failed.", loc_name.c_str());
            dump_HDF_error_stack();
            return false;
        }

        herr_t err;
        {
            PlugIn::ImageDataLocker imageLock(image, PlugIn::ImageDataLocker::lock_data_WONT_WRITE
                                                   | PlugIn::ImageDataLocker::lock_data_CONTIGUOUS);
            err = H5Dwrite(data.get(), memtype.get(), H5S_ALL, H5S_ALL, H5P_DEFAULT, imageLock.get());
        }
        if (err < 0) {
            warning("h5_create_dataset: Writing of dataset failed.");
            dump_HDF_error_stack();
            return false;
        }

    PLUG_IN_EXIT

    return true;
}

bool h5_create_dataset_simple(const char* filename, DM_StringToken location, long dtype, DM_TagGroupToken size_token)
{
    PLUG_IN_ENTRY

        DM::TagGroup size_tags(size_token);
        if (!size_tags.IsValid() || !size_tags.IsList()) {
                warning("h5_create_dataset: size must be tag list.");
                return false;
        }

        std::vector<hsize_t> dims = hsize_array_from_taglist(size_tags);
        if (dims.empty()) {
            warning("h5_create_dataset: invalid size.");
            return false;
        }
        for (std::vector<hsize_t>::const_iterator it = dims.begin(); it != dims.end(); ++it)
            if (*it <= 0) {
                warning("h5_create_dataset: invalid size.");
                return false;
            }
        int rank = int(dims.size());

        type_handle_t memtype = datatype_to_HDF(dtype);
        if (!memtype.valid()) {
            warning("h5_create_dataset: Unsupported image type.");
            return false;
        }

        space_handle_t space(H5Screate_simple(rank, &dims[0], NULL));
        if (!space.valid()) {
            warning("h5_create_dataset: Creation of dataspace failed.");
            dump_HDF_error_stack();
            return false;
        }

        file_handle_t file = open_always(filename);
        if (!file.valid()) {
            warning("h5_create_dataset: Can't open file '%s'.", filename);
            return false;
        }

        std::string loc_name = to_UTF8(DM::String(location));
        dataset_handle_t data(H5Dcreate(file.get(), loc_name.c_str(), memtype.get(), space.get(), H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT));
        if (!data.valid()) {
            warning("h5_create_dataset: Creation of dataset '%s' failed.", loc_name.c_str());
            dump_HDF_error_stack();
            return false;
        }

    PLUG_IN_EXIT

    return true;
}

DM_ImageToken_1Ref h5_read_dataset_all(const char* filename, DM_StringToken location)
{
    DM::Image image;

    PLUG_IN_ENTRY

        file_handle_t file(H5Fopen(filename, H5F_ACC_RDONLY, H5P_DEFAULT));
        if (!file.valid()) {
            warning("h5_read_dataset: Can't open file '%s'.", filename);
            return NULL;
        }

        std::string loc_name = to_UTF8(DM::String(location));
        dataset_handle_t data(H5Oopen(file.get(), loc_name.c_str(), H5P_DEFAULT));
        if (!data.valid()) {
            warning("h5_read_dataset: Invalid location '%s'.", loc_name.c_str());
            return NULL;
        }

        space_handle_t space(H5Dget_space(data.get()));
        if (!space.valid()) {
            warning("h5_read_dataset: Reading data space failed.");
            dump_HDF_error_stack();
            return NULL;
        }

        type_handle_t type(H5Dget_type(data.get()));
        if (!type.valid()) {
            warning("h5_read_dataset: Reading data type failed.");
            dump_HDF_error_stack();
            return NULL;
        }

        type_handle_t memtype;
        image = image_from_HDF(type.get(), space.get(), memtype);
        if (!image.IsValid()) {
            warning("h5_read_dataset: Unsupported array type or data space.");
            return NULL;
        }

        herr_t err;
        {
            PlugIn::ImageDataLocker imageLock(image, PlugIn::ImageDataLocker::lock_data_WONT_READ
                                                   | PlugIn::ImageDataLocker::lock_data_CONTIGUOUS);
            err = H5Dread(data.get(), memtype.get(), H5S_ALL, H5S_ALL, H5P_DEFAULT, imageLock.get());
            image.DataChanged();
        }
        if (err < 0) {
            debug("h5_read_dataset: Reading of dataset failed.");
            dump_HDF_error_stack();
            return NULL;
        }

    PLUG_IN_EXIT

    return image.release();
}
