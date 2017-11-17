//**********************************************************************
//
//  FILENAME
//      unittest.s
//
//  AUTHOR
//      Copyright (c) 2014, Tore Niermann
//      niermann@physik.tu-berlin.de
//
//  HISTORY
//      28.06.2014 written 
//      08.07.2016 more assertions
//
//  DESCRIPTION
//      A small unit test "framework" which allows to create 
//      test cases and has a test runner that will run all
//      registered tests. 
//
//**********************************************************************

/*
 * Class that enwraps a single test case
 */
class TestCase : Object
{
    TagGroup _test_list;
    
    TestCase(Object self)
    {
        _test_list = NewTagList();
    }
    
    // Initialize fixtures before test
    void setup(Object self)
    {
    }
    
    // Cleanup fixtures after test
    void teardown(Object self)
    {
    }

    // Return number of tests in test case
    Number test_count(Object self)
    {
        return TagGroupCountTags(_test_list);
    }
    
    // Add test to test case
    // Tests must be methods of a TestCase derived
    // class and have a signature method(Object testCase)
    void register_test(Object self, String method_name)
    {
        TagGroupInsertTagAsString(_test_list, -1, method_name)
    }
        
    // Return name of the test index
    String get_test_name(Object self, Number index)
    {
        String name
        TagGroupGetIndexedTagAsString(_test_list, index, name)
        return name
    }
        
    // Fail test
    void fail(Object self, string info)
    {
        Throw("Failure: " + info)
    }
        
    // Assert value is true, fail if not
    void assert_true(Object self, string info, Number value)
    {
        if (!value)
            Throw("Failure : " + info + "\n" \
                  + "Expected: true\n")
    }       

    // Assert value is false, fail if not
    void assert_false(Object self, string info, Number value)
    {
        if (value)
            Throw("Failure : " + info + "\n" \
                  + "Expected: false")
    }       

    // Assert values are equal
    void assert_eq(Object self, String info, Number a, Number b)
    {
        if (a != b)
            Throw("Failure : " + info + "\n" \
                  + "Expected: (" + a + ") == (" + b + ")")
    }       

    // Assert values are equal
    void assert_eq(Object self, String info, ComplexNumber a, ComplexNumber b)
    {
        if (a != b)
            Throw("Failure : " + info + "\n" \
                  + "Expected: (" + a + ") == (" + b + ")")
    }       

    // Assert values are equal
    void assert_eq(Object self, String info, String a, String b)
    {
        if (a != b)
            Throw("Failure : " + info + "\n" \
                  + "Expected: (" + a + ") == (" + b + ")")
    }       
    
    // Assert values are not equal
    void assert_ne(Object self, String info, Number a, Number b)
    {
        if (a == b)
            Throw("Failure : " + info + "\n" \
                  + "Expected: (" + a + ") != (" + b + ")")
    }       

    // Assert values are not equal
    void assert_ne(Object self, String info, ComplexNumber a, ComplexNumber b)
    {
        if (a == b)
            Throw("Failure : " + info + "\n" \
                  + "Expected: (" + a + ") != (" + b + ")")
    }       

    // Assert values are not equal
    void assert_ne(Object self, String info, String a, String b)
    {
        if (a == b)
            Throw("Failure : " + info + "\n" \
                  + "Expected: (" + a + ") != (" + b + ")")
    }       
    
    // Assert relationship
    void assert_lt(Object self, String info, Number a, Number b)
    {
        if (a >= b)
            Throw("Failure : " + info + "\n" \
                  + "Expected: (" + a + ") < (" + b + ")")
    }       
    
    // Assert relationship
    void assert_le(Object self, String info, Number a, Number b)
    {
        if (a > b)
            Throw("Failure : " + info + "\n" \
                  + "Expected: (" + a + ") <= (" + b + ")")
    }       
    
    // Assert relationship
    void assert_ge(Object self, String info, Number a, Number b)
    {
        if (a < b)
            Throw("Failure : " + info + "\n" \
                  + "Expected: (" + a + ") >= (" + b + ")")
    }       
    
    // Assert relationship
    void assert_gt(Object self, String info, Number a, Number b)
    {
        if (a <= b)
            Throw("Failure : " + info + "\n" \
                  + "Expected: (" + a + ") > (" + b + ")")
    }       
    
    // Assert values are almost equal (within atol)
    void assert_almost(Object self, String info, RealNumber a, RealNumber b, RealNumber atol)
    {
        if (abs(a - b) > abs(atol))
            Throw("Failure : " + info + "\n" \
                  + "Expected: (" + a + ") almost (" + b + ") within " + abs(atol))
    }       
    void assert_almost(Object self, String info, RealNumber a, RealNumber b)
    {
        self.assert_almost(info, a, b, 1e-7)
    }

    // Assert values are almost equal (within atol)
    void assert_almost(Object self, String info, ComplexNumber a, ComplexNumber b, RealNumber atol)
    {
        if (abs(a - b) > abs(atol))
            Throw("Failure : " + info + "\n" \
                  + "Expected: (" + a + ") almost (" + b + ") within " + abs(atol))
    }       
    void assert_almost(Object self, String info, ComplexNumber a, ComplexNumber b)
    {
        self.assert_almost(info, a, b, 1e-7)
    }
    
    // Assert object is valid
    void assert_valid(Object self, String info, Object &obj)
    {
        if (!ScriptObjectIsValid(obj))
            Throw("Failure : " + info + "\n" \
                  + "Expected valid object.")
    }

    // Assert image is valid
    void assert_valid(Object self, String info, Image &img)
    {
        if (!ImageIsValid(img))
            Throw("Failure : " + info + "\n" \
                  + "Expected valid image.")
    }

    // Assert object is not valid
    void assert_not_valid(Object self, String info, Object &obj)
    {
        if (ScriptObjectIsValid(obj))
            Throw("Failure : " + info + "\n" \
                  + "Expected invalid object.")
    }

    // Assert image is not valid
    void assert_not_valid(Object self, String info, Image &img)
    {
        if (ImageIsValid(img))
            Throw("Failure : " + info + "\n" \
                  + "Expected invalid image.")
    }

    // Assert taggroup is valid
    void assert_valid(Object self, String info, TagGroup &tags)
    {
        if (!TagGroupIsValid(tags))
            Throw("Failure : " + info + "\n" \
                  + "Expected valid taggroup.")
    }
    
    // Assert a named tag is given number
    void assert_tag_eq(Object self, String info, TagGroup tags, String key, Number expected)
    {
        if (!TagGroupIsValid(tags))
            Throw("Failure : " + info + ", key=\"" + key + "\"\n" \
                  + "Expected valid taggroup.")
        
        Number actual
        if (!TagGroupGetTagAsNumber(tags, key, actual))
            Throw("Failure : " + info + ", key=\"" + key + "\"\n" \
                  + "No such number tag: " + key)
                  
        if (actual != expected)
            Throw("Failure : " + info + ", key=\"" + key + "\"\n" \
                  + "Expected: " + expected + "\n" \
                  + "Actual  : " + actual)
    }
    
    // Assert a named tag is given complex number
    void assert_tag_eq(Object self, String info, TagGroup tags, String key, ComplexNumber expected)
    {
        if (!TagGroupIsValid(tags))
            Throw("Failure : " + info + ", key=\"" + key + "\"\n" \
                  + "Expected valid taggroup.")
        
        ComplexNumber actual
        if (!TagGroupGetTagAsNumber(tags, key, actual))
            Throw("Failure : " + info + ", key=\"" + key + "\"\n" \
                  + "No such complex number tag.")
                  
        if (actual != expected)
            Throw("Failure : " + info + ", key=\"" + key + "\"\n" \
                  + "Expected: " + expected + "\n" \
                  + "Actual  : " + actual)
    }
    
    // Assert a named tag is given string
    void assert_tag_eq(Object self, String info, TagGroup tags, String key, String expected)
    {
        if (!TagGroupIsValid(tags))
            Throw("Failure : " + info + ", key=\"" + key + "\"\n" \
                  + "Expected valid taggroup.")
        
        String actual
        if (!TagGroupGetTagAsString(tags, key, actual))
            Throw("Failure : " + info + ", key=\"" + key + "\"\n" \
                  + "No such string tag.")
                  
        if (actual != expected)
            Throw("Failure : " + info + ", key=\"" + key + "\"\n" \
                  + "Expected: " + expected + "\n" \
                  + "Actual  : " + actual)
    }

    // Assert an indexed tag is given number
    void assert_tag_eq(Object self, String info, TagGroup tags, Number index, Number expected)
    {
        if (!TagGroupIsValid(tags))
            Throw("Failure : " + info + ", index=" + index + "\n" \
                  + "Expected valid taggroup.")
        
        Number actual
        if (!TagGroupGetIndexedTagAsNumber(tags, index, actual))
            Throw("Failure : " + info + ", index=" + index + "\n" \
                  + "No such number tag.")
                  
        if (actual != expected)
            Throw("Failure : " + info + ", key=" + index + "\n" \
                  + "Expected: " + expected + "\n" \
                  + "Actual  : " + actual)
    }
    
    // Assert an indexed tag is given complex number
    void assert_tag_eq(Object self, String info, TagGroup tags, Number index, ComplexNumber expected)
    {
        if (!TagGroupIsValid(tags))
            Throw("Failure : " + info + ", index=" + index + "\n" \
                  + "Expected valid taggroup.")
        
        ComplexNumber actual
        if (!TagGroupGetIndexedTagAsNumber(tags, index, actual))
            Throw("Failure : " + info + ", index=" + index + "\n" \
                  + "No such complex number tag.")
                  
        if (actual != expected)
            Throw("Failure : " + info + ", index=" + index + "\n" \
                  + "Expected: " + expected + "\n" \
                  + "Actual  : " + actual)
    }
    
    // Assert an indexed tag is given string
    void assert_tag_eq(Object self, String info, TagGroup tags, Number index, String expected)
    {
        if (!TagGroupIsValid(tags))
            Throw("Failure : " + info + ", index=" + index + "\n" \
                  + "Expected valid taggroup.")
        
        String actual
        if (!TagGroupGetIndexedTagAsString(tags, index, actual))
            Throw("Failure : " + info + ", index=" + index + "\n" \
                  + "No such string tag.")
                  
        if (actual != expected)
            Throw("Failure : " + info + ", index=" + index + "\n" \
                  + "Expected: " + expected + "\n" \
                  + "Actual  : " + actual)
    }

    // Assert a named tag is tag group/list with given size
    void assert_tag_count(Object self, String info, TagGroup tags, String key, Number expected)
    {
        if (!TagGroupIsValid(tags))
            Throw("Failure : " + info + ", key=\"" + key + "\"\n" \
                  + "Expected valid taggroup.")
        
        TagGroup sub
        if (!TagGroupGetTagAsTagGroup(tags, key, sub))
            Throw("Failure : " + info + ", key=\"" + key + "\"\n" \
                  + "No such tag group.")
                  
        Number actual = TagGroupCountTags(sub)
        if (actual != expected)
            Throw("Failure : " + info + ", key=\"" + key + "\"\n" \
                  + "Expected count: " + expected + "\n" \
                  + "Actual count  : " + actual)
    }

    // Assert an indexed tag is tag group/list with given size
    void assert_tag_count(Object self, String info, TagGroup tags, Number index, Number expected)
    {
        if (!TagGroupIsValid(tags))
            Throw("Failure : " + info + ", index=" + index + "\n" \
                  + "Expected valid taggroup.")
        
        TagGroup sub
        if (!TagGroupGetIndexedTagAsTagGroup(tags, index, sub))
            Throw("Failure : " + info + ", index=" + index + "\n" \
                  + "No such tag group.")
                  
        Number actual = TagGroupCountTags(sub)
        if (actual != expected)
            Throw("Failure : " + info + ", index=" + index + "\n" \
                  + "Expected count: " + expected + "\n" \
                  + "Actual count  : " + actual)
    }
}

/*
 * The TestRunner object runs all tests
 */
class TestRunner : Object
{
    Object   _test_case_list
    Object   _current_test_case
    String   _current_test_name
    TagGroup _failed_tests
    TagGroup _passed_tests
    
    TestRunner(Object self)
    {          
        _test_case_list = alloc(ObjectList)
        _current_test_case = NULL
        _current_test_name = ""
    } 

    // Register a TestCase object with the runner
    void register_test_case(Object self, Object test_case)
    {
        _test_case_list.AddObjectToList(test_case)
    }
        
    // Method is used to put out text
    void output(Object self, String text)
    {
        Result(text)
    }
    
    // Return number of test cases
    Number test_case_count(Object self)
    {
        return _test_case_list.SizeOfList();
    }
    
    // Return overall number of tests
    Number total_test_count(Object self)
    {
        Number i, n = self.test_case_count()
        Number total = 0
        for (i = 0; i < n; i++) {
            Object test_case = _test_case_list.ObjectAt(i)
            total = total + test_case.test_count()
        }
        return total
    }
    
    // Return current test case (only valid during test runs)
    Object current_test_case(Object self)
    {
        return _current_test_case
    }
    
    // Return name of current test (only valid during test runs)
    String current_test_name(Object self)
    {
        return ClassName(_current_test_case) + "." + _current_test_name
    }
    
    void _run_current_test(Object self)
    {
        String name = self.current_test_name()
        self.output("[ RUN      ] " + name + "\n")

        Number failure = 0
        String header = "GetScriptObjectFromID(" + ScriptObjectGetID(_current_test_case) + ")."
        
        // Setup and run
        try {
            ExecuteScriptString(header + "setup()")
            ExecuteScriptString(header + _current_test_name + "()")
        } catch {
            failure = 1
            String result = GetExceptionString()
            self.output(result + "\n")
            break
        }
        
        // Tear down
        try
            ExecuteScriptString(header + "teardown()")
        catch
            break

        // Report
        if (!failure) {
            self.output("[       OK ] " + name + "\n")
            TagGroupInsertTagAsString(_passed_tests, -1, name)
        } else {
            self.output("[  FAILED  ] " + name + "\n")
            TagGroupInsertTagAsString(_failed_tests, -1, name)
        }
    }

    void _run_test_case(Object self, Object test_case)
    {       
        _current_test_case = test_case
        
        Number testI, testN = _current_test_case.test_count()
        self.output("[----------] " + testN + " test(s) from " \
                    + ClassName(_current_test_case) + "\n")
                    
        for (testI = 0; testI < testN; testI++) {
            _current_test_name = _current_test_case.get_test_name(testI)
            self._run_current_test()
        }
        _current_test_name = ""
                    
        self.output("[----------] " + testN + " test(s) from " \
                    + ClassName(_current_test_case) + "\n\n")
    }       
        
    void start(Object self)
    {
        _failed_tests = NewTagList()
        _passed_tests = NewTagList()
        
        self.output("[==========] Running " + self.total_test_count() \
                    + " test(s) from " + self.test_case_count() \
                    + " test case(s).\n")
                      
        Number caseI, caseN = self.test_case_count()
        for (caseI = 0; caseI < caseN; caseI++)
            self._run_test_case(_test_case_list.ObjectAt(caseI))
        _current_test_case = NULL
        
        self.output("[==========] " + self.total_test_count() \
                    + " test(s) from " + self.test_case_count() \
                    + " test case(s) ran.\n")

        // Summary
        if (TagGroupCountTags(_passed_tests) > 0) {
            self.output("[  PASSED  ] " + TagGroupCountTags(_passed_tests) \
                        + " test(s).\n")
        }
        if (TagGroupCountTags(_failed_tests) > 0) {
            Number failI, failN = TagGroupCountTags(_failed_tests)
            self.output("[  FAILED  ] " + failN \
                        + " test(s), listed below:\n")
            for (failI = 0; failI < failN; failI++) {
                String name
                if (TagGroupGetIndexedTagAsString(_failed_tests, failI, name))
                    self.output("[  FAILED  ] " + name + "\n")
            }
        }
    }
}
