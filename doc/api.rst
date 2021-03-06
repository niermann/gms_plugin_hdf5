.. default-domain:: cpp

Functions of the plugin
=======================
        
.. function:: string h5_version()

    Returns version string for the plugin.
        
.. function:: bool h5_is_file(string filename)

    Returns non-zero if *filename* references a HDF5 file.

.. cpp:function:: taggroup h5_info(string filename, string location = "/")

    Gives informations about the HDF5 object *location* of file *filename*. If *location* is "/" the contents of the file is listed.
    The returned ``taggroup`` object contains keys depending on the type of the HDF5 object. 
    
    .. tabularcolumns:: |p{0.15\linewidth}|p{0.20\linewidth}|p{0.55\linewidth}|

    +---------------+-------------------+-------------------------------------------------------------------+
    |Type           |Key                |Value                                                              |
    +===============+===================+===================================================================+
    |All            |"Name"             |Name of the object (``string``).                                   |
    |               +-------------------+-------------------------------------------------------------------+
    |               |"Type"             |Type of the object (``string``). Possible values are               |
    |               |                   |"DataSet", "Group", "NamedDataType", "SoftLink",                   |
    |               |                   |"ExternalLink", and "Unknown"                                      |
    +---------------+-------------------+-------------------------------------------------------------------+
    |"DataSet"      |"DataSpaceClass"   |Kind of data space (``string``). Possible values are               |
    |               |                   |"SCALAR", "SIMPLE", and "Unknown"                                  |
    |               +-------------------+-------------------------------------------------------------------+
    |               |"Rank"             |Only for data space class "SIMPLE" and "SCALAR" (``long``)         |
    |               +-------------------+-------------------------------------------------------------------+
    |               |"Size"             |Only for data space class "SIMPLE":                                |
    |               |                   |Tag list array with extents.                                       |
    |               +-------------------+-------------------------------------------------------------------+
    |               |"MaxSize"          |Only for data space class "SIMPLE":                                |
    |               |                   |Tag list with maximum extents. -1 represents                       |
    |               |                   |an unlimited dimension.                                            |
    |               +-------------------+-------------------------------------------------------------------+
    |               |"ChunkSize"        |Only for data space class "SIMPLE": one dimensional                |
    |               |                   |integer array with chunk sizes. May be omitted on                  |
    |               |                   |non-unlimited data spaces.                                         |
    |               +-------------------+-------------------------------------------------------------------+
    |               |"DataTypeClass"    |Class of type (``string``)                                         |
    |               |                   |"INTEGER", "FLOAT", "STRING", "BITFIELD", "OPAQUE", "COMPOUND",    |
    |               |                   |"REFERENCE", "ENUM", "VLEN", "ARRAY", or "Unknown"                 |
    |               +-------------------+-------------------------------------------------------------------+
    |               |"DataType"         |If an array of the type can be read, this is the data type         |
    |               |                   |of it (``long``), same values as ``ImageGetDataType()`` returns.   |
    +---------------+-------------------+-------------------------------------------------------------------+
    |"Group"        |"Contents"         |TagList (indexed ``taggroup``) with members of the                 |
    |               |                   |group. Each member again is a HDF5 object, described by            |
    |               |                   |a ``taggroup`` with the keys given in this table.                  |
    +---------------+-------------------+-------------------------------------------------------------------+
    |"SoftLink"     |"Path"             |HDF5-Path of the linked object (``string``)                        |
    +---------------+-------------------+-------------------------------------------------------------------+
    |"ExternalLink" |"Path"             |HDF5-Path of the linked object (``string``) in the external file.  |
    |               +-------------------+-------------------------------------------------------------------+
    |               |"Filename"         |File-Path of the external file (``string``)                        |
    |               +-------------------+-------------------------------------------------------------------+
    |               |"Flags"            |Unused currently (``number``).                                     |
    +---------------+-------------------+-------------------------------------------------------------------+
    

.. cpp:function:: taggroup h5_read_attr(string handle, string location)

    Reads attributes of *location* of file *filename*. Use "/" as *location* to read the attributes of the file object itself.
    The attributes are returned as ``TagGroup``, where the keys are the names of the attributes and the
    values are their value. 
    
    Only some types of attributes are supported. If the attribute's type is not 
    supported, it is missing in the returned ``TagGroup``. Supported types are:
    
        * **H5T_INTEGER: scalar** Returned as ``Number``. The value is clipped to a 32-bit integer.
        * **H5T_FLOAT: scalar** Returned as ``Number``. 
        * **H5T_STRING: scalar** Returned as ``String``. Fixed and variable length strings are returned. The strings are read as UTF-8 strings.
        * **complex: scalar** Returned as ``Number``.

    .. note::
    
        Colons are interpreted as TagGroup path separators. If invalid characters, e.g. "[" or "]", occur in the attribute name,
        the attributes are not read. 

        DigitalMicrograph only supports 8 bit tag names, but it is undocumented how these tag names are
        encoded. The attribute names on the other side, might contain unicode characters. This function
        encodes the attribute name in UTF8 (See :ref:`string-encoding-label`)
        
        Integer/float/complex arrays are read as lists of the scalar values. Multidimensional arrays are read as list of lists.
        
        The sizes compared to the HDF5 file are reported in reversed order (see :ref:`data-spaces-label`).

.. cpp:function:: bool h5_exists_attr(string filename, string location, string attr)

    Returns whether an attribute *attr* exists at *location* from file *filename*.

.. cpp:function:: bool h5_delete_attr(string filename, string location, string attr)

    Deletes an attribute *attr* exists at *location* from file *filename*.
    Returns whether deletion was successful. 
    The function returns false on a try to delete a nonexisting attribute.

.. cpp:function:: image h5_read_dataset(string filename, string location)

    Reads dataset *location* from *filename*. Only some data types are supported (see :ref:`data-types-label`). Only data
    spaces with rank 0 to 4 are supported. On failure an invalid image is returned.
    
    Scalar dataspaces (rank 0) are returned as one dimensional image with one element.

.. cpp:function:: image h5_read_dataset_slice1(string filename, string location, TagGroup offset, number dim0, number count0, number stride0)

    Reads 1D subset of dataset *location* from *filename*. This method can be used to read a one
    dimensional slice along an arbitrary dimension from a higher dimensional dataset. 
    
    *offset* is a TagList of numbers, where the index of the first element of the returned
    array for all dimensions of the dataset is given. The tag list must have a size corresponding
    to the number of dimensions.
    
    *dim0* is the dimension along which the slice is returned, *count0* the number of elements
    in the slice. *stride0* the distance between adjacent elements in the returned slice (e.g. a 
    *stride0* of 2 will return only every second element).
    
    Only some data types are supported (see :ref:`data-types-label`). For order of
    dimensions see :ref:`data-spaces-label`. Strides must be > 0.

    On failure an invalid image is returned.

.. cpp:function:: image h5_read_dataset_slice2(string filename, string location, TagGroup offset, number dim0, number count0, number stride0, number dim1, number count1, number stride1)

    Reads 2D subset of dataset *location* from *filename*. This method can be used to read a two
    dimensional slice along an arbitrary dimension from a higher dimensional dataset. 
    
    *offset* is a TagList of numbers, where the index of the first element of the returned
    array for all dimensions of the dataset is given. The tag list must have a size corresponding
    to the number of dimensions.
    
    *dim0* is the X-dimension along which the slice is returned, *count0* the number of elements
    in the slice. *stride0* the distance between adjacent elements in the returned slice (e.g. a 
    *stride0* of 2 will return only every second element).

    *dim1* is the Y-dimension along which the slice is returned, *count1* the number of elements
    in this direction. *stride1* the distance between adjacent elements. 
    
    Due to a limitation of the underlying HDF5 library the order of the dimensions must be 
    increasing, i.e. *dim0* < *dim1*. Using this call to transpose the dataset is not possible.
    
    Only some data types are supported (see :ref:`data-types-label`). For order of
    dimensions see :ref:`data-spaces-label`. Strides must be > 0.

    On failure an invalid image is returned.

.. cpp:function:: image h5_read_dataset_slice3(string filename, string location, TagGroup offset, number dim0, number count0, number stride0, number dim1, number count1, number stride1, number dim2, number count2, number stride2)

    Reads 3D subset of dataset *location* from *filename*. This method can be used to read a three
    dimensional slice along an arbitrary dimension from a higher dimensional dataset. 
    
    *offset* is a TagList of numbers, where the index of the first element of the returned
    array for all dimensions of the dataset is given. The tag list must have a size corresponding
    to the number of dimensions.
    
    *dim0* is the X-dimension along which the slice is returned, *count0* the number of elements
    in the slice. *stride0* the distance between adjacent elements in the returned slice (e.g. a 
    *stride0* of 2 will return only every second element).

    *dim1* is the Y-dimension along which the slice is returned, *count1* the number of elements
    in this direction. *stride1* the distance between adjacent elements. 

    *dim2* is the Z-dimension along which the slice is returned, *count2* the number of elements
    in this direction. *stride2* the distance between adjacent elements. 
    
    Due to a limitation of the underlying HDF5 library the order of the dimensions must be 
    increasing, i.e. *dim0* < *dim1* < *dim2*. Using this call to transpose the dataset is not possible.
    
    Only some data types are supported (see :ref:`data-types-label`). For order of
    dimensions see :ref:`data-spaces-label`. Strides must be > 0.

    On failure an invalid image is returned.

.. cpp:function:: string h5_read_string_dataset(string filename, string location)

    Reads string dataset *location* from *filename*. This only works with datasets 
    with ``DataTypeClass`` of "STRING" (see :func:`h5_info`). Only data spaces with one
    single element are supported (scalars or arrays with one element). Strings are
    assumed to be UTF-8 encoded.

    On failure an invalid string is returned.

.. cpp:function:: bool h5_create_dataset(string filename, string location, Image* data)

    Creates *dataset* in file *filename* from image data. If the file *filename* does not exist,
    it is created. Only some data types are supported (see :ref:`data-types-label`). The function will fail
    if there is already a dataset of this name.
    
    Returns zero on failure and non-zero on success.

.. cpp:function:: bool h5_create_dataset(string filename, string location, number datatype, TagGroup size)

    Creates empty dataset *dataset* in file *filename* from image data. If the file *filename* does not exist,
    it is created. The dataset is filled with the default value. *datatype* is the type of the dataset, the
    values are the same as returned by ImageGetDataType() (see :ref:`data-types-label` for a list). 
    *size* must be a tag list containing the extents of the datasets (only positive numbers allowed).
    
    Returns zero on failure and non-zero on success.

.. cpp:function:: bool h5_exists(string filename, string location, string attr)

    Returns whether an object *location* exists in file *filename*.

.. cpp:function:: bool h5_delete(string filename, string location)

    Remove object *location* from file *filename*.
    
    Returns zero on failure and non-zero on success.
