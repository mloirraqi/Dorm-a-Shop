//
//  ParseLiveQueryObjCBridge.swift
//  Dorm-a-Shop
//
//  Created by mloirraqi on 08/02/2019.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

import UIKit
import Parse
import ParseLiveQuery

@objc public final class ParseLiveQueryObjCBridge: NSObject {
    
    private let client = Client.shared
    private var subscription: Subscription<PFObject>?
    
    @objc(subscribeToQuery:handler:)
    func subscribeToQuery(query: PFQuery<PFObject>, handler: @escaping (PFObject?) -> Void) {
        guard let client = client else { handler(nil); return }        
        subscription = client.subscribe(query).handle(Event.created) { _, object in
            handler(object)
        }
    }
}


//func subscribeToQuery(sender: PFUser, handler: @escaping (PFObject?) -> Void) {
//    guard let client = client else { handler(nil); return }
//
//    let query:PFQuery = PFQuery(className: "Messages")
//    query.whereKey("receiver", equalTo: PFUser.current())
//    query.whereKey("sender", equalTo: sender)
//
//    subscription = client.subscribe(query).handle(Event.created) { _, object in
//        handler(object)
//    }
//}
//}
