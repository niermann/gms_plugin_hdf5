About
=====

This is a small unit testing "framework" for Gatan's Digital Micrograph.
(DM). As programming for DM is a pain in the back, this hopefully eases
the task a little bit.

Installation
============

Within Digital Micrograph select "File" -> "Install Script File..." and
select the "unittest.s" file. In the following dialog select the "Library"
tab. Whether you install the script for yourself or all users, is at your
own descretion.

Removal
-------

Simply select the script "unittest.s" in the "File" -> "Remove script..."
dialog.

Documentation
=============

The reader is assumed to be familiar with the concept of unit testing,
otherwise:
    http://en.wikipedia.org/wiki/Unit_testing

Tests, Test cases, and running them
-----------------------------------

A test case is creates by deriving a class from TestCase. The
individual tests are methods of this class (no argument beside
self) and must be registered by register_test(). This can be
done conveniently in the CTOR:

    class MyTest: TestCase
    {
        void test_something(Object self)
        {
            ...
        }

        MyTest(Object self)
        {
            self.register_test("test_something")
        }
    }

To run the tests, create an instance of the TestRunner
class, and register the instances of the individual test cases:

    Object runner = alloc(TestRunner)
    runner.register_test_case(alloc(MyTest))

The tests are run by calling the start() method of TestRunner
and the results of the tests are output to the Result window:

    runner.start()
    
The output mimics the output of the Google Test framework.

Assertions
----------

The individual test methods succeed if they return without throwing
an exception. Any exception is considered a failure. The test
runner will print the text of a thrown exception.

Your can throw own errors
    
    Throw("Wrong result.")

or use the fail() method of the TestCase to make the test logic 
clearer:

    self.fail("Wrong result")

you can also use one of the assert_... methods of the TestCase class.
For instance you can test the value of a number:

    Number myVar
    self.assert_eq("myVar", myVar, 2)

The first argument of the assert_... methods always describe the
tested assertion (as there is no stack trace in DM, this is 
description is the only way to pinpoint the failed assertion in the
test output). In the case of assert_eq the next two values are
tested for equality.

For numbers, the following assertions exist:
    assert_eq(String description, Number a, Number b)
    assert_true(String description, Number a)
    assert_false(String description, Number a)

For strings, there are:
    assert_eq(String description, String a, String b)

Finally, the following assertion tests for object validity:
    assert_valid(String description, Object obj)
    assert_valid(String description, Image img)

Fixtures
--------

Is is possible to create test fixtures within the test cases. These
are created by the setup() method and cleaned up by the teardown()
method:
     
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

The setup() method is called before each test function is called, and
the teardown() after the individual test function has run. teardown() is
called, whether the test succeeded or not.
