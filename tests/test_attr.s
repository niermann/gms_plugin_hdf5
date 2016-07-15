// NOTE
//  * You must have unittest.s installed as a script library within DM
//  * The current directory must contain the test data:
//    Import script to DM and immediately execute it
     
class Test_H5_Attr: TestCase
{
    string _file_path
    string _cur_dir
    
    void setup(Object self)
    {
        _cur_dir = GetApplicationDirectory(0, 0);
        _file_path = PathConcatenate(_cur_dir, "attr.hdf5");
    }
    
    void test_not_a_file(Object self)
    {
        string not_a_file = PathConcatenate(_cur_dir, "not_a_hdf5_file.txt")
        taggroup attr = h5_read_attr(not_a_file, "/data")
        self.assert_false("attr", TagGroupIsValid(attr))
    }
    
    void test_noent(Object self)
    {
        taggroup attr = h5_read_attr(_file_path, "/noent")
        self.assert_false("attr", TagGroupIsValid(attr))
    }

    void test_no_attr(Object self)
    {
        taggroup attr = h5_read_attr(_file_path, "/cdata")
        self.assert_eq("len(attr)", 0, TagGroupCountTags(attr))
    }

    void test_scalar_attr(Object self)
    {
        taggroup attr = h5_read_attr(_file_path, "/data")
        self.assert_valid("attr", attr)
        
        self.assert_tag_eq("attr", attr, "int", 5)
        self.assert_tag_eq("attr", attr, "float", 6.0)
        self.assert_tag_eq("attr", attr, "complex", complex(7.0, 8.0))
        self.assert_tag_eq("attr", attr, "deeply/nested/string", "Some Data")
    }

    void test_string_array(Object self)
    {
        taggroup attr = h5_read_attr(_file_path, "/data")
        self.assert_valid("attr", attr)
        
        self.assert_tag_count("attr", attr, "StrList", 3)
        self.assert_tag_eq("attr", attr, "StrList[0]", "Eins")
        self.assert_tag_eq("attr", attr, "StrList[1]", "Zwo")
        self.assert_tag_eq("attr", attr, "StrList[2]", "Und die Drei")
    }

    void test_complex_array(Object self)
    {
        taggroup attr = h5_read_attr(_file_path, "/data")
        self.assert_valid("attr", attr)
        
        self.assert_tag_count("attr", attr, "clist", 5)
        Number n
        for (n = 0; n < 5; n++)
            self.assert_tag_eq("attr", attr, "clist[" + n + "]", complex(n, 0))
    }

    void test_integer_array_1d(Object self)
    {
        taggroup attr = h5_read_attr(_file_path, "/data")
        self.assert_valid("attr", attr)
        
        self.assert_tag_count("attr", attr, "list", 3)
        Number n
        for (n = 0; n < 3; n++)
            self.assert_tag_eq("attr", attr, "list[" + n + "]", n + 1)
    }

    void test_integer_array_2d(Object self)
    {
        taggroup attr = h5_read_attr(_file_path, "/data")
        self.assert_valid("attr", attr)
        
        Number x = 0, n, m
        self.assert_tag_count("attr", attr, "array", 10)
        for (n = 0; n < 10; n++) {
            self.assert_tag_count("attr", attr, "array[" + n + "]", 10)
            for (m = 0; m < 10; m++) {
                self.assert_tag_eq("attr", attr, "array[" + n + "][" + m + "]", x)
                x++
            }
        }
    }
    
    void test_integer_array_3d(Object self)
    {
        taggroup attr = h5_read_attr(_file_path, "/data")
        self.assert_valid("attr", attr)
        
        Number x = 0, n, m, k
        self.assert_tag_count("attr", attr, "threeDim", 5)
        for (n = 0; n < 5; n++) {
            self.assert_tag_count("attr", attr, "threeDim[" + n + "]", 5)
            for (m = 0; m < 5; m++) {
                self.assert_tag_count("attr", attr, "threeDim[" + n + "][" + m + "]", 5)
                for (k = 0; k < 5; k++) {
                    self.assert_tag_eq("attr", attr, "threeDim[" + n + "][" + m + "][" + k + "]", x)
                    x++
                }
            }
        }
    }
    
    void test_unicode(Object self)
    {
        taggroup attr = h5_read_attr(_file_path, "/data")
        self.assert_valid("attr", attr)
        
        number pi // Tag name below is \u03C0 encoded as UTF8
        self.assert_true("attr", TagGroupGetTagAsNumber(attr, "π", pi))
        self.assert_almost("attr[pi]", pi, 3.141, 1e-2)

        // This would fail, since attribute names are encoded in an unknown way
        // self.assert_tag_eq("attr", attr, "\u03C0", pi)
        
        // Variable length string
        self.assert_tag_eq("attr", attr, "unicode_string", "Theta: \u0398, Xi: \u03be");
        
        // Fixed length string array
        self.assert_tag_count("attr", attr, "unicode_list", 5)
        number n
        for (n = 0; n < 5; n++)
            self.assert_tag_eq("attr", attr, "unicode_list[" + n + "]", "Theta: \u0398, Xi: \u03be")
    }
    
    void test_existance(Object self)
    {
        taggroup attr = h5_read_attr(_file_path, "/data")
        self.assert_valid("attr", attr)
        
        self.assert_true("int", h5_exists_attr(_file_path, "/data", "int"))
        self.assert_false("not_a_file", h5_exists_attr("not_a_hdf5_file.txt", "/data", "int"))
        self.assert_false("noent", h5_exists_attr(_file_path, "noent", "int"))
        self.assert_false("attr", h5_exists_attr(_file_path, "noent", "_bla_bla_foo"))
    }

    Test_H5_Attr(Object self)
    {
        self.register_test("test_not_a_file")
        self.register_test("test_noent")
        self.register_test("test_no_attr")
        self.register_test("test_scalar_attr")
        self.register_test("test_string_array")
        self.register_test("test_complex_array")
        self.register_test("test_integer_array_1d")
        self.register_test("test_integer_array_2d")
        self.register_test("test_integer_array_3d")
        self.register_test("test_unicode")
        self.register_test("test_existance")
    }
}

{
    Object runner = alloc(TestRunner)
    runner.register_test_case(alloc(Test_H5_Attr))
    runner.start()
}
