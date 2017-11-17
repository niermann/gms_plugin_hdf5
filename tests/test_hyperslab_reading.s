// NOTE
//  * You must have unittest.s installed as a script library within DM
//  * The current directory must contain the test data:
//    Import script to DM and immediately execute it
//  * _tmp_dir must contain to a tmp directory (user must have write permission)

     
class Test_H5_Hyperslab_Reading: TestCase
{
    string _cur_dir, _file_path
    
    void setup(Object self)
    {
        _cur_dir = GetApplicationDirectory(0, 0);
        _file_path = PathConcatenate(_cur_dir, "hyperslab.hdf5");
    }
    
    void teardown(Object self)
    {
    }

    void test_read_slice1(Object self)
    {
        TagGroup offsets = NewTagList()
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        
        // Offset 0, 0, 0, 0
        Image data := h5_read_dataset_slice1(_file_path, "data", offsets, 0, 16, 1)
        self.assert_valid("data", data)
        self.assert_eq("data.ndim", ImageGetNumDimensions(data), 1)
        self.assert_eq("data.dim", ImageGetDimensionSize(data, 0), 16)
		self.assert_eq("data[]", sum(abs(data - icol)), 0)
    }

    void test_read_slice1_offsets(Object self)
    {
        TagGroup offsets = NewTagList()
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        offsets.TagGroupInsertTagAsLong(infinity(), 1)
        offsets.TagGroupInsertTagAsLong(infinity(), 2)
        offsets.TagGroupInsertTagAsLong(infinity(), 3)
        
        // Offset 0, 1, 2, 3
        Image data := h5_read_dataset_slice1(_file_path, "data", offsets, 0, 16, 1)
        self.assert_valid("data", data)
        self.assert_eq("data.ndim", ImageGetNumDimensions(data), 1)
        self.assert_eq("data.dim", ImageGetDimensionSize(data, 0), 16)
		self.assert_eq("data[]", sum(abs(data - icol - 1 * 16 - 2 * 256 - 3 * 4096)), 0)
    }

    void test_read_slice1_dimension(Object self)
    {
        TagGroup offsets = NewTagList()
        offsets.TagGroupInsertTagAsLong(infinity(), 11)
        offsets.TagGroupInsertTagAsLong(infinity(), 4)
        offsets.TagGroupInsertTagAsLong(infinity(), 2)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        
        // Offset 11, 4, 2, 0
        Image data := h5_read_dataset_slice1(_file_path, "data", offsets, 2, 10, 1)
        self.assert_valid("data", data)
        self.assert_eq("data.ndim", ImageGetNumDimensions(data), 1)
        self.assert_eq("data.dim", ImageGetDimensionSize(data, 0), 10)
		self.assert_eq("data[]", sum(abs(data - icol * 256 - 11 - 4 * 16 - 2 * 256)), 0)
    }

    void test_read_slice1_slice(Object self)
    {
        TagGroup offsets = NewTagList()
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        
        // Offset 0, 0, 0, 0
        Image data := h5_read_dataset_slice1(_file_path, "data", offsets, 3, 5, 3)
        self.assert_valid("data", data)
        self.assert_eq("data.ndim", ImageGetNumDimensions(data), 1)
        self.assert_eq("data.dim", ImageGetDimensionSize(data, 0), 5)
		self.assert_eq("data[]", sum(abs(data - icol * 4096 * 3)), 0)
    }

    void test_read_slice1_error(Object self)
    {
        TagGroup offsets = NewTagList()
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        
        // Only 3 offsets
        Image data := h5_read_dataset_slice1(_file_path, "data", offsets, 3, 5, 3)
        self.assert_not_valid("invalid offsets", data)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        
        // Invalid dimension
        data := h5_read_dataset_slice1(_file_path, "data", offsets, 4, 5, 3)
        self.assert_not_valid("invalid dimension", data)
        data := h5_read_dataset_slice1(_file_path, "data", offsets, -1, 5, 3)
        self.assert_not_valid("invalid dimension", data)

        // Invalid stride
        data := h5_read_dataset_slice1(_file_path, "data", offsets, 0, 5, 0)
        self.assert_not_valid("invalid stride", data)
    }


    void test_read_slice2(Object self)
    {
        TagGroup offsets = NewTagList()
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        
        // Offset 0, 0, 0, 0
        Image data := h5_read_dataset_slice2(_file_path, "data", offsets, 0, 16, 1, 1, 16, 1)
        self.assert_valid("data", data)
        self.assert_eq("data.ndim", ImageGetNumDimensions(data), 2)
        self.assert_eq("data.dim[0]", ImageGetDimensionSize(data, 0), 16)
        self.assert_eq("data.dim[1]", ImageGetDimensionSize(data, 1), 16)
		self.assert_eq("data[]", sum(abs(data - icol - irow * 16)), 0)
    }

    void test_read_slice2_offsets(Object self)
    {
        TagGroup offsets = NewTagList()
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        offsets.TagGroupInsertTagAsLong(infinity(), 1)
        offsets.TagGroupInsertTagAsLong(infinity(), 2)
        offsets.TagGroupInsertTagAsLong(infinity(), 3)
        
        // Offset 0, 1, 2, 3
        Image data := h5_read_dataset_slice2(_file_path, "data", offsets, 0, 16, 1, 1, 12, 1)
        self.assert_valid("data", data)
        self.assert_eq("data.ndim", ImageGetNumDimensions(data), 2)
        self.assert_eq("data.dim", ImageGetDimensionSize(data, 0), 16)
        self.assert_eq("data.dim", ImageGetDimensionSize(data, 1), 12)
		self.assert_eq("data[]", sum(abs(data - icol - irow * 16 - 1 * 16 - 2 * 256 - 3 * 4096)), 0)
    }

    void test_read_slice2_dimension(Object self)
    {
        TagGroup offsets = NewTagList()
        offsets.TagGroupInsertTagAsLong(infinity(), 11)
        offsets.TagGroupInsertTagAsLong(infinity(), 4)
        offsets.TagGroupInsertTagAsLong(infinity(), 2)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        
        // Offset 11, 4, 2, 0
        Image data := h5_read_dataset_slice2(_file_path, "data", offsets, 2, 10, 1, 3, 16, 1)
        self.assert_valid("data", data)
        self.assert_eq("data.ndim", ImageGetNumDimensions(data), 2)
        self.assert_eq("data.dim[0]", ImageGetDimensionSize(data, 0), 10)
        self.assert_eq("data.dim[1]", ImageGetDimensionSize(data, 1), 16)
		self.assert_eq("data[]", sum(abs(data - icol * 256 - irow * 4096 - 11 - 4 * 16 - 2 * 256)), 0)
    }

    void test_read_slice2_slice(Object self)
    {
        TagGroup offsets = NewTagList()
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        
        // Offset 0, 0, 0, 0
        Image data := h5_read_dataset_slice2(_file_path, "data", offsets, 1, 5, 3, 3, 6, 2)
        self.assert_valid("data", data)
        self.assert_eq("data.ndim", ImageGetNumDimensions(data), 2)
        self.assert_eq("data.dim[0]", ImageGetDimensionSize(data, 0), 5)
        self.assert_eq("data.dim[1]", ImageGetDimensionSize(data, 1), 6)
		self.assert_eq("data[]", sum(abs(data - irow * 4096 * 2 - icol * 16 * 3)), 0)
    }

    void test_read_slice2_error(Object self)
    {
        TagGroup offsets = NewTagList()
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        
        // Only 3 offsets
        Image data := h5_read_dataset_slice2(_file_path, "data", offsets, 0, 16, 1, 3, 5, 3)
        self.assert_not_valid("invalid offsets", data)
        offsets.TagGroupInsertTagAsLong(infinity(), 0)
        
        // Invalid dimension
        data := h5_read_dataset_slice2(_file_path, "data", offsets, 0, 16, 1, 4, 5, 3)
        self.assert_not_valid("invalid dimension", data)
        data := h5_read_dataset_slice2(_file_path, "data", offsets, 0, 16, 1, -1, 5, 3)
        self.assert_not_valid("invalid dimension", data)

        // Invalid dimension order
        data := h5_read_dataset_slice2(_file_path, "data", offsets, 1, 16, 1, 0, 16, 1)
        self.assert_not_valid("invalid dimension order", data)

        // Invalid stride
        data := h5_read_dataset_slice2(_file_path, "data", offsets, 0, 16, 1, 0, 5, 0)
        self.assert_not_valid("invalid stride", data)
    }

    Test_H5_Hyperslab_Reading(Object self)
    {
        self.register_test("test_read_slice1")
        self.register_test("test_read_slice1_offsets")
        self.register_test("test_read_slice1_dimension")
        self.register_test("test_read_slice1_slice")
        self.register_test("test_read_slice1_error")

        self.register_test("test_read_slice2")
        self.register_test("test_read_slice2_offsets")
        self.register_test("test_read_slice2_dimension")
        self.register_test("test_read_slice2_slice")
        self.register_test("test_read_slice2_error")
    }
}

{
    Object runner = alloc(TestRunner)
    runner.register_test_case(alloc(Test_H5_Hyperslab_Reading))
    runner.start()
}
