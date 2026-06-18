trigger AccountBeforeInsertIndustryRequired on Account (before insert) {
    for (Account acc : Trigger.new) {
        if (acc.Industry == null || acc.Industry.trim() == '') {
            acc.Industry.addError('Industry is required.');
        }
    }
}