#include "plugin.h"

using namespace Gatan;

// Forwards
static DM::TagGroup get_object_info(hid_t loc_id, const std::string& loc_name, const char* name);

static std::string get_fullname(const std::string& loc_name, const char* name)
{
    std::string fullname = loc_name;
    if (fullname.empty() || *fullname.rbegin() != '/')
        fullname.append("/");

    while (*name == '/')
        name++;
    fullname.append(name);

    return fullname;
}

static DM::TagGroup get_softlink_info(hid_t loc_id, const std::string& loc_name, const char* name, size_t val_size)
{
    DM::TagGroup tags = DM::NewTagGroup();
    tags.SetTagAsString("Name", from_UTF8(get_fullname(loc_name, name)));
    tags.SetTagAsString("Type", "SoftLink");

    std::vector<char> value(val_size);
    if (H5Lget_val(loc_id, name, &value[0], val_size, H5P_DEFAULT) < 0)
        return DM::TagGroup();

    tags.SetTagAsString("Path", from_UTF8(&value[0]));

    return tags;
}

static DM::TagGroup get_externallink_info(hid_t loc_id, const std::string& loc_name, const char* name, size_t val_size)
{
    DM::TagGroup tags = DM::NewTagGroup();
    tags.SetTagAsString("Name", from_UTF8(get_fullname(loc_name, name)));
    tags.SetTagAsString("Type", "ExternalLink");
    
    std::vector<char> value(val_size);
    if (H5Lget_val(loc_id, name, &value[0], val_size, H5P_DEFAULT) < 0)
        return DM::TagGroup();

    const char* filename = 0;
    const char* path = 0;
    unsigned flags = 0;
    if (H5Lunpack_elink_val(&value[0], val_size, &flags, &filename, &path) < 0)
        return DM::TagGroup();

    tags.SetTagAsString("Filename", from_UTF8(filename));
    tags.SetTagAsString("Path", from_UTF8(path));
    tags.SetTagAsUInt32("Flags", flags);

    return tags;
}

struct group_iterator_param_t
{
    const std::string& loc_name;
    DM::TagGroup&      parent;

    group_iterator_param_t(const std::string& _loc_name, DM::TagGroup& _parent)
    : loc_name(_loc_name), parent(_parent) 
    {}
};

static herr_t group_iterator(hid_t loc_id, const char *name, const H5L_info_t *info, group_iterator_param_t *param) 
{
    DM::TagGroup tags;
    switch (info->type) {
    case H5L_TYPE_HARD:
        tags = get_object_info(loc_id, param->loc_name, name);
        break;

    case H5L_TYPE_SOFT:
        tags = get_softlink_info(loc_id, param->loc_name, name, info->u.val_size);
        break;

    case H5L_TYPE_EXTERNAL:
        tags = get_externallink_info(loc_id, param->loc_name, name, info->u.val_size);
        break;

    default:
        break;  // Ignore unknown link types
    }

    if (tags.IsValid())
        param->parent.AddTagGroupAtEnd(tags);

    return 0;
}

static bool get_group_info(hid_t loc_id, const std::string& fullname, const char* name, DM::TagGroup& tags)
{
    DM::TagGroup contents = tags.CreateNewLabeledList("Contents");

    group_handle_t group(H5Gopen(loc_id, name, H5P_DEFAULT));
    if (!group.valid())
        return false;

    group_iterator_param_t param(fullname, contents);
    hsize_t idx = 0;
    H5Literate(group.get(), H5_INDEX_NAME, H5_ITER_INC, &idx, (H5L_iterate_t)&group_iterator, &param);

    return true;
}

// Returns rank
static int get_space_info(hid_t space_id, DM::TagGroup& tags)
{
    if (!H5Sis_simple(space_id)) {
        tags.SetTagAsString("DataSpaceClass", "Unknown");
        return -1;
    }

    int rank = H5Sget_simple_extent_ndims(space_id);
    if (rank < 0)
        return -1;

    tags.SetTagAsLong("Rank", rank);
    if (rank > 0) {
        tags.SetTagAsString("DataSpaceClass", "SIMPLE");

        std::vector<hsize_t> dims(rank*2);
        if (H5Sget_simple_extent_dims(space_id, &dims[0], &dims[rank]) < 0)
            return -1;

        tags.SetTagAsTagGroup("Size", taglist_from_hsize_array(&dims[0], rank));
        tags.SetTagAsTagGroup("MaxSize", taglist_from_hsize_array(&dims[rank], rank));
    } else if (rank == 0)
        tags.SetTagAsString("DataSpaceClass", "SCALAR");

    return rank;
}

static void get_type_info(hid_t type_id, DM::TagGroup& tags)
{
    switch (H5Tget_class(type_id)) {
    case H5T_INTEGER:
        tags.SetTagAsString("DataTypeClass", "INTEGER");
        break;

    case H5T_FLOAT:
        tags.SetTagAsString("DataTypeClass", "FLOAT");
           break;

    case H5T_STRING:
        tags.SetTagAsString("DataTypeClass", "STRING");
        break;

    case H5T_BITFIELD:
        tags.SetTagAsString("DataTypeClass", "BITFIELD");
        break;

    case H5T_OPAQUE:
        tags.SetTagAsString("DataTypeClass", "OPAQUE");
        break;

    case H5T_COMPOUND:
        tags.SetTagAsString("DataTypeClass", "COMPOUND");
        break;

    case H5T_REFERENCE:
        tags.SetTagAsString("DataTypeClass", "REFERENCE");
        break;

    case H5T_ENUM:
        tags.SetTagAsString("DataTypeClass", "ENUM");
        break;

    case H5T_VLEN:
        tags.SetTagAsString("DataTypeClass", "VLEN");
        break;

    case H5T_ARRAY:
        tags.SetTagAsString("DataTypeClass", "ARRAY");
        break;

    default:
        tags.SetTagAsString("DataTypeClass", "Unknown");
        break;
    }

    long dtype = datatype_from_HDF(type_id);
    if (dtype >= 0)
        tags.SetTagAsLong("DataType", dtype);
}

static bool get_dataset_info(hid_t loc_id, const char* name, DM::TagGroup& tags)
{
    dataset_handle_t dset(H5Dopen(loc_id, name, H5P_DEFAULT));
    if (!dset.valid())
        return false;

    space_handle_t space(H5Dget_space(dset.get()));
    if (!space.valid())
        return false;
    int rank = get_space_info(space.get(), tags);

    type_handle_t type(H5Dget_type(dset.get()));
    if (!type.valid())
        return false;
    get_type_info(type.get(), tags);

    plist_handle_t plist(H5Dget_create_plist(dset.get()));
    if (plist.valid() && rank > 0) {
        std::vector<hsize_t> chunkSize(rank);
        if (H5Pget_chunk(plist.get(), rank, &chunkSize[0]) >= 0)
            tags.SetTagAsTagGroup("ChunkSize", taglist_from_hsize_array(&chunkSize[0], rank));
    }

    return true;
}

static DM::TagGroup get_object_info(hid_t loc_id, const std::string& loc_name, const char* name)
{
    H5O_info_t info;
    if (H5Oget_info_by_name(loc_id, name, &info, H5P_DEFAULT) < 0)
        return DM::TagGroup();

    DM::TagGroup tags = DM::NewTagGroup();
    std::string fullname = get_fullname(loc_name, name);
    tags.SetTagAsString("Name", from_UTF8(fullname));

    switch (info.type) {
    case H5O_TYPE_GROUP:
        tags.SetTagAsString("Type", "Group");
        if (!get_group_info(loc_id, fullname, name, tags))
           return DM::TagGroup();
        break;

    case H5O_TYPE_DATASET:
        tags.SetTagAsString("Type", "DataSet");
        if (!get_dataset_info(loc_id, name, tags))
            return DM::TagGroup();
        break;

    case H5O_TYPE_NAMED_DATATYPE:
        tags.SetTagAsString("Type", "NamedDataType");
        break;

    default:
        tags.SetTagAsString("Type", "Unknown");
        break;
    }

    return tags;
}

DM_TagGroupToken_1Ref h5_info_location(const char* filename, DM_StringToken location)
{
    DM::TagGroup tags;

    PLUG_IN_ENTRY

        file_handle_t file(H5Fopen(filename, H5F_ACC_RDONLY, H5P_DEFAULT));
        if (!file.valid()) {
            warning("h5_info: Can't open file '%s'.", filename);
            return NULL;
        }

        std::string loc_name = to_UTF8(DM::String(location));
        tags = get_object_info(file.get(), "", loc_name.c_str());

    PLUG_IN_EXIT

    return tags.release();
}

DM_TagGroupToken_1Ref h5_info_root(const char* filename)
{
    DM::TagGroup tags;

    PLUG_IN_ENTRY

        file_handle_t file(H5Fopen(filename, H5F_ACC_RDONLY, H5P_DEFAULT));
        if (!file.valid()) {
            warning("h5_info: Can't open file '%s'.", filename);
            return NULL;
        }

        tags = get_object_info(file.get(), "", "/");

    PLUG_IN_EXIT

    return tags.release();
}

bool h5_delete(const char* filename, DM_StringToken location)
{
    PLUG_IN_ENTRY

        file_handle_t file(H5Fopen(filename, H5F_ACC_RDWR, H5P_DEFAULT));
        if (!file.valid()) {
            warning("h5_delete: Can't open file '%s'.", filename);
            return NULL;
        }

        std::string loc_name = to_UTF8(DM::String(location));
        if (H5Ldelete(file.get(), loc_name.c_str(), H5P_DEFAULT) < 0) {
            warning("h5_delete: Error deleting object '%s'.", loc_name.c_str());
            dump_HDF_error_stack();
            return false;
        }

    PLUG_IN_EXIT

    return true;
}

bool h5_exists(const char* filename, DM_StringToken location)
{
    htri_t result;

    PLUG_IN_ENTRY

        file_handle_t file(H5Fopen(filename, H5F_ACC_RDONLY, H5P_DEFAULT));
        if (!file.valid()) {
            warning("h5_exists: Can't open file '%s'.", filename);
            return NULL;
        }

        std::string loc_name = to_UTF8(DM::String(location));
        result = H5Lexists(file.get(), loc_name.c_str(), H5P_DEFAULT);
        if (result < 0) {
            warning("h5_exists: Error checking existance of object '%s'.", loc_name.c_str());
            dump_HDF_error_stack();
            return false;
        }

    PLUG_IN_EXIT

    return result;
}
