//
//  EventManager.m
//  room
//
//  Created by lcm_ios on 16/6/24.
//  Copyright © 2016年 lcm_ios. All rights reserved.
//

#import "EventManager.h"
#import "ASIHTTPRequest.h"

@implementation EventManager

NSInteger STATUS_INIT = 0;
NSInteger STATUS_FIND_FOLDER = 1;
NSInteger STATUS_FIND_ITEM = 2;
NSInteger status;
NSString *const EWS_ADDRESS = @"https://mail.citrix.com/EWS/Exchange.asmx";

- (NSArray *)fetchEvents
{
    NSArray *resultEvents = nil;
    status = STATUS_INIT;
    self.resultArray = [[NSMutableArray alloc]init];
    [self getFolder];

    return resultEvents;
}

- (void)requestFinished:(ASIHTTPRequest *)request {
    NSLog(@"Finished : %@",[request responseString]);
    self.resultText = [request responseString];
    status++;
    if (status == STATUS_FIND_FOLDER) {
        [self findItem];
    } else if (status == STATUS_FIND_ITEM) {
        [self parseCalendar];
        NSDictionary *userInfo = self.resultArray ? @{DataAvailableContext : self.resultArray} : nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:DataAvailableNotification
                                                            object:self userInfo:userInfo];
    }
}

- (void)parseCalendar {
    NSString *responseString = self.resultText;
     while ([responseString rangeOfString:@"<t:CalendarItem>"].location != NSNotFound)
    {
        NSRange rangeSubjectStart = [responseString rangeOfString:@"<t:Subject>"];
        NSRange rangeSubjectEnd = [responseString rangeOfString:@"</t:Subject>"];
        NSRange rangeStartStart = [responseString rangeOfString:@"<t:Start>"];
        NSRange rangeStartEnd = [responseString rangeOfString:@"</t:Start>"];
        NSRange rangeEndStart = [responseString rangeOfString:@"<t:End>"];
        NSRange rangeEndEnd = [responseString rangeOfString:@"</t:End>"];
        
        NSRange rangeSubject = NSMakeRange(rangeSubjectStart.location + rangeSubjectStart.length, rangeSubjectEnd.location  - rangeSubjectStart.location - rangeSubjectStart.length);
        NSString *subject = [responseString substringWithRange:rangeSubject];
        
        NSRange rangeStart = NSMakeRange(rangeStartStart.location + rangeStartStart.length, rangeStartEnd.location  - rangeStartStart.location - rangeStartStart.length);
        NSString *startTime = [responseString substringWithRange:rangeStart];
        
        NSRange rangeEnd = NSMakeRange(rangeEndStart.location + rangeEndStart.length, rangeEndEnd.location  - rangeEndStart.location - rangeEndStart.length);
        NSString *endTime = [responseString substringWithRange:rangeEnd];
        
        NSRange calendarItemEnd = [responseString rangeOfString:@"</t:CalendarItem>"];
        NSString *subString = [responseString substringFromIndex:(calendarItemEnd.length + calendarItemEnd.location)];
        responseString = subString;
        NSString *result = [[[[startTime stringByAppendingString:@"-"] stringByAppendingString:endTime] stringByAppendingString:@":"] stringByAppendingString:subject];
        //NSLog(@"zzzz%u",[responseString rangeOfString:@"<t:CalendarItem>"].location);
        [self.resultArray addObject:subject];
    }
}


- (void)requestFailed:(ASIHTTPRequest *)request {
    NSError *error = [request error];
    NSLog(@"Failed %@ with code %ld and with userInfo %@", [error domain], (long)[error code], [error userInfo]);
}

// build SOAP request and send asynchronous
- (void)doSOAPRequest: (NSString *)soapMessage {
    NSURL *url = [NSURL URLWithString: EWS_ADDRESS];
    ASIHTTPRequest *theRequest =  [ASIHTTPRequest requestWithURL:url];
    
    [theRequest addRequestHeader:@"Content-Type" value:@"text/xml; charset=utf-8"];
    
    NSString *msgLength = [NSString stringWithFormat:@"%lu", (unsigned long)[soapMessage length]];
    [theRequest addRequestHeader:@"Content-Length" value:msgLength];
    [theRequest setRequestMethod:@"POST"];
    [theRequest appendPostData: [soapMessage dataUsingEncoding: NSUTF8StringEncoding]];
    [theRequest setDefaultResponseEncoding: NSUTF8StringEncoding];
    
    [theRequest setAuthenticationScheme: (NSString *) kCFHTTPAuthenticationSchemeBasic];
    [theRequest setUsername: @"zhenz"];
    [theRequest setPassword: @"Citrix@123"];
    [theRequest setShouldPresentCredentialsBeforeChallenge: YES];

    
    [theRequest setDelegate: self];
    
    [theRequest startAsynchronous];
}

- (void)showNumberOfMessageInInbox {
    NSString *soapMessage = [NSString stringWithFormat:
                             @"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                             "<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"\n"
                             "   xmlns:t=\"http://schemas.microsoft.com/exchange/services/2006/types\">\n"
                             "<soap:Header>\n"
                             "    <t:RequestServerVersion Version=\"Exchange2007_SP1\" />\n"
                             "  </soap:Header>\n"
                             "  <soap:Body>\n"
                             "    <GetFolder xmlns=\"http://schemas.microsoft.com/exchange/services/2006/messages\"\n"
                             "               xmlns:t=\"http://schemas.microsoft.com/exchange/services/2006/types\">\n"
                             "      <FolderShape>\n"
                             "        <t:BaseShape>Default</t:BaseShape>\n"
                             "      </FolderShape>\n"
                             "      <FolderIds>\n"
                             "        <t:DistinguishedFolderId Id=\"inbox\"/>\n"
                             "      </FolderIds>\n"
                             "    </GetFolder>\n"
                             "  </soap:Body>\n"
                             "</soap:Envelope>\n"
                             ];
    
    [self doSOAPRequest: soapMessage];
}



- (void)getFolder {
    NSString *soapMessage = [NSString stringWithFormat:
                             @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
                             "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" \n"
                             "               xmlns:m=\"http://schemas.microsoft.com/exchange/services/2006/messages\" \n"
                             "               xmlns:t=\"http://schemas.microsoft.com/exchange/services/2006/types\" \n"
                             "               xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n"
                             "  <soap:Header>\n"
                             "    <t:RequestServerVersion Version=\"Exchange2010\" />\n"
                             "  </soap:Header>\n"
                             "  <soap:Body>\n"
                             "    <m:GetFolder>\n"
                             "      <m:FolderShape>\n"
                             "        <t:BaseShape>IdOnly</t:BaseShape>\n"
                             "      </m:FolderShape>\n"
                             "      <m:FolderIds>\n"
                             "        <t:DistinguishedFolderId Id=\"calendar\" />\n"
                             "      </m:FolderIds>\n"
                             "    </m:GetFolder>\n"
                             "  </soap:Body>\n"
                             "</soap:Envelope>"
                             ];
    
    [self doSOAPRequest: soapMessage];
}

- (void)getFolderResponse {
    NSString *soapMessage = [NSString stringWithFormat:
                             @"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                             "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" \n"
                             "               xmlns:m=\"http://schemas.microsoft.com/exchange/services/2006/messages\" \n"
                             "               xmlns:t=\"http://schemas.microsoft.com/exchange/services/2006/types\" \n"
                             "               xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n"
                             "  <soap:Header>\n"
                             "    <t:RequestServerVersion Version=\"Exchange2010\" />\n"
                             "  </soap:Header>\n"
                             "  <soap:Body>\n"
                             "    <m:GetFolderResponse xmlns:m=\"http://schemas.microsoft.com/exchange/services/2006/messages\"xmlns:t=\"http://schemas.microsoft.com/exchange/services/2006/types\">\n"
                             "      <m:ResponseMessages>\n"
                             "        <m:GetFolderResponseMessage ResponseClass=\"Success\">\n"
                             "          <m:ResponseCode>NoError</m:ResponseCode>\n"
                             "          <m:Folders>\n"
                             "            <t:CalendarFolder>\n"
                             "              <t:FolderId Id=\"QMkAGVhMDk0ZTVmLTYyZjItNDA0Ny1hZjE2LWMzN2MxMzYxZTczMQAuAAADu4595GA3Rketc7D8wigZkAEAfw0eyqsYaUGyYLpjwRSmNwAAAb1HPQAAAA==\" ChangeKey=\"AgAAABYAAADY9YrqyjJtRLCXrlg2TfwJAAB3KU4F\" />\n"
                             "            </t:CalendarFolder>\n"
                             "          </m:Folders>\n"
                             "        </m:GetFolderResponseMessage>\n"
                             "      </m:ResponseMessages>\n"
                             "    </m:GetFolderResponse>\n"
                             "  </soap:Body>\n"
                             "</soap:Envelope>"
                             ];
    
    [self doSOAPRequest: soapMessage];
}


- (void)findItem {
    NSString *soapMessage = [NSString stringWithFormat:
                             @"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                             "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" \n"
                             "               xmlns:m=\"http://schemas.microsoft.com/exchange/services/2006/messages\" \n"
                             "               xmlns:t=\"http://schemas.microsoft.com/exchange/services/2006/types\" \n"
                             "               xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n"
                             "  <soap:Header>\n"
                             "    <t:RequestServerVersion Version=\"Exchange2010\" />\n"
                             "  </soap:Header>\n"
                             "  <soap:Body>\n"
                             "    <m:FindItem Traversal=\"Shallow\">\n"
                             "      <m:ItemShape>\n"
                             "        <t:BaseShape>IdOnly</t:BaseShape>\n"
                             "        <t:AdditionalProperties>\n"
                             "          <t:FieldURI FieldURI=\"item:Subject\" />\n"
                             "          <t:FieldURI FieldURI=\"calendar:Start\" />\n"
                             "          <t:FieldURI FieldURI=\"calendar:End\" />\n"
                             "        </t:AdditionalProperties>\n"
                             "      </m:ItemShape>\n"
                             "      <m:CalendarView MaxEntriesReturned=\"5\" StartDate=\"2016-06-21T17:30:24.127Z\" EndDate=\"2016-06-30T17:30:24.127Z\" />\n"
                             "      <m:ParentFolderIds>\n"
                             "        <t:FolderId Id=\"AQMkAGVhMDk0ZTVmLTYyZjItNDA0Ny1hZjE2LWMzN2MxMzYxZTczMQAuAAADu4595GA3Rketc7D8wigZkAEAfw0eyqsYaUGyYLpjwRSmNwAAAb1HPQAAAA==\" ChangeKey=\"AgAAABYAAADY9YrqyjJtRLCXrlg2TfwJAAB3KU4F\" />\n"
                             "      </m:ParentFolderIds>"
                             "    </m:FindItem>"
                             "  </soap:Body>\n"
                             "</soap:Envelope>"
                             ];
    
    
    [self doSOAPRequest: soapMessage];
}




- (void)getRoomList {
    NSString *soapMessage = [NSString stringWithFormat:
                             @"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                             "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" \n"
                             "               xmlns:m=\"http://schemas.microsoft.com/exchange/services/2006/messages\" \n"
                             "               xmlns:t=\"http://schemas.microsoft.com/exchange/services/2006/types\" \n"
                             "               xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n"
                             "  <soap:Header>\n"
                             "    <t:RequestServerVersion Version=\"Exchange2010\" />\n"
                             "  </soap:Header>\n"
                             "  <soap:Body>\n"
                             "    <m:GetRoomLists />\n"
                             "  </soap:Body>\n"
                             "</soap:Envelope>"
                             ];
    
    [self doSOAPRequest: soapMessage];
}

//-(void)RoomBookRequest{
//    NSString *bookroom = [NSString stringWithFormat:
//                          @"<?xml version=\"1.0\" encoding=\"utf-8\"?>
//                          "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:m=\"http://schemas.microsoft.com/exchange/services/2006/messages\" \n"
//                            xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
//                          "<soap:Header> \
//                          <t:RequestServerVersion Version=\"Exchange2007_SP1\" />\
//                          <t:TimeZoneContext>\
//                          <t:TimeZoneDefinition Id=\"Pacific Standard Time\" />\
//                          </t:TimeZoneContext>\
//                          </soap:Header>\
//                          <soap:Body>\
//                          <m:CreateItem SendMeetingInvitations=\"SendToAllAndSaveCopy\">\
//                          <m:Items>\
//                          <t:CalendarItem>\
//                          <t:Subject>Team building exercise</t:Subject>\
//                          <t:Body BodyType=\"HTML\">Let's learn to really work as a team and then have lunch!</t:Body>\
//                          <t:ReminderMinutesBeforeStart>60</t:ReminderMinutesBeforeStart>\
//                          <t:Start>2013-09-21T16:00:00.000Z</t:Start>"
//                          <t:End>self.time</t:End>\
//                          <t:Location> self.bookroom</t:Location>\
//                          <t:RequiredAttendees>\
//                          <t:Attendee>\
//                          <t:Mailbox>\
//                          <t:EmailAddress>Mack.Chaves@contoso.com</t:EmailAddress>\
//                          </t:Mailbox>\
//                          </t:Attendee>\
//                          <t:Attendee>\
//                          <t:Mailbox>\
//                          <t:EmailAddress>Sadie.Daniels@contoso.com</t:EmailAddress>\
//                          </t:Mailbox>\
//                          </t:Attendee>\
//                          </t:RequiredAttendees>\
//                          <t:OptionalAttendees>\
//                          <t:Attendee>\
//                          <t:Mailbox>\
//                          <t:EmailAddress>Magdalena.Kemp@contoso.com</t:EmailAddress>\
//                          </t:Mailbox>\
//                          </t:Attendee>\
//                          </t:OptionalAttendees>\
//                          <t:MeetingTimeZone TimeZoneName=\"Pacific Standard Time\" />\
//                          </t:CalendarItem>\
//                          </m:Items>\
//                          </m:CreateItem>\
//                          </soap:Body>\
//                          </soap:Envelope>"];
//}

@end
