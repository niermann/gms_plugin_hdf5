// NOTE
//  * You must have unittest.s installed as a script library within DM
//  * The current directory must contain the test data:
//    Import script to DM and immediately execute it
//  * _tmp_dir must contain to a tmp directory (user must have write permission)

     
class Test_H5_DataSet: TestCase
{
    string _tmp_dir, _tmp_file
    string _cur_dir, _file_path
    
    void setup(Object self)
    {
        _cur_dir = GetApplicationDirectory(0, 0);
        _file_path = PathConcatenate(_cur_dir, "test2.hdf5");

        // Contrary to the documentation 6 (instead of 3) gives temporary directory
        _tmp_dir = GetApplicationDirectory(6, 1)
        
        // Create temporary filename
        while (_tmp_file == Null || DoesFileExist(_tmp_file)) {
            string file = Hex(GetHighResTickCount(), 16) + "_" + Hex(random() * 1e8, 8) + ".hdf5"
            _tmp_file = PathConcatenate(_tmp_dir, file);
        }
    }
    
    void teardown(Object self)
    {
        // Delete temporary file
        DeleteFile(_tmp_file)
    }

    void randomize_image(Object self, Image &img, Number offset, Number scale)
    {
        number sx = ImageGetDimensionSize(img, 0)
        number sy = ImageGetDimensionSize(img, 1)
        number sz = ImageGetDimensionSize(img, 2)
        
        Image tmp := ExprSize(sx, sy, sz, offset + random() * scale)
        img[0, 0, 0, sx, sy, sz] = tmp[0, 0, 0, sx, sy, sz]
    }
    
    void test_read_scalar(Object self)
    {
        Image data := h5_read_dataset(_file_path, "scalar")
        self.assert_valid("data", data)
        self.assert_eq("data.ndim", ImageGetNumDimensions(data), 1)
        self.assert_eq("data.dim", ImageGetDimensionSize(data, 0), 1)
        self.assert_eq("data.type", ImageGetDataType(data), 10)
        self.assert_eq("data[]", data.GetPixel(0, 0), 42)
    }

    void test_readwrite_integer(Object self)
    {
        Image data1 := IntegerImage("foo", 2, 1, 100, 100)
        self.randomize_image(data1, -32768, 65535)

        Image data2 := IntegerImage("foo", 1, 0, 10, 20, 30)
        self.randomize_image(data2, 0, 255)

        Image data3 := IntegerImage("foo", 4, 0, 128)
        self.randomize_image(data3, -(1 << 31), 1 << 32)

        self.assert_true("create_data1", h5_create_dataset(_tmp_file, "data1", data1))
        self.assert_true("create_data2", h5_create_dataset(_tmp_file, "data2", data2))
        self.assert_true("create_data3", h5_create_dataset(_tmp_file, "data3", data3))

        Image load1 := h5_read_dataset(_tmp_file, "data1")
        self.assert_valid("load1", load1)
        self.assert_eq("load1.ndim", ImageGetNumDimensions(load1), 2)
        self.assert_eq("load1.type", ImageGetDataType(load1), 1)
        self.assert_eq("sum(load1 - data1)", 0, sum(load1 - data1))

        Image load2 := h5_read_dataset(_tmp_file, "data2")
        self.assert_valid("load2", load2)
        self.assert_eq("load2.ndim", ImageGetNumDimensions(load2), 3)
        self.assert_eq("load2.type", ImageGetDataType(load2), 6)
        self.assert_eq("sum(load2 - data2)", 0, sum(load2 - data2))

        Image load3 := h5_read_dataset(_tmp_file, "data3")
        self.assert_valid("load3", load3)
        self.assert_eq("load3.ndim", ImageGetNumDimensions(load3), 1)
        self.assert_eq("load3.type", ImageGetDataType(load3), 11)
        self.assert_eq("sum(load3 - data3)", 0, sum(load3 - data3))
    }

    void test_readwrite_float(Object self)
    {
        Image data1 := RealImage("foo", 4, 100)
        self.randomize_image(data1, -0.5, 1.0)

        Image data2 := RealImage("foo", 8, 10, 20, 30)
        self.randomize_image(data2, -0.5, 1.0)

        self.assert_true("create_real1", h5_create_dataset(_tmp_file, "real1", data1))
        self.assert_true("create_real2", h5_create_dataset(_tmp_file, "real2", data2))

        Image load1 := h5_read_dataset(_tmp_file, "real1")
        self.assert_valid("load1", load1)
        self.assert_eq("load1.ndim", ImageGetNumDimensions(load1), 1)
        self.assert_eq("load1.type", ImageGetDataType(load1), 2)
        self.assert_eq("sum(load1 - data1)", 0, sum(load1 - data1))

        Image load2 := h5_read_dataset(_tmp_file, "real2")
        self.assert_valid("load2", load2)
        self.assert_eq("load2.ndim", ImageGetNumDimensions(load2), 3)
        self.assert_eq("load2.type", ImageGetDataType(load2), 12)
        self.assert_eq("sum(load2 - data2)", 0, sum(load2 - data2))
    }

    void test_readwrite_complex(Object self)
    {
        Image data1 := ComplexImage("foo", 8, 100)
        self.randomize_image(data1, -0.5, 1.0)

        Image data2 := ComplexImage("foo", 16, 10, 20, 30)
        self.randomize_image(data2, -0.5, 1.0)

        self.assert_true("create_cmp1", h5_create_dataset(_tmp_file, "cmp1", data1))
        self.assert_true("create_cmp2", h5_create_dataset(_tmp_file, "cmp2", data2))

        ComplexImage load1 := h5_read_dataset(_tmp_file, "cmp1")
        self.assert_valid("load1", load1)
        self.assert_eq("load1.ndim", ImageGetNumDimensions(load1), 1)
        self.assert_eq("load1.type", ImageGetDataType(load1), 3)
        self.assert_eq("sum(load1 - data1)", 0, sum(load1 - data1))

        ComplexImage load2 := h5_read_dataset(_tmp_file, "cmp2")
        self.assert_valid("load2", load2)
        self.assert_eq("load2.ndim", ImageGetNumDimensions(load2), 3)
        self.assert_eq("load2.type", ImageGetDataType(load2), 13)
        self.assert_eq("sum(load2 - data2)", 0, sum(load2 - data2))
    }

    void test_packed(Object self)
    {
        // COMPLEX8_PACKED_DATA: saved as complex
        Image img := NewImage("foo", 27, 100, 100)
        self.randomize_image(img, -0.5, 2.0)
        
        self.assert_true("create_packed1", h5_create_dataset(_tmp_file, "test1", img))

        ComplexImage load1 := h5_read_dataset(_tmp_file, "test1")
        self.assert_valid("load1", load1)
        self.assert_eq("load1.ndim", ImageGetNumDimensions(load1), 2)
        self.assert_eq("load1.type", ImageGetDataType(load1), 3)
        self.assert_eq("sum(load1 - data1)", 0, sum(load1 - img))
    }
      
    void test_unsupported(Object self)
    {
        Image img
        
        // RGB_DATA
        img := NewImage("foo", 8, 100, 100)
        self.assert_false("RGB_DATA", h5_create_dataset(_tmp_file, "test1", img))

        // RGBA_U8
        img := NewImage("foo", 25, 100, 100)
        self.assert_false("RGBA_FLOAT32_DATA", h5_create_dataset(_tmp_file, "test1", img))
    }
    
    void test_overwrite(Object self)
    {
        self.assert_false("data exists", h5_exists(_tmp_file, "data"))
        
        Image data1 := RealImage("foo", 4, 100)
        self.randomize_image(data1, -0.5, 1.0)

        Image data2 := RealImage("foo", 8, 10, 20, 30)
        self.randomize_image(data2, -0.5, 1.0)

        self.assert_true("write1", h5_create_dataset(_tmp_file, "data", data1))
        self.assert_true("data exists", h5_exists(_tmp_file, "data"))
        
        self.assert_false("write2", h5_create_dataset(_tmp_file, "data", data2))
        
        self.assert_true("data delete", h5_delete(_tmp_file, "data"))
        self.assert_false("data after delete", h5_exists(_tmp_file, "data"))

        self.assert_true("write2", h5_create_dataset(_tmp_file, "data", data2))

        Image load := h5_read_dataset(_tmp_file, "data")
        self.assert_valid("load", load)
        self.assert_eq("load.ndim", ImageGetNumDimensions(load), 3)
        self.assert_eq("load.type", ImageGetDataType(load), 12)
        self.assert_eq("sum(load - data2)", 0, sum(load - data2))
    }
    
    Test_H5_DataSet(Object self)
    {
        self.register_test("test_read_scalar")
        self.register_test("test_readwrite_integer")
        self.register_test("test_readwrite_float")
        self.register_test("test_readwrite_complex")
        self.register_test("test_packed")
        self.register_test("test_unsupported")
        self.register_test("test_overwrite")
    }
}

{
    Object runner = alloc(TestRunner)
    runner.register_test_case(alloc(Test_H5_DataSet))
    runner.start()
}
