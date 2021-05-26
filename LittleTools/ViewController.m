//
//  ViewController.m
//  LittleTools
//
//  Created by xiejc on 2021/5/26.
//

#import "ViewController.h"
#import <Contacts/Contacts.h>
#import "Tools.h"

@interface ViewController ()


@property (nonatomic, weak) IBOutlet UILabel *infoLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self requestContactAuthorAndData];
}


#pragma mark - 操作

-(IBAction)clearContact:(id)sender {
    self.infoLabel.text = nil;
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"警告" message:@"请确认清除通讯录前进行保存通讯录" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *clearAction = [UIAlertAction actionWithTitle:@"清除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        self.infoLabel.text = @"即将清除所有通讯录...";
        
        NSArray *contacts = [self getContactFromPhone];
        if (contacts == nil || contacts.count == 0) {
            self.infoLabel.text = @"通讯录未找到任何信息!!";
            return;
        }
        for (CNContact *contact in contacts){
            [self deleteContact:contact.mutableCopy];
        }
        
        self.infoLabel.text = @"清除通讯录完成~~~";
    }];
    [alertVC addAction:clearAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertVC addAction:cancelAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (IBAction)saveContact:(id)sender {
    self.infoLabel.text = @"保存进行中...";
    NSDictionary *contactMap = [self getAllContactMap];
    if (contactMap == nil || contactMap.allKeys.count == 0) {
        self.infoLabel.text = @"保存失败!! 没有获取到通讯录信息！！";
        NSLog(@"%@", self.infoLabel.text);
        return;
    }
    
    NSString *jsonStr = [Tools objectToJson:contactMap];
    
    NSLog(@"===保存信息:%@", jsonStr);
    if (jsonStr == nil) {
        self.infoLabel.text = @"保存失败!!json失败!!";
        NSLog(@"%@", self.infoLabel.text);
        return;
    }
    
    NSString *contactPath = [self getContactFilePath];
    NSString *contactCopyPath = [self getCopyContactFilePath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:contactPath]) {
        NSLog(@"存在备份，即将进行重命名...");
        if ([[NSFileManager defaultManager] fileExistsAtPath:contactCopyPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:contactCopyPath error:nil];
        }
        
        NSError *error;
        [[NSFileManager defaultManager] moveItemAtPath:contactPath toPath:contactCopyPath error:&error];
        if (error != nil) {
            self.infoLabel.text = [NSString stringWithFormat:@"复制备份文件失败!!%@", error.localizedDescription];
            return;
        }
        NSLog(@"存在备份，完成重命名~~");
    }
    
    NSLog(@"备份进行中...");
    NSError *error;
    [jsonStr writeToFile:contactPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error != nil) {
        NSLog(@"备份失败，恢复备份....");
        self.infoLabel.text = [NSString stringWithFormat:@"保存失败!!%@", error.localizedDescription];
        //失败，则恢复备份
        [[NSFileManager defaultManager] moveItemAtPath:contactCopyPath toPath:contactPath error:&error];
        if (error != nil) {
            self.infoLabel.text = [NSString stringWithFormat:@"恢复备份文件失败!!%@", error.localizedDescription];
            NSLog(@"%@", self.infoLabel.text);
            return;
        }
        NSLog(@"备份失败，恢复备份完成~~");
        return;
    }
    
    //成功，则删除备份信息
    [[NSFileManager defaultManager] removeItemAtPath:contactCopyPath error:nil];
    self.infoLabel.text = [NSString stringWithFormat:@"保存完成(%lu)~~~", (unsigned long)contactMap.count];
    NSLog(@"备份完成~~~");
}

- (IBAction)resetContact:(id)sender {
    self.infoLabel.text = @"即将恢复通讯录...";
    NSLog(@"%@", self.infoLabel.text);

    NSDictionary *contacts = [self getContactFromFile];
    for (NSString *name in contacts.allKeys) {
        NSDictionary *info = [contacts objectForKey:name];
        self.infoLabel.text = [NSString stringWithFormat:@"恢复通讯录:%@", name];
        CNMutableContact *contact = [self createContactFromMap:info];
        [self addContact:contact];
    }
    
    self.infoLabel.text = [NSString stringWithFormat:@"恢复通讯录完成(%lu)~~", (unsigned long)contacts.count];
    NSLog(@"%@", self.infoLabel.text);
}


- (IBAction)logAction:(id)sender {
    self.infoLabel.text = @"即将从文件加载通讯录信息...";
    
    NSDictionary *contacts = [self getContactFromFile];
    int i=0;
    for (NSDictionary *info in contacts.allValues) {
        NSString *name = [NSString stringWithFormat:@"%@%@", [info objectForKey:CNContactFamilyNameKey], [info objectForKey:CNContactGivenNameKey]];
        NSArray *phones = [info objectForKey:CNContactPhoneNumbersKey];
        NSArray *emails = [info objectForKey:CNContactEmailAddressesKey];
        NSLog(@"===%d==%@:\n%@\n%@", ++i, name, phones, emails);
    }
    
    
    self.infoLabel.text = [NSString stringWithFormat:@"打印通讯录完成(共%lu)～～～", (unsigned long)contacts.allKeys.count];
    NSLog(@"%@", self.infoLabel.text);

}

#pragma mark - 私有方法

//根据map创建联系人
- (CNMutableContact *)createContactFromMap:(NSDictionary *)info {
    NSString *familyName = [info objectForKey:CNContactFamilyNameKey];
    NSString *givenName = [info objectForKey:CNContactGivenNameKey];
    NSArray *phones = [info objectForKey:CNContactPhoneNumbersKey];
    NSArray *emails = [info objectForKey:CNContactEmailAddressesKey];
    
    CNMutableContact *contact = [[CNMutableContact alloc] init];
    contact.givenName = givenName;
    contact.familyName = familyName;
    
    NSMutableArray *phoneList = [NSMutableArray array];
    for (NSString *phone in phones) {
        CNPhoneNumber *mobileNumber = [[CNPhoneNumber alloc] initWithStringValue:phone];
        CNLabeledValue *mobilePhone = [[CNLabeledValue alloc] initWithLabel:CNLabelPhoneNumberMobile value:mobileNumber];
        [phoneList addObject:mobilePhone];
    }
    contact.phoneNumbers = phoneList;
    
    NSMutableArray *emailList = [NSMutableArray array];
    for (NSString *email in emails) {
        CNLabeledValue *emailValue = [[CNLabeledValue alloc] initWithLabel:CNLabelWork value:email];
        [emailList addObject:emailValue];
    }
    contact.emailAddresses = emailList;
    return contact;
}

//添加联系人
- (void)addContact:(CNMutableContact *)contact {
    CNSaveRequest *saveRequest = [[CNSaveRequest alloc] init];
    [saveRequest addContact:contact toContainerWithIdentifier:nil];
    CNContactStore *store = [[CNContactStore alloc] init];
    [store executeSaveRequest:saveRequest error:nil];
}


/**
 删除客服信息
 */
- (void)deleteContact:(CNMutableContact *)contact {
    self.infoLabel.text = [NSString stringWithFormat:@"正在删除%@%@...", contact.familyName, contact.givenName];
    // 创建联系人请求
    CNSaveRequest *saveRequest = [[CNSaveRequest alloc] init];
    [saveRequest deleteContact:contact];
    // 写入操作
    CNContactStore *store = [[CNContactStore alloc] init];
    [store executeSaveRequest:saveRequest error:nil];
}




//保存的文件地址
- (NSString *)getContactFilePath {
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *contactPath = [docPath stringByAppendingPathComponent:@"contact.txt"];
    return contactPath;
}

//保存的备份文件地址
- (NSString *)getCopyContactFilePath {
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *contactPath = [docPath stringByAppendingPathComponent:@"contact_copy.txt"];
    return contactPath;
}

//从保存文件加载通讯录
- (NSDictionary *)getContactFromFile {
    NSString *contactPath = [self getContactFilePath];
    NSError *error;
    NSString *json = [NSString stringWithContentsOfFile:contactPath encoding:NSUTF8StringEncoding error:&error];
    
    if (error != nil) {
        self.infoLabel.text = [NSString stringWithFormat:@"保存失败!!%@", error.localizedDescription];
        return nil;
    }
        
    NSDictionary *contacts = [Tools jsonToObject:json];
    if (contacts.allKeys.count == 0) {
        self.infoLabel.text = [NSString stringWithFormat:@"保存失败!!%@", error.localizedDescription];
        return nil;
    }
    
    return contacts;
}

//从手机加载通讯录
- (NSArray *)getContactFromPhone {
    NSMutableArray *contactList = [NSMutableArray array];
    
    // 获取指定的字段,并不是要获取所有字段，需要指定具体的字段
    NSArray *keysToFetch = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey];
    CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
    CNContactStore *contactStore = [[CNContactStore alloc] init];
    
    [contactStore enumerateContactsWithFetchRequest:fetchRequest error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
        [contactList addObject:contact];
    }];
    return contactList;
}


//请求通讯录权限
- (void)requestContactAuthorAndData {
    self.infoLabel.text = @"正在鉴权...";
    
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (status == CNAuthorizationStatusNotDetermined) {
        CNContactStore *store = [[CNContactStore alloc] init];
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError*  _Nullable error) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (error) {
                    self.infoLabel.text = @"授权失败!!!!";
                } else {
                    self.infoLabel.text = @"授权成功~~~~";
                    [self requestContactAuthorAndData];
                }
            });
        }];
    }
    else if(status == CNAuthorizationStatusRestricted)
    {
        [self showAlertViewAboutNotAuthorAccessContact];
    }
    else if (status == CNAuthorizationStatusDenied)
    {
        self.infoLabel.text = @"用户拒绝!!!";
        [self showAlertViewAboutNotAuthorAccessContact];
        NSLog(@"%@", self.infoLabel.text);
    }
    else if (status == CNAuthorizationStatusAuthorized)//已经授权
    {
        self.infoLabel.text = @"已获取到数据权限～～";
    }
    
}

//有通讯录权限-- 进行下一步操作
- (NSDictionary *)getAllContactMap {
    NSMutableDictionary *contactMap = [NSMutableDictionary dictionary];
    NSArray *contacts = [self getContactFromPhone];
    int i=0;
    for (CNContact *contact in contacts){
        NSLog(@"-------------------------------------------------------");

        NSString *givenName = contact.givenName;
        NSString *familyName = contact.familyName;
        
        //拼接姓名
        NSString *fullName = [NSString stringWithFormat:@"%@%@",contact.familyName,contact.givenName];
        if ([contactMap.allKeys containsObject:fullName]) {
            NSLog(@"====已存在姓名:%@", fullName);
            continue;
        }
        
        NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
        [info setObject:[Tools notNullString:givenName] forKey:CNContactGivenNameKey];
        [info setObject:[Tools notNullString:familyName] forKey:CNContactFamilyNameKey];
        
        
        //获取电话号码
        NSMutableArray *phoneList = [NSMutableArray array];
        [info setObject:phoneList forKey:CNContactPhoneNumbersKey];
        
        //遍历一个人名下的多个电话号码
        NSArray *phoneNumbers = contact.phoneNumbers;
        for (CNLabeledValue *labelValue in phoneNumbers) {
            
            CNPhoneNumber *phoneNumber = labelValue.value;
            NSString *phoneStr = phoneNumber.stringValue;
            
            NSArray *codeList = @[@"+86", @"-", @"(",@")",@" "];
            //去掉电话中的特殊字符
            for (NSString *code in codeList) {
                phoneStr = [phoneStr stringByReplacingOccurrencesOfString:code withString:@""];
            }
            if (![phoneStr isEqualToString:@""]) {
                [phoneList addObject:phoneStr];
            }
        }
        
        if (phoneList.count == 0) {
            //没有电话 则不进行备份，继续下一个
            continue;;
        }
        
        NSMutableArray *emailList = [NSMutableArray array];
        NSArray *emails = contact.emailAddresses;
        for (CNLabeledValue *labelValue in emails) {
            NSString *email = labelValue.value;
            if (email == nil && ![email isEqualToString:@""]) {
                [emailList addObject:email];
            }
        }
        
        NSLog(@"===%d==姓名:%@;phone=%@;email:%@", ++i, fullName, phoneList, emailList);
        [contactMap setObject:info forKey:fullName];
    }
    return contactMap;
}

//提示没有通讯录权限
- (void)showAlertViewAboutNotAuthorAccessContact {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"请授权通讯录权限"
                                          message:@"请在iPhone的\"设置-隐私-通讯录\"选项中,允许花解解访问你的通讯录"
                                          preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:OKAction];
    [self presentViewController:alertController animated:YES completion:nil];
    self.infoLabel.text = @"请在iPhone的\"设置-隐私-通讯录\"选项中,允许花解解访问你的通讯录";
}


@end
