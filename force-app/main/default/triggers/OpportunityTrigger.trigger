trigger OpportunityTrigger on Opportunity (before insert, before update) {
    OpportunityRecordTypeService.applyByService(Trigger.new, Trigger.oldMap);
}
