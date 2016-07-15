class TestH5Plugin: TestCase
{
	void test_has_version(Object self)
	{
		string version = h5_version()
		self.assert_true("version", version != "")
	}
	
	TestH5Plugin(Object self)
	{
		self.register_test("test_has_version")
	}
}

{
	Object runner = alloc(TestRunner)
	runner.register_test_case(alloc(TestH5Plugin))
	runner.start()
}