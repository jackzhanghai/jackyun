/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 3.0 Edition
 BSD License, Use at your own risk
 */

#import "ABContactsHelper.h"

@implementation ABContactsHelper
/*
 Note: You cannot CFRelease the addressbook after ABAddressBookCreate();
 */
+ (ABAddressBookRef) addressBook
{
	return IS_IOS6 ? ABAddressBookCreateWithOptions(NULL, nil) : ABAddressBookCreate();
}

+ (NSArray *) contacts:(ABAddressBookRef)addressBook
{
    //	ABAddressBookRef addressBook = ABAddressBookCreate();
	NSArray *thePeople = (NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:thePeople.count];
	for (id person in thePeople)
		[array addObject:[ABContact contactWithRecord:(ABRecordRef)person]];
	[thePeople release];
    
	return array;
}

//Add by kuit
+ (BOOL) removeAll:(NSError **) error
{
	ABAddressBookRef addressBook = ABAddressBookCreate();
    NSArray *thePeople = (NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
    //	NSMutableArray *array = [NSMutableArray arrayWithCapacity:thePeople.count];
	for (id person in thePeople) {
        if (!ABAddressBookRemoveRecord(addressBook, (ABRecordRef)person, (CFErrorRef *) error)) {
            CFRelease(addressBook);
            return NO;
        }
    }
    
	[thePeople release];
    BOOL ret = ABAddressBookSave(addressBook,  (CFErrorRef *) error);
    CFRelease(addressBook);
    
    return ret;
}

+ (int) contactsCount
{
	ABAddressBookRef addressBook = ABAddressBookCreate();
    int ret = ABAddressBookGetPersonCount(addressBook);
    CFRelease(addressBook);
    
	return ret;
}

+ (int) contactsWithImageCount
{
	ABAddressBookRef addressBook = ABAddressBookCreate();
	NSArray *peopleArray = (NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
	int ncount = 0;
	for (id person in peopleArray) if (ABPersonHasImageData(person)) ncount++;
	[peopleArray release];
	return ncount;
}

+ (int) contactsWithoutImageCount
{
	ABAddressBookRef addressBook = ABAddressBookCreate();
	NSArray *peopleArray = (NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
	int ncount = 0;
	for (id person in peopleArray) if (!ABPersonHasImageData(person)) ncount++;
	[peopleArray release];
	return ncount;
}

// Groups
+ (int) numberOfGroups
{
	ABAddressBookRef addressBook = ABAddressBookCreate();
	NSArray *groups = (NSArray *)ABAddressBookCopyArrayOfAllGroups(addressBook);
	int ncount = groups.count;
	[groups release];
	return ncount;
}

+ (NSArray *) groups
{
	ABAddressBookRef addressBook = ABAddressBookCreate();
	NSArray *groups = (NSArray *)ABAddressBookCopyArrayOfAllGroups(addressBook);
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:groups.count];
	for (id group in groups)
		[array addObject:[ABGroup groupWithRecord:(ABRecordRef)group]];
	[groups release];
	return array;
}

// Sorting
+ (BOOL) firstNameSorting
{
	return (ABPersonGetCompositeNameFormat() == kABPersonCompositeNameFormatFirstNameFirst);
}

#pragma mark Contact Management

// Thanks to Eridius for suggestions re: error
+ (BOOL) addContact: (ABContact *) aContact withError: (NSError **) error
{
	ABAddressBookRef addressBook = ABAddressBookCreate();
	if (!ABAddressBookAddRecord(addressBook, aContact.record, (CFErrorRef *) error)) {
        CFRelease(addressBook);
        return NO;
    }
    BOOL ret = ABAddressBookSave(addressBook, (CFErrorRef *) error);
    CFRelease(addressBook);
	return ret;
}

+ (BOOL) addGroup: (ABGroup *) aGroup withError: (NSError **) error
{
	ABAddressBookRef addressBook = ABAddressBookCreate();
	if (!ABAddressBookAddRecord(addressBook, aGroup.record, (CFErrorRef *) error)) return NO;
	return ABAddressBookSave(addressBook, (CFErrorRef *) error);
}

+ (NSArray *) contactsMatchingName: (NSString *) fname
{
	NSPredicate *pred;
    ABAddressBookRef addressBook = ABAddressBookCreate();
	NSArray *contacts = [ABContactsHelper contacts:addressBook];
	pred = [NSPredicate predicateWithFormat:@"firstname contains[cd] %@ OR lastname contains[cd] %@ OR nickname contains[cd] %@ OR middlename contains[cd] %@", fname, fname, fname, fname];
	return [contacts filteredArrayUsingPredicate:pred];
}

+ (NSArray *) contactsMatchingName: (NSString *) fname andName: (NSString *) lname
{
	NSPredicate *pred;
    ABAddressBookRef addressBook = ABAddressBookCreate();
	NSArray *contacts = [ABContactsHelper contacts:addressBook];
	pred = [NSPredicate predicateWithFormat:@"firstname contains[cd] %@ OR lastname contains[cd] %@ OR nickname contains[cd] %@ OR middlename contains[cd] %@", fname, fname, fname, fname];
	contacts = [contacts filteredArrayUsingPredicate:pred];
	pred = [NSPredicate predicateWithFormat:@"firstname contains[cd] %@ OR lastname contains[cd] %@ OR nickname contains[cd] %@ OR middlename contains[cd] %@", lname, lname, lname, lname];
	contacts = [contacts filteredArrayUsingPredicate:pred];
	return contacts;
}

+ (NSArray *) contactsMatchingPhone: (NSString *) number
{
	NSPredicate *pred;
    ABAddressBookRef addressBook = ABAddressBookCreate();
	NSArray *contacts = [ABContactsHelper contacts:addressBook];
	pred = [NSPredicate predicateWithFormat:@"phonenumbers contains[cd] %@", number];
	return [contacts filteredArrayUsingPredicate:pred];
}

+ (NSArray *) groupsMatchingName: (NSString *) fname
{
	NSPredicate *pred;
	NSArray *groups = [ABContactsHelper groups];
	pred = [NSPredicate predicateWithFormat:@"name contains[cd] %@ ", fname];
	return [groups filteredArrayUsingPredicate:pred];
}


+ (ABRecordID)groupIDHasContact:(ABContact *)contact
{
    NSArray *groups = [ABContactsHelper groups];
    for (ABGroup *group in groups) {
        if ([group.members containsObject:contact]) {
                        
            return group.recordID;
        }
    }
    
    return -1;
}

+ (BOOL)addContact: (ABContact *) aContact withError: (NSError **) error addressbook:(ABAddressBookRef)addressBook
{
	if (!ABAddressBookAddRecord(addressBook, aContact.record, (CFErrorRef *) error)) {
        return NO;
    }
    BOOL ret = ABAddressBookSave(addressBook, (CFErrorRef *) error);
	return ret;
}

@end