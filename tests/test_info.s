// NOTE
//  * You must have unittest.s installed as a script library within DM
//  * The current directory must contain the test data:
//    Import script to DM and immediately execute it
     
class Test_H5_Info: TestCase
{
    string _file_path
    string _cur_dir
    
    void setup(Object self)
    {
        _cur_dir = GetApplicationDirectory(0, 0);
        _file_path = PathConcatenate(_cur_dir, "test2.hdf5");
    }
    
    void test_file_exists(Object self)
    {
        string not_a_file = PathConcatenate(_cur_dir, "not_a_hdf5_file.txt")
        self.assert_false("h5_is_file(not_a_file)", h5_is_file(not_a_file))
        self.assert_false("h5_is_file(nonexistant)", h5_is_file("nonexistant"))
        
        self.assert_true("h5_is_file(_file_path)", h5_is_file(_file_path))
    }
    
    void test_root(Object self)
    {
        taggroup info = h5_info(_file_path)
        self.assert_valid("root", info)

        self.assert_tag_eq("root", info, "Name", "/")
        self.assert_tag_eq("root", info, "Type", "Group")
        
        self.assert_tag_count("root", info, "Contents", 7)
    }
    
    void test_data(Object self)
    {
        taggroup info = h5_info(_file_path, "/data")
        self.assert_valid("data", info)

        self.assert_tag_eq("data", info, "Name", "/data")
        self.assert_tag_eq("data", info, "Type", "DataSet")
        self.assert_tag_eq("data", info, "DataSpaceClass", "SIMPLE")
        self.assert_tag_eq("data", info, "DataTypeClass", "FLOAT")
        self.assert_tag_eq("data", info, "DataType", 2)
        self.assert_tag_eq("data", info, "Rank", 2)
        
        self.assert_tag_count("data", info, "Size", 2)
        self.assert_tag_eq("data", info, "Size[0]", 10)
        self.assert_tag_eq("data", info, "Size[1]", 9)
    }

    void test_ch(Object self)
    {
        taggroup info = h5_info(_file_path, "/ch")
        self.assert_valid("ch", info)
        
        self.assert_tag_eq("ch", info, "Name", "/ch")
        self.assert_tag_eq("ch", info, "Type", "DataSet")
        self.assert_tag_eq("ch", info, "DataSpaceClass", "SIMPLE")
        self.assert_tag_eq("ch", info, "DataTypeClass", "FLOAT")
        self.assert_tag_eq("ch", info, "DataType", 2)
        self.assert_tag_eq("ch", info, "Rank", 3)
        
        self.assert_tag_count("ch", info, "Size", 3)
        self.assert_tag_eq("ch", info, "Size[0]", 1)
        self.assert_tag_eq("ch", info, "Size[1]", 32)
        self.assert_tag_eq("ch", info, "Size[2]", 32)
    }
    
    void test_cdata(Object self)
    {
        taggroup info = h5_info(_file_path, "/cdata")
        self.assert_valid("cdata", info)

        self.assert_tag_eq("cdata", info, "Name", "/cdata")
        self.assert_tag_eq("cdata", info, "Type", "DataSet")
        self.assert_tag_eq("cdata", info, "DataSpaceClass", "SIMPLE")
        self.assert_tag_eq("cdata", info, "DataTypeClass", "COMPOUND")
        self.assert_tag_eq("cdata", info, "DataType", 3)
        self.assert_tag_eq("cdata", info, "Rank", 2)
        
        self.assert_tag_count("cdata", info, "Size", 2)
        self.assert_tag_eq("cdata", info, "Size[0]", 10)
        self.assert_tag_eq("cdata", info, "Size[1]", 9)
    }
    
    void test_group(Object self)
    {
        taggroup info = h5_info(_file_path, "/group")
        self.assert_valid("group", info)
        
        self.assert_tag_eq("group", info, "Name", "/group")
        self.assert_tag_eq("group", info, "Type", "Group")
        
        taggroup contents
        self.assert_true("group.Contents", TagGroupGetTagAsTagGroup(info, "Contents", contents))
        self.assert_eq("len(group.Contents)", 1, TagGroupCountTags(contents))
        self.assert_true("group.Contents[0]", TagGroupGetIndexedTagAsTagGroup(contents, 0, info))

        self.assert_tag_eq("nested", info, "Name", "/group/nested")
        self.assert_tag_eq("nested", info, "Type", "DataSet")
        self.assert_tag_eq("nested", info, "DataSpaceClass", "SIMPLE")
        self.assert_tag_eq("nested", info, "DataTypeClass", "INTEGER")
        self.assert_tag_eq("nested", info, "DataType", 39)
        self.assert_tag_eq("nested", info, "Rank", 3)
        
        self.assert_tag_count("nested", info, "Size", 3)
        self.assert_tag_eq("nested", info, "Size[0]", 8)
        self.assert_tag_eq("nested", info, "Size[1]", 9)
        self.assert_tag_eq("nested", info, "Size[2]", 10)
    }
    
    void test_soft(Object self)
    {
        taggroup root = h5_info(_file_path, "/")
        self.assert_valid("root", root)
        
        taggroup info
        self.assert_true("soft", TagGroupGetTagAsTagGroup(root, "Contents[6]", info))
        
        self.assert_tag_eq("soft", info, "Name", "/soft")
        self.assert_tag_eq("soft", info, "Type", "SoftLink")
        self.assert_tag_eq("soft", info, "Path", "/group/nested")
    }
    
    void test_scalar(Object self)
    {
        taggroup info = h5_info(_file_path, "/scalar")
        self.assert_valid("scalar", info)

        self.assert_tag_eq("scalar", info, "Name", "/scalar")
        self.assert_tag_eq("scalar", info, "Type", "DataSet")
        self.assert_tag_eq("scalar", info, "DataSpaceClass", "SCALAR")
        self.assert_tag_eq("scalar", info, "DataTypeClass", "INTEGER")
        self.assert_tag_eq("scalar", info, "DataType", 10)
        self.assert_tag_eq("scalar", info, "Rank", 0)
        
        taggroup size
        self.assert_false("cdata.Size", TagGroupGetTagAsTagGroup(info, "Size", size))
    }
    
    void test_noent(Object self)
    {
        taggroup info = h5_info(_file_path, "/noent")
        self.assert_false("info", TagGroupIsValid(info))
    }
        
    void test_existance(Object self)
    {
        self.assert_false("not_a_file", h5_exists_attr("not_a_hdf5_file.txt", "/data", "int"))
        self.assert_false("noent", h5_exists(_file_path, "noent"))
        self.assert_false("object", h5_exists(_file_path, "noent"))

        self.assert_true("data", h5_exists(_file_path, "/data"))
        self.assert_true("group", h5_exists(_file_path, "/group"))
        self.assert_true("soft", h5_exists(_file_path, "/soft"))
        self.assert_true("hard", h5_exists(_file_path, "/hard"))
    }
    
    Test_H5_Info(Object self)
    {
        self.register_test("test_file_exists")
        self.register_test("test_root")
        self.register_test("test_data")
        self.register_test("test_ch")
        self.register_test("test_cdata")
        self.register_test("test_group")
        self.register_test("test_soft")
        self.register_test("test_scalar")
        self.register_test("test_noent")
        self.register_test("test_existance")
    }
}

{
    Object runner = alloc(TestRunner)
    runner.register_test_case(alloc(Test_H5_Info))
    runner.start()
}
