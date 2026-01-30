//
//  SIPManager.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 30/12/25
//

import Foundation

final class SIPManager {

    static let shared = SIPManager()
    private init() {}

    private(set) var accountId: pjsua_acc_id = PJSUA_INVALID_ID.rawValue
    private var loginCompletion: ((Bool, String?) -> Void)?

    func login(
        username: String,
        password: String,
        domain: String,
        transport: String = "tcp",
        completion: @escaping (Bool, String?) -> Void
    ) {

        // store completion
        self.loginCompletion = completion

        var accCfg = pjsua_acc_config()
        pjsua_acc_config_default(&accCfg)

        let idUri   = strdup("sip:\(username)@\(domain)")
        let regUri  = strdup("sip:\(domain)")
        let proxy   = strdup("sip:\(domain);transport=\(transport)")
        let realm   = strdup("*")
        let user    = strdup(username)
        let pass    = strdup(password)

        accCfg.id = pj_str(idUri)
        accCfg.reg_uri = pj_str(regUri)

        accCfg.cred_count = 1
        accCfg.cred_info.0.scheme = pj_str(strdup("digest"))
        accCfg.cred_info.0.realm = pj_str(realm)
        accCfg.cred_info.0.username = pj_str(user)
        accCfg.cred_info.0.data_type =
            pj_int32_t(PJSIP_CRED_DATA_PLAIN_PASSWD.rawValue)
        accCfg.cred_info.0.data = pj_str(pass)

        accCfg.proxy_cnt = 1
        accCfg.proxy.0 = pj_str(proxy)

        accCfg.vid_in_auto_show = pj_bool_t(PJ_FALSE.rawValue)
        accCfg.vid_out_auto_transmit = pj_bool_t(PJ_FALSE.rawValue)

        var accId = pjsua_acc_id()
        let status = pjsua_acc_add(&accCfg, pj_bool_t(PJ_TRUE.rawValue), &accId)

        free(idUri); free(regUri); free(proxy); free(realm); free(user); free(pass)

        // ONLY check if account creation failed
        if status != PJ_SUCCESS.rawValue {
            DispatchQueue.main.async {
                completion(false, "Failed to create SIP account")
            }
        }
    }

    //  CALLED FROM on_reg_state2
    func handleRegistration(
        accId: pjsua_acc_id,
        statusCode: Int,
        reason: String
    ) {
        DispatchQueue.main.async {
            if statusCode == 200 {
                self.accountId = accId
                self.loginCompletion?(true, nil)
            } else {
                self.loginCompletion?(false, "Login failed: \(reason)")
            }
            self.loginCompletion = nil
        }
    }
    
//    func transferCall(
//        callId: pjsua_call_id,
//        target: String
//    ) -> Bool {
//
//        guard callId != PJSUA_INVALID_ID.rawValue else {
//            return false
//        }
//
//        let destStr = strdup(target)
//        var dest = pj_str(destStr)
//
//        let status = pjsua_call_xfer(callId, &dest, nil)
//
//        free(destStr)
//
//        return status == PJ_SUCCESS.rawValue
//    }

}
