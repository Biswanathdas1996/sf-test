trigger ContactTrigger on Contact (before insert) {
    // Bad practice: All logic in trigger instead of handler class
    // No bulkification - processing one record at a time!

    for(Contact c : Trigger.new) {
        // SOQL in loop - Major anti-pattern!
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name = :c.LastName + ' Household'];

        if(accounts.size() > 0) {
            // Just taking first one, no proper logic
            c.AccountId = accounts[0].Id;
        } else {
            // DML in loop - Another major anti-pattern!
            Account newAcc = new Account();
            newAcc.Name = c.LastName + ' Household';

            // No try-catch, no error handling
            // No CRUD/FLS security checks
            insert newAcc;

            c.AccountId = newAcc.Id;
        }

        // Another SOQL in loop just to demonstrate more bad practices
        List<Account> checkAgain = [SELECT Id FROM Account WHERE Id = :c.AccountId];

        // Useless query above, not even using the results
    }
}