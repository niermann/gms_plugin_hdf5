//**************************************************************************
//
//  FILENAME
//      CMD_import_hdf5.s
//
//  DESCRIPTION
//      Import image(s) from HDF5 file
//
//  AUTHOR
//      Tore Niermann
//
//  REQUIREMENTS
//      HDF5 plugin version >= 1.0
//
//**************************************************************************

void H5IMPORT_import_single(String filename, String name, Number append_name)
{
    // Get array
    Image array := h5_read_dataset(filename, name)
    if (!ImageIsValid(array)) {
        OkDialog("Error reading dataset " + name + " of file " + filename + ".\nSee debug window for details.\n")
        return
    }

    // Add attributes
    TagGroup attr = h5_read_attr(filename, name)
    if (!TagGroupIsValid(attr))
        attr = NewTagGroup()    // Avoid later exceptions

    TagGroup tags = ImageGetTagGroup(array)
    TagGroupSetTagAsTagGroup(tags, "Attributes", attr)

    // Set name
    if (append_name)
        ImageSetName(array, PathExtractBaseName(filename, 0) + name)
    else
        ImageSetName(array, PathExtractBaseName(filename, 0))

    // Look for dimension scales
    TagGroup offset_group, scale_group, unit_group
    if (!TagGroupGetTagAsTagGroup(attr, "dim_offset", offset_group))
        offset_group = NewTagList()
    if (!TagGroupGetTagAsTagGroup(attr, "dim_scale", scale_group))
        scale_group = NewTagList()
    if (!TagGroupGetTagAsTagGroup(attr, "dim_unit", unit_group))
        unit_group = NewTagList()

    Number rank = ImageGetNumDimensions(array)
    Number n
    for (n = 0; n < rank; n++) {
        Number offset = 0.0
        Number scale = 1.0
        String unit = ""

        if (n < TagGroupCountTags(scale_group)) {
            TagGroup scale_list;

            // multi-dimensional scale?
            if (TagGroupGetIndexedTagAsTagGroup(scale_group, n, scale_list)) {
                // Only use diagonal elements
                if (n < TagGroupCountTags(scale_list))
                    if (TagGroupGetIndexedTagAsNumber(scale_list, n, scale))
                        ImageSetDimensionScale(array, n, scale)
            } else if (TagGroupGetIndexedTagAsNumber(scale_group, n, scale))
                ImageSetDimensionScale(array, n, scale)     // 1D scale
        }
        if (n < TagGroupCountTags(offset_group))
            if (TagGroupGetIndexedTagAsNumber(offset_group, n, offset))
                ImageSetDimensionOrigin(array, n, offset)
        if (n < TagGroupCountTags(unit_group))
            if (TagGroupGetIndexedTagAsString(unit_group, n, unit))
                ImageSetDimensionUnitString(array, n, unit)
    }

    // Look for intensity scale
    Number data_scale = 1.0
    if (TagGroupGetTagAsNumber(attr, "scale", data_scale))
        ImageSetIntensityScale(array, data_scale)
    Number data_offset = 0.0
    if (TagGroupGetTagAsNumber(attr, "offset", data_offset))
        ImageSetIntensityOrigin(array, data_offset)
    String data_unit
    if (TagGroupGetTagAsString(attr, "unit", data_unit))
        ImageSetIntensityUnitString(array, data_unit)

    // Look for more
    Number voltage
    if (TagGroupGetTagAsNumber(attr, "voltage(kV)", voltage))
        TagGroupSetTagAsNumber(tags, "Microscope Info:Voltage", voltage * 1e3)

    ShowImage(array)
}

String H5IMPORT_get_data_type_name(Number dtype)
{
    if (dtype == 1)
        return "Int16"
    else if (dtype == 2)
        return "Float32"
    else if (dtype == 3)
        return "Complex64"
    else if (dtype == 6)
        return "UInt8"
    else if (dtype == 7)
        return "Int32"
    else if (dtype == 9)
        return "UInt8"
    else if (dtype == 10)
        return "UInt16"
    else if (dtype == 11)
        return "UInt32"
    else if (dtype == 12)
        return "Float64"
    else if (dtype == 12)
        return "Complex128"
    else if (dtype == 39)
        return "Int64"
    else if (dtype == 40)
        return "UInt64"
    else
        return "<Unknown>"
}

void H5IMPORT_content_walker(TagGroup content, TagGroup &names, TagGroup &infos)
{
    String type, name

    if (!TagGroupGetTagAsString(content, "Type", type) || !TagGroupGetTagAsString(content, "Name", name))
        return;

    if (type == "DataSet") {
        // If data type is not supported, no "DataType" tag exists, and the query fails
        Number dtype
        if (!TagGroupGetTagAsNumber(content, "DataType", dtype))
            return

        Number rank
        if (!TagGroupGetTagAsNumber(content, "Rank", rank) || rank < 0 || rank > 4)
            return          // DM only supports up to 4D

        // Create size string
        String size_text = ""
        if (rank > 0) {
            TagGroup size
            if (!TagGroupGetTagAsTagGroup(content, "Size", size))
                return

            Number n
            for (n = 0; n < rank; n++) {
                Number dim
                TagGroupGetIndexedTagAsLong(size, n, dim)
                if (n > 0)
                    size_text = size_text + "x" + dim
                else
                    size_text = "" + dim
            }
        }

        // Create info string
        String info_text = name + " - " + H5IMPORT_get_data_type_name(dtype) + "[" + size_text + "]"

        TagGroupInsertTagAsString(names, -1, name)
        TagGroupInsertTagAsString(infos, -1, info_text)
    } else if (type == "Group") {
        TagGroup group_content
        if (!TagGroupGetTagAsTagGroup(content, "Contents", group_content))
            return

        Number num = TagGroupCountTags(group_content)
        Number n
        for (n = 0; n < num; n++) {
            TagGroup child
            if (TagGroupGetIndexedTagAsTagGroup(group_content, n, child))
                H5IMPORT_content_walker(child, names, infos)
        }
    }
}

Number H5IMPORT_select_dataset(String filename, TagGroup infos)
{
    TagGroup dialog = DLGCreateDialog(filename)
    dialog.DLGTableLayout(1, 2, 0)

    dialog.DLGAddElement(DLGCreateLabel( "There are multiple datasets in the HDF file.\nSelect dataset to import:" )) \
        .DLGExpand("X") \
        .DLGFill("X") \
        .DLGAnchor("West")
    TagGroup entries
    TagGroup choice = DLGCreateChoice(entries)
    dialog.DLGAddElement(choice) \
        .DLGExpand("X") \
        .DLGFill("X") \
        .DLGAnchor("West")

    entries.DLGAddChoiceItemEntry("<import all>")

    Number num = TagGroupCountTags(infos)
    Number n
    for (n = 0; n < num; n++) {
        String info
        TagGroupGetIndexedTagAsString(infos, n, info)
        entries.DLGAddChoiceItemEntry(info)
    }

    Object frame = alloc(uiframe).init(dialog)
    if (!frame.Pose())
        exit(0)

    return choice.DLGGetValue() - 1
}

// Scope needed to avoid memory leaks
{
    String filename
    if (!OpenDialog(Null, "Select HDF5 file", "*.hdf5", filename))
        exit(0)

    // Open file
    if(!h5_is_file(filename)) {
        OkDialog("Error opening file " + filename + ".\nNot a HDF5 file.\n")
        exit(0)
    }

    // Scan file
    TagGroup content = h5_info(filename)
    TagGroup names = NewTagList()
    TagGroup infos = NewTagList()
    H5IMPORT_content_walker(content, names, infos)

    Number num = TagGroupCountTags(infos)
    if (num == 0) {
        OkDialog("No supported datasets in file " + filename + ".\n")
        exit(-1)
    } else if (num > 1) {
        Number index = H5IMPORT_select_dataset(filename, infos)
        if (index < 0) {
            Number n
            for (n = 0; n < num; n++) {
                String name
                TagGroupGetIndexedTagAsString(names, n, name)
                H5IMPORT_import_single(filename, name, 1)
            }
        } else {
            String name
            TagGroupGetIndexedTagAsString(names, index, name)
            H5IMPORT_import_single(filename, name, 1)
        }
    } else {
        // Single image in file
        String name
        TagGroupGetIndexedTagAsString(names, 0, name)
        H5IMPORT_import_single(filename, name, 0)
    }
}

//**************************************************************************
