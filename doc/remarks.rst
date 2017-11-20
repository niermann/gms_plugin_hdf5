Remarks
=======

.. _complex-types-label:

Complex types
-------------

    As HDF has no primitive complex data types, complex data is saved
    as compound data types, with two H5T_FLOAT fields "r" and "i" for
    the real and imaginary parts, respectively. 
    
    When complex data is read from the HDF file, compounds with
    two H5T_FLOAT fields name either "r"/"i", "re"/"im", or "real"/"imag" 
    are recognized and read as complex data. The name comparison for the
    field names is done case independent.
    
    This is the same way of handling complex types as done by ``h5py``, 
    the HDF wrapper for python.
    
.. _data-types-label:

Data types
----------

    While HDF can handle virtually any data type, Digital Micrograph has only
    a few data types. The plugin itself, only supports integer, real and complex
    data types. While integer and real data can be handled natively by
    the HDF library, complex types are handled as described in :ref:`complex-types-label`.
    
    Internally Digital Micrograph describes the data types by a number (DM-Type
    in the following table), these numbers are for instance returned by 
    the ``ImageGetDataType()`` function.
    
    Supported data types:

    +-------+-------------------+-------------------+-------------------------------------------+
    |DM Type|DM Name            |HDF equivalent     |Remarks                                    |
    +=======+===================+===================+===========================================+
    |1      |Integer 2 Signed   |HDF_NATIVE_INT16   |                                           |
    +-------+-------------------+-------------------+-------------------------------------------+
    |2      |Real 4             |HDF_NATIVE_FLOAT   |                                           |
    +-------+-------------------+-------------------+-------------------------------------------+
    |3      |Complex 8          |HDF_COMPOUND       |See :ref:`complex-types-label`             |
    |       |                   |                   |PackedComplex 8 is also saved as this type |
    +-------+-------------------+-------------------+-------------------------------------------+
    |6      |Integer 1 Unsigned |HDF_NATIVE_UINT8   |                                           |
    +-------+-------------------+-------------------+-------------------------------------------+
    |7      |Integer 4 Signed   |HDF_NATIVE_INT32   |                                           |
    +-------+-------------------+-------------------+-------------------------------------------+
    |9      |Integer 1 Signed   |HDF_NATIVE_INT8    |                                           |
    +-------+-------------------+-------------------+-------------------------------------------+
    |10     |Integer 2 Unsigned |HDF_NATIVE_UINT16  |                                           |
    +-------+-------------------+-------------------+-------------------------------------------+
    |11     |Integer 4 Unsigned |HDF_NATIVE_UINT32  |                                           |
    +-------+-------------------+-------------------+-------------------------------------------+
    |12     |Real 8             |HDF_NATIVE_DOUBLE  |                                           |
    +-------+-------------------+-------------------+-------------------------------------------+
    |13     |Complex 16         |HDF_COMPOUND       |See :ref:`complex-types-label`             |
    |       |                   |                   |PackedComplex 16 is also saved as this type|
    +-------+-------------------+-------------------+-------------------------------------------+
    |39     |Integer 8 Signed   |HDF_NATIVE_INT64   |Only supported in GMS versions >= 2.0      |
    +-------+-------------------+-------------------+-------------------------------------------+
    |40     |Integer 8 Unsigned |HDF_NATIVE_UINT64  |Only supported in GMS versions >= 2.0      |
    +-------+-------------------+-------------------+-------------------------------------------+

.. _data-spaces-label:

Dataspaces
----------

    Multidimensional datasets in HDF5 files are stored in a column-major (a.k.a. C style) order. 
    This means that items with successive indices in the last dimension are stored in adjacent 
    file positions, while items with successive indices in the non-last dimensions are
    stored non-adjacently.

    Digital Micrograph on the opposite has a row-major (a.k.a. Fortran style) order. Items with 
    successive indices in the first dimension are stored in adjacent memory positions, while 
    items with successive indices in the non-first dimensions are stored non-adjacently.

    Typical 3D datasets are stored in a way, that adjacent items in X direction are stored adjacently,
    while adjacent items in Y direction are stored farer apart, and adjacent items in Z direction are 
    stored even farer apart. For HDF5 storage such a dataset is indexed as ``[Z,Y,X]`` while for
    Digital Micrograph it is indexed as ``[X,Y,Z]``.
    
    In order to adjust for this differences, the order of all indices is reversed by the
    plugin. The first dimension in a plugin call, always refers to the last dimension in the
    HDF5 dataset and vice-versa.

    For more details on ordering see for instance the `Wikipedia article <https://en.wikipedia.org/wiki/Row-_and_column-major_order>`_.

.. _string-encoding-label:

String encoding and file names
------------------------------

    Strings in Digital Micrograph are unicode strings. The only exception are the
    names of tags in TagGroups, these are single byte strings. However, it is undocumented
    what encoding is used in tags names (most likely Latin1).
    
    Names in HDF are best handled as unicodes strings (these are internally encoded
    as UTF8 strings). While this causes no problems when these are converted to
    Digital Micrograph strings, a problem remains when it comes to attributes. The
    plugin converts the attributes of a HDF object to a taglist, thus the unicode
    HDF names must be converted to single-byte strings. The plugin currently encodes
    these attribute names as UTF8. 
    
    Another problem arises, when it comes to filenames. The HDF library uses
    single-byte file names, which are passed verbatim to the C standard library. 
    Windows usually uses unicode file names and converts the single byte strings
    passed to the C standard library to unicode strings using the encoding specified
    by the selected code page. When is comes to filenames, the plugin currently uses
    Digital Micrographs default unicode to single-byte conversion, to create the 
    single byte filenames required for the HDF library. However, it is undocumented,
    what encoding is used by DM in this conversion.
