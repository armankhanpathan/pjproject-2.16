//
//  PJSIPCallFunctions.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 06/01/26.
//

import Foundation

func call_func(user_data: UnsafeMutableRawPointer?) {

    guard let user_data else { return }

    let pjsipVars =
        Unmanaged<PjsipVars>
            .fromOpaque(user_data)
            .takeUnretainedValue()

    if !pjsipVars.calling {

        var opt = pjsua_call_setting()
        pjsua_call_setting_default(&opt)
        opt.aud_cnt = 1
        opt.vid_cnt = 1

        let destStr = strdup(pjsipVars.dest)
        defer { free(destStr) }

        var dest = pj_str(destStr)

        let status = pjsua_call_make_call(
            SIPManager.shared.accountId,
            &dest,
            &opt,
            nil,
            nil,
            &pjsipVars.call_id
        )

        DispatchQueue.main.async {
            pjsipVars.calling = (status == PJ_SUCCESS.rawValue)
        }

    } else {

        if pjsipVars.call_id != PJSUA_INVALID_ID.rawValue {
            pjsua_call_hangup(pjsipVars.call_id, 200, nil, nil)

            DispatchQueue.main.async {
                pjsipVars.calling = false
                pjsipVars.call_id = PJSUA_INVALID_ID.rawValue
            }
        }
    }
}
