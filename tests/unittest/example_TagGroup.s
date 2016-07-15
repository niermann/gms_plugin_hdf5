// NOTE
//  You must have unittest.s installed as a script library within DM
//  to run this example
     
class TestTagGroup: TestCase
{
    TagGroup _tags
    
    void setup(Object self)
    {
        _tags = NewTagList()
    }
    
    void teardown(Object self)
    {
        _tags = NULL
    }
    
    void test_new_list_is_empty(Object self)
    {
        self.assert_eq("CountTags", 0, TagGroupCountTags(_tags))
    }

    void test_can_add_tags(Object self)
    {
        TagGroupInsertTagAsString(_tags, -1, "One")
        self.assert_eq("CountTags", 1, TagGroupCountTags(_tags))
        TagGroupInsertTagAsString(_tags, -1, "Two")
        self.assert_eq("CountTags", 2, TagGroupCountTags(_tags))
    }

    void test_can_retrieve_tags(Object self)
    {
        TagGroupInsertTagAsString(_tags, -1, "One")
        TagGroupInsertTagAsString(_tags, -1, "Two")
        String x
        self.assert_true("GetAsString", TagGroupGetIndexedTagAsString(_tags, 0, x))
        self.assert_eq("Tag[0]", x, "One")
        self.assert_true("GetAsString", TagGroupGetIndexedTagAsString(_tags, 1, x))
        self.assert_eq("Tag[1]", x, "Two")
    }
    
    void test_named_tag_values(Object self)
    {
        TagGroup group = NewTagGroup()
        TagGroupSetTagAsString(group, "aaa", "One")
        TagGroupSetTagAsNumber(group, "bbb", 2)
        TagGroupSetTagAsNumber(group, "ccc", complex(2, -3))

        self.assert_tag_eq("group", group, "aaa", "One")
        self.assert_tag_eq("group", group, "bbb", 2)
        self.assert_tag_eq("group", group, "ccc", complex(2, -3))
    }
    
    void test_indexed_tag_values(Object self)
    {
        TagGroupInsertTagAsString(_tags, -1, "One")
        TagGroupInsertTagAsNumber(_tags, -1, 2)
        TagGroupInsertTagAsNumber(_tags, -1, complex(2, -3))

        self.assert_tag_eq("tags", _tags, 0, "One")
        self.assert_tag_eq("tags", _tags, 1, 2)
        self.assert_tag_eq("tags", _tags, 2, complex(2, -3))
    }

    void test_can_remove_tags(Object self)
    {
        TagGroupInsertTagAsString(_tags, -1, "One")
        TagGroupInsertTagAsString(_tags, -1, "Two")
        self.assert_eq("CountTags", 2, TagGroupCountTags(_tags))
        TagGroupDeleteTagWithIndex(_tags, 0)
        self.assert_eq("CountTags", 1, TagGroupCountTags(_tags))
    }
    
    TestTagGroup(Object self)
    {
        self.register_test("test_new_list_is_empty")
        self.register_test("test_can_add_tags")
        self.register_test("test_can_retrieve_tags")
        self.register_test("test_named_tag_values")
        self.register_test("test_indexed_tag_values")
        self.register_test("test_can_remove_tags")
    }
}

{
    Object runner = alloc(TestRunner)
    runner.register_test_case(alloc(TestTagGroup))
    runner.start()
}
