/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 3.0 Edition
 BSD License, Use at your own risk
 */

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "ABContact.h"
#import "ABGroup.h"

@interface ABContactsHelper : NSObject

// Address Book
+ (ABAddressBookRef) addressBook;

// Address Book Contacts and Groups
+ (NSArray *) contacts:(ABAddressBookRef)addressBook; // people
+ (NSArray *) groups; // groups

//Add by kuit
+ (BOOL) removeAll:(NSError **) error;

// Counting
+ (int) contactsCount;
+ (int) contactsWithImageCount;
+ (int) contactsWithoutImageCount;
+ (int) numberOfGroups;

// Sorting
+ (BOOL) firstNameSorting;

// Add contacts and groups
+ (BOOL) addContact: (ABContact *) aContact withError: (NSError **) error;
+ (BOOL) addGroup: (ABGroup *) aGroup withError: (NSError **) error;

// Find contacts
+ (NSArray *) contactsMatchingName: (NSString *) fname;
+ (NSArray *) contactsMatchingName: (NSString *) fname andName: (NSString *) lname;
+ (NSArray *) contactsMatchingPhone: (NSString *) number;

// Find groups
+ (NSArray *) groupsMatchingName: (NSString *) fname;

//获取联系人所在分组ID，若该联系人没有在任何一个分组中，返回-1
+ (ABRecordID)groupIDHasContact:(ABContact *)contact;

+ (BOOL)addContact: (ABContact *) aContact withError: (NSError **) error addressbook:(ABAddressBookRef)addressBook;

@end

// For the simple PCUtility of it. Feel free to comment out if desired
@interface NSString (cstring)
@property (readonly) char *UTF8String;
@end