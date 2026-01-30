//
//  PJSIPCallFunctions.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 06/01/26.
//

import Foundation

func call_func(user_data: UnsafeMutableRawPointer?) {

    guard let user_data else { return }

    let vars = Unmanaged<PjsipVars>
        .fromOpaque(user_data)
        .takeUnretainedValue()

    var opt = pjsua_call_setting()
    pjsua_call_setting_default(&opt)
    opt.aud_cnt = 1
    opt.vid_cnt = 1

    let destStr = strdup(vars.dest)
    defer { free(destStr) }
    var dest = pj_str(destStr)

    var newCallId = pjsua_call_id()

    let status = pjsua_call_make_call(
        SIPManager.shared.accountId,
        &dest,
        &opt,
        nil,
        nil,
        &newCallId
    )

    if status == PJ_SUCCESS.rawValue {
        DispatchQueue.main.async {
            vars.calling = true

            //  Track calls properly
            if !vars.activeCallIds.contains(newCallId) {
                vars.activeCallIds.append(newCallId)
            }
        }
    }
}

func toggle_hold_call(user_data: UnsafeMutableRawPointer?) {

    guard let user_data else { return }

    let vars = Unmanaged<PjsipVars>
        .fromOpaque(user_data)
        .takeUnretainedValue()

    guard let callId = vars.activeCallIds.first else { return }

    if !vars.isOnHold {
        pjsua_call_set_hold(callId, nil)
        DispatchQueue.main.async {
            vars.isOnHold = true
        }
    } else {
        pjsua_call_reinvite(callId, UInt32(pj_bool_t(PJ_TRUE.rawValue)), nil)
        DispatchQueue.main.async {
            vars.isOnHold = false
        }
    }
}

//func merge_calls(user_data: UnsafeMutableRawPointer?) {
//
//    let vars = Unmanaged<PjsipVars>
//        .fromOpaque(user_data!)
//        .takeUnretainedValue()
//
//    guard vars.activeCallIds.count == 2 else { return }
//
//    let callA = vars.activeCallIds[0]
//    let callB = vars.activeCallIds[1]
//
//    // Resume SIP
//    pjsua_call_reinvite(callA, UInt32(pj_bool_t(PJ_TRUE.rawValue)), nil)
//    pjsua_call_reinvite(callB, UInt32(pj_bool_t(PJ_TRUE.rawValue)), nil)
//
//    guard
//        let slotA = vars.conferenceSlots[callA],
//        let slotB = vars.conferenceSlots[callB]
//    else { return }
//
//    //  Disconnect everything first
////    pjsua_conf_disconnect(0, pj_int32_t(slotA))
////    pjsua_conf_disconnect(0, pj_int32_t(slotB))
////    pjsua_conf_disconnect(pj_int32_t(slotA), 0)
////    pjsua_conf_disconnect(pj_int32_t(slotB), 0)
//
//    // Call ↔ Call
//    pjsua_conf_connect(pj_int32_t(slotA), pj_int32_t(slotB))
//    pjsua_conf_connect(pj_int32_t(slotB), pj_int32_t(slotA))
//
//    // Mic → calls
//    pjsua_conf_connect(0, pj_int32_t(slotA))
//    pjsua_conf_connect(0, pj_int32_t(slotB))
//
//    // Calls → speaker
//    pjsua_conf_connect(pj_int32_t(slotA), 0)
//    pjsua_conf_connect(pj_int32_t(slotB), 0)
//
//    // Ensure device attached
//    pjsua_conf_connect(0, 0)
//
//    DispatchQueue.main.async {
//        vars.isConference = true
//        vars.isOnHold = false
//    }
//}

func merge_calls(user_data: UnsafeMutableRawPointer?) {

    let vars = Unmanaged<PjsipVars>
        .fromOpaque(user_data!)
        .takeUnretainedValue()

    guard vars.activeCallIds.count == 2 else { return }

    let a = vars.activeCallIds[0]
    let b = vars.activeCallIds[1]

    guard
        let slotA = vars.conferenceSlots[a],
        let slotB = vars.conferenceSlots[b]
    else { return }

    pjsua_conf_connect(pj_int32_t(slotA), pj_int32_t(slotB))
    pjsua_conf_connect(pj_int32_t(slotB), pj_int32_t(slotA))

    pjsua_conf_connect(0, pj_int32_t(slotA))
    pjsua_conf_connect(0, pj_int32_t(slotB))

    DispatchQueue.main.async {
        vars.isConference = true
        vars.isOnHold = false
    }
}

func answer_call(user_data: UnsafeMutableRawPointer?) {

    guard let user_data else { return }

    let vars =
        Unmanaged<PjsipVars>
            .fromOpaque(user_data)
            .takeUnretainedValue()

    let callId = vars.call_id
    guard callId != PJSUA_INVALID_ID.rawValue else { return }

    // Send 200 OK
    pjsua_call_answer(callId, 200, nil, nil)

    DispatchQueue.main.async {
      //  vars.calling = true
      //  vars.callAnswered = false
        vars.hasIncomingCall = false

    }
}

func reject_call(user_data: UnsafeMutableRawPointer?) {

    guard let user_data else { return }

    let vars =
        Unmanaged<PjsipVars>
            .fromOpaque(user_data)
            .takeUnretainedValue()

    let callId = vars.call_id
    guard callId != PJSUA_INVALID_ID.rawValue else { return }

    // Send 486 Busy Here
    pjsua_call_hangup(callId, 486, nil, nil)

    DispatchQueue.main.async {
        vars.call_id = PJSUA_INVALID_ID.rawValue
        vars.calling = false
        vars.callAnswered = false
        vars.hasIncomingCall = false
        vars.showOngoingCall = false   
    }
}

func end_all_calls(user_data: UnsafeMutableRawPointer?) {

    guard let user_data else { return }

    let vars =
        Unmanaged<PjsipVars>
            .fromOpaque(user_data)
            .takeUnretainedValue()

    // Hang up ALL active calls
    for callId in vars.activeCallIds {
        if callId != PJSUA_INVALID_ID.rawValue {
            pjsua_call_hangup(callId, 200, nil, nil)
        }
    }

    DispatchQueue.main.async {
        vars.activeCallIds.removeAll()
        vars.conferenceSlots.removeAll()

        vars.calling = false
        vars.callAnswered = false
        vars.isConference = false
        vars.isOnHold = false
        vars.hasIncomingCall = false
        vars.showOngoingCall = false
        vars.call_id = PJSUA_INVALID_ID.rawValue
    }
}

func transfer_call(user_data: UnsafeMutableRawPointer?) {

    guard let user_data else { return }

    let vars = Unmanaged<PjsipVars>
        .fromOpaque(user_data)
        .takeUnretainedValue()

    guard let callId = vars.activeCallIds.first else { return }

    let destStr = strdup(vars.dest)
    var dest = pj_str(destStr)

    let status = pjsua_call_xfer(callId, &dest, nil)
    free(destStr)

    if status == PJ_SUCCESS.rawValue {
        DispatchQueue.main.async {
            vars.isTransferInProgress = true
        }
    }
}
