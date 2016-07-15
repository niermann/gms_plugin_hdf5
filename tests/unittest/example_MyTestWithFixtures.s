// NOTE
//  You must have unittest.s installed as a script library within DM
//  to run this example
     
class MyTestWithFixture: TestCase
{
    Number myVar
    
    void setup(Object self)
    {
        myVar = 42
    }
    
    void teardown(Object self)
    {
        myVar = 0
    }

    void test_is_fourty_two(Object self)
    {
        self.assert_eq("myVar", myVar, 42) 
    }

    void test_is_not_eleven(Object self)
    {
        self.assert_true("myVar", myVar != 11) 
    }

    MyTestWithFixture(Object self)
    {
        self.register_test("test_is_fourty_two")
        self.register_test("test_is_not_eleven")
    }
}

{
    Object runner = alloc(TestRunner)
    runner.register_test_case(alloc(MyTestWithFixture))
    runner.start()
}
