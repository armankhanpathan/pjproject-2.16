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
    
    // Get the audio slot (port) for this call
    guard let slotInt = vars.conferenceSlots[callId] else { return }
    let callPort = pj_int32_t(slotInt)

    if !vars.isOnHold {
        // MARK: --- HOLD ACTION
        
        // 1. Send SIP Hold Signal (Signaling)
        pjsua_call_set_hold(callId, nil)
        
        // 2. Physically Disconnect Audio (Media)
        //    Stop sending Mic (0) to Call
        pjsua_conf_disconnect(0, callPort)
        
        //    Stop hearing Call on Speaker (0)
        pjsua_conf_disconnect(callPort, 0)

        DispatchQueue.main.async {
            vars.isOnHold = true
        }
        
    } else {
        // MARK: --- RESUME ACTION

        // 1. Send SIP Re-INVITE to Un-Hold (Signaling)
        pjsua_call_reinvite(callId, UInt32(pj_bool_t(PJ_TRUE.rawValue)), nil)

        // 2. Reconnect Audio (Media)
        //    Note: The on_call_media_state callback will also trigger,
        //    but doing it here ensures immediate responsiveness.
        pjsua_conf_connect(0, callPort)
        pjsua_conf_connect(callPort, 0)

        DispatchQueue.main.async {
            vars.isOnHold = false
        }
    }
}

func merge_calls(user_data: UnsafeMutableRawPointer?) {

    guard let user_data else { return }

    let vars = Unmanaged<PjsipVars>
        .fromOpaque(user_data)
        .takeUnretainedValue()

    guard vars.activeCallIds.count == 2 else { return }

    let callA = vars.activeCallIds[0]
    let callB = vars.activeCallIds[1]

    // 1. Send SIP Re-INVITE to unhold both calls
    pjsua_call_reinvite(callA, UInt32(pj_bool_t(PJ_TRUE.rawValue)), nil)
    pjsua_call_reinvite(callB, UInt32(pj_bool_t(PJ_TRUE.rawValue)), nil)

    // 2. DELAY the audio mixing.
    // We wait 1.0s to ensure the SIP "Unhold" completes and media ports are ready.
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        
        guard
            let slotA = vars.conferenceSlots[callA],
            let slotB = vars.conferenceSlots[callB]
        else { return }

        let portA = pj_int32_t(slotA)
        let portB = pj_int32_t(slotB)
        
        // --- RESET: Disconnect everything first to prevent conflicts ---
        pjsua_conf_disconnect(0, portA)
        pjsua_conf_disconnect(portA, 0)
        pjsua_conf_disconnect(0, portB)
        pjsua_conf_disconnect(portB, 0)
        pjsua_conf_disconnect(portA, portB)
        pjsua_conf_disconnect(portB, portA)

        // --- REBUILD: Connect the 3-Way Conference ---
        
        // 1. Connect User A <-> User B
        pjsua_conf_connect(portA, portB)
        pjsua_conf_connect(portB, portA)

        // 2. Connect My Mic (0) -> User A
        pjsua_conf_connect(0, portA)
        
        // 3. Connect My Mic (0) -> User B
        pjsua_conf_connect(0, portB)

        // 4. Connect User A -> My Speaker (0)
        pjsua_conf_connect(portA, 0)

        // 5. Connect User B -> My Speaker (0)
        pjsua_conf_connect(portB, 0)

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
