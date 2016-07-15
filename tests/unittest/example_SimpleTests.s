// NOTE
//  You must have unittest.s installed as a script library within DM
//  to run this example
     
class SimpleTest1: TestCase
{
    void test_succeeding(Object self)
    {
    }

    void test_fail_due_to_inequality(Object self)
    {
        self.assert_eq("test", 4, 5)
    }
    
    void test_complex_numbers(Object self)
    {
        ComplexNumber a = complex(1, 2);
        ComplexNumber b = 1;
        
        self.assert_ne("test", a, b);
        self.assert_almost("test", a, complex(1, 2.00000002));
    }
    
    void test_float_numbers(Object self)
    {
        self.assert_almost("pi", pi(), 3.141, 1e-2)
        self.assert_almost("pi", pi(), 3.141592653589793)
    }
    
    SimpleTest1(Object self)
    {
        self.register_test("test_succeeding")
        self.register_test("test_complex_numbers")
        self.register_test("test_float_numbers")
        self.register_test("test_fail_due_to_inequality")
    }
}

class SimpleTest2: TestCase
{
    void test_true_success(Object self)
    {
        self.assert_true("true", 1)
    }

    void test_success_due_to_equality(Object self)
    {
        self.assert_eq("test", "One", "One")
    }

    void test_fail_due_to_exception(Object self)
    {
        Throw("I want to fail.")
    }
    
    SimpleTest2(Object self)
    {
        self.register_test("test_true_success")
        self.register_test("test_success_due_to_equality")
        self.register_test("test_fail_due_to_exception")
    }
}

{
    Object runner = alloc(TestRunner)
    runner.register_test_case(alloc(SimpleTest1))
    runner.register_test_case(alloc(SimpleTest2))
    runner.start()
}
