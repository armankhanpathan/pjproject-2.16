/*
 * Copyright (C) 2021-2021 Teluu Inc. (http://www.teluu.com)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

/* This is a simple Swift demo app that shows an example of how to use
 * PJSUA API to make one audio+video call to another user.
 */

import SwiftUI
import AVFoundation

class PjsipVars: ObservableObject {
    
    @Published var calling = false
    @Published var callAnswered: Bool = false
    @Published var callEnded: Bool = false
    @Published var isOnHold: Bool = false
    @Published var hasIncomingCall = false
    @Published var showOngoingCall = false
    
    @Published var isRecording: Bool = false
        var recorderId: pjsua_recorder_id = PJSUA_INVALID_ID.rawValue
    
    @Published var activeCallIds: [pjsua_call_id] = []
    @Published var conferenceSlots: [pjsua_call_id: Int] = [:]
    @Published var isConference: Bool = false
    @Published var isTransferInProgress = false

   var dest: String = ""
    var call_id: pjsua_call_id = PJSUA_INVALID_ID.rawValue
    var primaryCallId: pjsua_call_id?

    /* Video window */
    @Published var vid_win:UIView? = nil
}

class AppDelegate: NSObject, UIApplicationDelegate {
    static let Shared = AppDelegate()
    var pjsip_vars = PjsipVars()
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        configureAudioSession()
        return true
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetooth, .defaultToSpeaker]
            )
            try session.setActive(true)
        } catch {
            print("AudioSession error:", error)
        }
    }
}

@main
struct ipjsua_swiftApp: App {
    @StateObject private var appSession = AppSession()
    @StateObject private var pjsipVars = AppDelegate.Shared.pjsip_vars
    
    init() {
        
        /* Create pjsua */
        var status: pj_status_t;
        status = pjsua_create();
        if (status != PJ_SUCCESS.rawValue) {
            NSLog("Failed creating pjsua");
        }
        
        /* Init configs */
        var cfg = pjsua_config();
        var log_cfg = pjsua_logging_config();
        var media_cfg = pjsua_media_config();
        
        pjsua_config_default(&cfg);
        pjsua_logging_config_default(&log_cfg);
        pjsua_media_config_default(&media_cfg);
        
        cfg.cb.on_reg_state2 = { acc_id, info in
            guard
                let info = info,
                let cb = info.pointee.cbparam
            else { return }
            
            //  SIP RESPONSE CODE (200 / 401 / 403)
            let sipCode = cb.pointee.code
            
            let reason = String(
                bytesNoCopy: cb.pointee.reason.ptr,
                length: Int(cb.pointee.reason.slen),
                encoding: .utf8,
                freeWhenDone: false
            ) ?? ""
            
            print(" SIP REGISTER RESPONSE:", sipCode, reason)
            
            SIPManager.shared.handleRegistration(
                accId: acc_id,
                statusCode: Int(sipCode),
                reason: reason
            )
        }
        
        /* Initialize application callbacks */
        cfg.cb.on_incoming_call = on_incoming_call;
        cfg.cb.on_call_state = on_call_state;
        cfg.cb.on_call_media_state = on_call_media_state;
        cfg.cb.on_call_transfer_status = on_call_transfer_status

        
        /* Init pjsua */
        status = pjsua_init(&cfg, &log_cfg, &media_cfg);
        
        /* Create transport */
        var transport_id = pjsua_transport_id();
        var tcp_cfg = pjsua_transport_config();
        pjsua_transport_config_default(&tcp_cfg);
        tcp_cfg.port = 5080;
        status = pjsua_transport_create(PJSIP_TRANSPORT_TCP,
                                        &tcp_cfg, &transport_id);
        
        /* Add local account */
        var aid = pjsua_acc_id();
        status = pjsua_acc_add_local(transport_id, pj_bool_t(PJ_TRUE.rawValue), &aid);
        
        /* Use colorbar for local account and enable incoming video */
        var acc_cfg = pjsua_acc_config();
        var tmp_pool:UnsafeMutablePointer<pj_pool_t>? = nil;
        var info : [pjmedia_vid_dev_info] =
        Array(repeating: pjmedia_vid_dev_info(), count: 16);
        var count:UInt32 = UInt32(info.capacity);
        
        tmp_pool = pjsua_pool_create("tmp-ipjsua", 1000, 1000);
        pjsua_acc_get_config(aid, tmp_pool, &acc_cfg);
        acc_cfg.vid_in_auto_show = pj_bool_t(PJ_TRUE.rawValue);
        
        pjsua_vid_enum_devs(&info, &count);
        for i in 0..<count {
            let name: [CChar] = tupleToArray(tuple: info[Int(i)].name);
            if let dev_name = String(validatingUTF8: name) {
                if (dev_name == "Colorbar generator") {
                    acc_cfg.vid_cap_dev = pjmedia_vid_dev_index(i);
                    break;
                }
            }
        }
        //        pjsua_acc_modify(aid, &acc_cfg);
        //
        //        /* Init account config */
        //        let id = strdup("Test<sip:test@sip.pjsip.org>");
        //        let username = strdup("test");
        //        let passwd = strdup("pwd");
        //        let realm = strdup("*");
        //        let registrar = strdup("sip:sip.pjsip.org");
        //        let proxy = strdup("sip:sip.pjsip.org;transport=tcp");
        //
        //        pjsua_acc_config_default(&acc_cfg);
        //        acc_cfg.id = pj_str(id);
        //        acc_cfg.cred_count = 1;
        //        acc_cfg.cred_info.0.username = pj_str(username);
        //        acc_cfg.cred_info.0.realm = pj_str(realm);
        //        acc_cfg.cred_info.0.data = pj_str(passwd);
        //        acc_cfg.reg_uri = pj_str(registrar);
        //        acc_cfg.proxy_cnt = 1;
        //        acc_cfg.proxy.0 = pj_str(proxy);
        //        acc_cfg.vid_out_auto_transmit = pj_bool_t(PJ_TRUE.rawValue);
        //        acc_cfg.vid_in_auto_show = pj_bool_t(PJ_TRUE.rawValue);
        
        //        /* Add account */
        //        pjsua_acc_add(&acc_cfg, pj_bool_t(PJ_TRUE.rawValue), nil);
        //
        //        /* Free strings */
        //        free(id); free(username); free(passwd); free(realm);
        //        free(registrar); free(proxy);
        //
        //        pj_pool_release(tmp_pool);
        //
        
        //        /* Start pjsua */
        //        status = pjsua_start();
        status = pjsua_start()
        if status != PJ_SUCCESS.rawValue {
            NSLog("Failed starting pjsua")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appSession)
                .environmentObject(pjsipVars)
        }
    }
}
    
private func on_incoming_call(
    acc_id: pjsua_acc_id,
    call_id: pjsua_call_id,
    rdata: UnsafeMutablePointer<pjsip_rx_data>?
) {
    let vars = AppDelegate.Shared.pjsip_vars

    vars.call_id = call_id

    var ci = pjsua_call_info()
    pjsua_call_get_info(call_id, &ci)

    let caller = String(cString: ci.remote_info.ptr)

    DispatchQueue.main.async {
        vars.dest = caller
        vars.calling = true
        vars.callAnswered = false
        vars.hasIncomingCall = true
    }
}

    private func on_call_state(
        call_id: pjsua_call_id,
        e: UnsafeMutablePointer<pjsip_event>?
    ) {
        var ci = pjsua_call_info()
        pjsua_call_get_info(call_id, &ci)
        
        DispatchQueue.main.async {
            
            switch ci.state {
                
            case PJSIP_INV_STATE_CALLING,
            PJSIP_INV_STATE_EARLY:
                // Outgoing call ringing
                AppDelegate.Shared.pjsip_vars.calling = true
                AppDelegate.Shared.pjsip_vars.callAnswered = false
                AppDelegate.Shared.pjsip_vars.callEnded = false
                
            case PJSIP_INV_STATE_CONFIRMED:
                let vars = AppDelegate.Shared.pjsip_vars

                if !vars.activeCallIds.contains(call_id) {
                    vars.activeCallIds.append(call_id)
                }

                vars.callAnswered = true
                vars.calling = true
                vars.showOngoingCall = true

                AppDelegate.Shared.pjsip_vars.showOngoingCall = true
                
            case PJSIP_INV_STATE_DISCONNECTED:

                let vars = AppDelegate.Shared.pjsip_vars

                // Transfer completed OR normal hangup
                vars.activeCallIds.removeAll { $0 == call_id }
                vars.conferenceSlots.removeValue(forKey: call_id)

                if vars.activeCallIds.isEmpty {
                    vars.calling = false
                    vars.callAnswered = false
                    vars.showOngoingCall = false
                    vars.hasIncomingCall = false
                    vars.isConference = false
                    vars.isOnHold = false
                    vars.call_id = PJSUA_INVALID_ID.rawValue
                }

            default:
                break
            }
        }
    }
    
    private func tupleToArray<Tuple, Value>(tuple: Tuple) -> [Value] {
        let tupleMirror = Mirror(reflecting: tuple)
        return tupleMirror.children.compactMap { (child: Mirror.Child) -> Value? in
            return child.value as? Value
        }
    }
    
private func on_call_media_state(call_id: pjsua_call_id) {

    let vars = AppDelegate.Shared.pjsip_vars

    // 1. If in Conference mode, let merge_calls handle the wiring.
    if vars.isConference {
        return
    }

    // 2. If Transferring, do not interfere.
    if vars.isTransferInProgress {
        return
    }
    
    // 3. Get Call Info to check Media Status
    var ci = pjsua_call_info()
    pjsua_call_get_info(call_id, &ci)

    // --- CRITICAL FIX ---
    // Only connect audio if the media status is ACTIVE.
    // If it is HOLD (Local or Remote), do NOT connect audio.
    if ci.media_status != PJSUA_CALL_MEDIA_ACTIVE {
        print("Call media is NOT active (Status: \(ci.media_status.rawValue)). Skipping audio connection.")
        return
    }

    let media: [pjsua_call_media_info] = tupleToArray(tuple: ci.media)

    for mi in 0..<ci.media_cnt {

        guard media[Int(mi)].type == PJMEDIA_TYPE_AUDIO else { continue }

        let call_conf_slot = media[Int(mi)].stream.aud.conf_slot
        
        if call_conf_slot != PJSUA_INVALID_ID.rawValue {

            DispatchQueue.main.async {
                vars.conferenceSlots[call_id] = Int(call_conf_slot)
            }

            // Standard 1-to-1 Audio Connection
            pjsua_conf_connect(call_conf_slot, 0)
            pjsua_conf_connect(0, call_conf_slot)
        }
    }
}

private func on_call_transfer_status(
    call_id: pjsua_call_id,
    status_code: Int32,
    status_text: UnsafePointer<pj_str_t>?,
    final: pj_bool_t,
    p_cont: UnsafeMutablePointer<pj_bool_t>?
) {
    let vars = AppDelegate.Shared.pjsip_vars

    // Transfer fully completed
    if final == pj_bool_t(PJ_TRUE.rawValue),
       status_code >= 200 && status_code < 300 {

        //  Disconnect transferrer (A)
        pjsua_call_hangup(call_id, 200, nil, nil)

        DispatchQueue.main.async {
            vars.isTransferInProgress = false
        }
    }
}
