@IsTest
private class HelloWorldTest {
    @IsTest
    static void shouldReturnMessage() {
        Test.startTest();
        String message = HelloWorld.getMessage();
        Test.stopTest();

        System.assertEquals('Hello Salesforce', message);
    }
}
