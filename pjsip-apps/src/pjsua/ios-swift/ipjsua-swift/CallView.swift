//
//  CallView.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 31/12/25.
//

import SwiftUI

struct CallView: View {

    @EnvironmentObject var pjsipVars: PjsipVars

    var body: some View {
        VStack(spacing: 20) {

            Text("SIP Account Registered")
                .font(.headline)

            Button(action: {
                triggerCallOrHangup()
            }) {
                Text(pjsipVars.calling ? "Hangup Call" : "Call Test User")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(pjsipVars.calling ? Color.red : Color.green)
                    .cornerRadius(8)
            }

            if pjsipVars.calling {
                Text("Call in progress…")
                    .foregroundColor(.green)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - PJSIP call trigger
    private func triggerCallOrHangup() {
        let userData =
            UnsafeMutableRawPointer(
                Unmanaged.passUnretained(pjsipVars).toOpaque()
            )

        // PJSUA internal timer thread
        pjsua_schedule_timer2_dbg(
            call_func,
            userData,
            0,
            "swift",
            0
        )
    }
}

func call_func(user_data: UnsafeMutableRawPointer?) {
   let pjsip_vars = Unmanaged<PjsipVars>.fromOpaque(user_data!).takeUnretainedValue()
   if (!pjsip_vars.calling) {
       var status: pj_status_t;
       var opt = pjsua_call_setting();

       pjsua_call_setting_default(&opt);
       opt.aud_cnt = 1;
       opt.vid_cnt = 1;

       let dest_str = strdup(pjsip_vars.dest);
       var dest:pj_str_t = pj_str(dest_str);
       
       status = pjsua_call_make_call(SIPManager.shared.accountId, &dest, &opt, nil, nil, &pjsip_vars.call_id);
       DispatchQueue.main.sync {
           pjsip_vars.calling = (status == PJ_SUCCESS.rawValue);
       }
       free(dest_str);
   } else {
       if (pjsip_vars.call_id != PJSUA_INVALID_ID.rawValue) {
           DispatchQueue.main.sync {
               pjsip_vars.calling = false;
           }
           pjsua_call_hangup(pjsip_vars.call_id, 200, nil, nil);
           pjsip_vars.call_id = PJSUA_INVALID_ID.rawValue;
       }
   }

}
